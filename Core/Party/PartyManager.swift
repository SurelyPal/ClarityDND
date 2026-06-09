//
//  PartyManager.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import Foundation
import MultipeerConnectivity
import Combine

/// Главный менеджер мультиплеера.
/// Отвечает ТОЛЬКО за: управление ролью, хостинг/поиск, публичный API.
/// Остальная логика вынесена в отдельные extensions и RestVotingManager.
@MainActor
final class PartyManager: NSObject, ObservableObject {
    static let shared = PartyManager()

    // MARK: - Published State
    @Published var role: Role = .player
    @Published var localPeerName: String = PlatformCompatibility.deviceName
    @Published var partyMembers: [PartyMember] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var roomCode: String = ""
    @Published var gameRules: GameRules = .default

    @Published var debugLog: String = ""
    @Published var lastError: String? = nil
    @Published var disconnectReason: String? = nil

    let restVotingManager = RestVotingManager()

    // ✅ ОБРАТНАЯ СОВМЕСТИМОСТЬ: UI продолжает использовать старые имена типов
    // Это alias'ы, которые указывают на реальные типы в RestVotingManager
    typealias RestVoteSession = RestVotingManager.RestVoteSession
    typealias RestEffectEvent = RestVotingManager.RestEffectEvent

    // MARK: - Nested Types

    enum Role { case player, dungeonMaster }

    enum ConnectionState: Equatable {
        case disconnected
        case selectingCharacter
        case configuringRules
        case hosting(code: String)
        case searching
        case connecting(peerName: String)
        case connected(peersCount: Int)
    }

    // MARK: - Internal & Private State

    private let serviceType = "clarity-dnd"
    let localPeerID: MCPeerID // ✅ Было private → стало internal (видно из extension-файлов)
    private(set) var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private(set) var selectedCharacter: DNDCharacter?
    private var didTryAutoReconnect = false
    // ✅ Хранилище для версионирования (игнорируем устаревшие сообщения)
    var lastUpdateTime: [UUID: Date] = [:]
    // ✅ Хранилище для троттлинга синхронизации
    // (extension не может содержать stored properties, поэтому переносим сюда)
    var lastBasicSyncTime: Date = .distantPast
    let basicSyncThrottle: TimeInterval = 1.0
    var throttledSyncTask: Task<Void, Never>?
    var lastBroadcastTime: Date = .distantPast
    let broadcastThrottle: TimeInterval = 1.5

    // MARK: - Init

    private override init() {
        self.localPeerID = MCPeerID(displayName: PlatformCompatibility.deviceName)
        super.init()
        loadPartyState()
        loadGameRules()
    }

    deinit {
        session?.disconnect()
    }

    // MARK: - Logging

    func log(_ message: String) {
        #if DEBUG
        print(message)
        debugLog += "\(Date().formatted(date: .omitted, time: .standard)) \(message)\n"

        let lines = debugLog.components(separatedBy: "\n")
        if lines.count > 1000 {
            debugLog = lines.suffix(1000).joined(separator: "\n")
        }
        #endif
    }

    // MARK: - 🎲 ДМ API

    func startHosting() {
        self.role = .dungeonMaster
        self.partyMembers = []
        self.connectionState = .configuringRules
        log("⚙️ ДМ настраивает правила игры")
    }

    func applyRulesAndStartHosting(_ rules: GameRules) {
        self.gameRules = rules
        self.roomCode = String((100000..<999999).randomElement()!)
        saveGameRules(rules)

        self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: .none)
        self.session?.delegate = self

        var discoveryInfo: [String: String] = [
            "roomCode": self.roomCode,
            "hostName": self.localPeerName
        ]

        if let rulesData = try? JSONEncoder().encode(rules),
           let rulesString = String(data: rulesData, encoding: .utf8) {
            discoveryInfo["gameRules"] = rulesString
        }

        self.advertiser = MCNearbyServiceAdvertiser(
            peer: self.localPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: self.serviceType
        )
        self.advertiser?.delegate = self
        self.advertiser?.startAdvertisingPeer()

        self.connectionState = .hosting(code: self.roomCode)
        log("🎲 ДМ создал комнату: \(self.roomCode)")
    }

    func stopHosting() {
        self.advertiser?.stopAdvertisingPeer()
        self.advertiser = nil
        self.session?.disconnect()
        self.session = nil
        self.partyMembers = []
        self.role = .player
        self.roomCode = ""
        restVotingManager.resetAll()
        self.connectionState = .disconnected
        log("🛑 ДМ остановил хостинг")
    }

    // MARK: - 🗡️ Игрок API

    func beginPlayerFlow() {
        self.role = .player
        self.connectionState = .selectingCharacter
        log("👤 Игрок начал выбор персонажа")
    }

    func tryAutoReconnect(characters: [DNDCharacter]) {
        guard !didTryAutoReconnect,
              connectionState == .disconnected,
              let savedCharID = loadSelectedCharacterID(),
              let character = characters.first(where: { $0.id == savedCharID }) else {
            return
        }

        didTryAutoReconnect = true
        log("🔄 Автопереподключение с персонажем: \(character.displayName)")

        self.role = .player
        self.selectedCharacter = character
        self.connectionState = .searching

        if self.session == nil {
            self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: .none)
            self.session?.delegate = self
        }

        if self.browser == nil {
            self.browser = MCNearbyServiceBrowser(peer: self.localPeerID, serviceType: self.serviceType)
            self.browser?.delegate = self
        }

        self.browser?.startBrowsingForPeers()
    }

    func clearSelectedCharacter() {
        self.selectedCharacter = nil
        saveSelectedCharacterID(nil)
    }

    func startSearching(with character: DNDCharacter) {
        self.selectedCharacter = character

        if self.session == nil {
            self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: .none)
            self.session?.delegate = self
        }

        if self.browser == nil {
            self.browser = MCNearbyServiceBrowser(peer: self.localPeerID, serviceType: self.serviceType)
            self.browser?.delegate = self
        }

        self.browser?.startBrowsingForPeers()
        self.connectionState = .searching
    }

    func setSelectedCharacter(_ character: DNDCharacter?) {
        self.selectedCharacter = character
        saveSelectedCharacterID(character?.id)
    }

    func joinRoom(peerID: MCPeerID, roomCode: String) {
        guard session != nil else {
            log("❌ joinRoom: session nil")
            return
        }
        self.connectionState = .connecting(peerName: peerID.displayName)
        self.browser?.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
    }

    func leaveRoom() {
        self.selectedCharacter = nil
        self.browser?.stopBrowsingForPeers()
        self.browser = nil
        self.session?.disconnect()
        self.session = nil
        restVotingManager.resetAll()
        self.connectionState = .disconnected
        log("👋 Вышел из комнаты")
    }

    // MARK: - 🛏️ Rest API (делегирование)

    func initiateRestVote(type: RestType, from character: DNDCharacter) {
        if type == .short && !gameRules.canShortRest { return }
        if type == .long && !gameRules.canLongRest { return }
        
        // ✅ ЕСЛИ Я ДМ: формирую eligibleVoterIDs сам и рассылаю всем
        if role == .dungeonMaster {
            var eligibleIDs: Set<UUID> = []
            // Добавляем себя (ДМ)
            let dmID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            eligibleIDs.insert(dmID)
            // Добавляем всех connected игроков
            for member in partyMembers where member.isConnected {
                eligibleIDs.insert(member.id)
            }
            
            let message = PartyMessage.restVoteRequest(
                initiatorID: dmID,
                initiatorName: "Мастер",
                restType: type,
                eligibleVoterIDs: eligibleIDs
            )
            send(message)
            
            restVotingManager.startSession(
                initiatorID: dmID,
                initiatorName: "Мастер",
                restType: type,
                eligibleVoterIDs: eligibleIDs
            )
            
            // Если голосующих нет (только ДМ) — сразу применяем
            if eligibleIDs.count == 1 {
                let result = restVotingManager.registerVote(voterID: dmID, accepted: true)
                if case .success(let restType, let name) = result {
                    send(.restStarted(restType: restType))
                    decrementRestCounter(restType: restType)
                    restVotingManager.startEffect(restType: restType, initiatorName: name)
                }
            }
            
        } else {
            // ✅ ЕСЛИ Я ИГРОК: создаём локальную сессию СРАЗУ
            // Это гарантирует что плашка появится моментально
            
            // Предварительно формируем eligibleIDs (только себя)
            // Когда придёт restVoteRequest от ДМ-а, список будет обновлён
            var eligibleIDs: Set<UUID> = [character.id]
            
            let message = PartyMessage.requestRestVote(
                restType: type,
                requesterID: character.id,
                requesterName: character.displayName
            )
            send(message)
            log("📨 Запросил у ДМ-а начать голосование за \(type.displayName)")
            
            // ✅ СРАЗУ создаём локальную сессию с initiatorAutoVote=true
            // Инициатор автоматически голосует ЗА
            restVotingManager.startSession(
                initiatorID: character.id,
                initiatorName: character.displayName,
                restType: type,
                eligibleVoterIDs: eligibleIDs,
                initiatorAutoVote: true  // ✅ Я проголосовал ЗА автоматически
            )
        }
    }
        func sendRestVote(accepted: Bool, from character: DNDCharacter) {
            restVotingManager.markMyVote(accepted)
            
            // ✅ ДОБАВЛЕНО: обновляем локальную сессию — игрок видит свой голос в счётчике
            // registerVote добавит голос в activeRestVote.votes и проверит завершение
            let localResult = restVotingManager.registerVote(voterID: character.id, accepted: accepted)
            log("🗳️ Локальный голос: \(character.displayName) = \(accepted ? "ЗА" : "ПРОТИВ"), результат: \(localResult)")
            
            if role == .dungeonMaster {
                // ДМ уже обновил локальную сессию выше, обрабатываем результат
                switch localResult {
                case .success(let restType, let initiatorName):
                    send(.restStarted(restType: restType))
                    decrementRestCounter(restType: restType)
                    
                    // ДМ тоже применяет эффект отдыха
                    if let dmCharacter = selectedCharacter {
                        applyRestEffectImmediately(to: dmCharacter, type: restType)
                    }
                    
                    restVotingManager.startEffect(restType: restType, initiatorName: initiatorName)
                    
                case .failed:
                    send(.restVoteFailed(reason: "Кто-то проголосовал против"))
                    
                case .inProgress:
                    break
                }
            } else {
                // Игрок отправляет голос ДМ-у
                send(.restVoteResponse(
                    voterID: character.id,
                    voterName: character.displayName,
                    accepted: accepted
                ))
            }
        }
        func sendDMVote(accepted: Bool) {
            restVotingManager.markMyVote(accepted)
            let dmID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            let result = restVotingManager.registerVote(voterID: dmID, accepted: accepted)
            
            switch result {
            case .success(let restType, let name):
                send(.restStarted(restType: restType))
                decrementRestCounter(restType: restType)
                restVotingManager.startEffect(restType: restType, initiatorName: name)
            case .failed:
                send(.restVoteFailed(reason: "Кто-то проголосовал против"))
            case .inProgress:
                break
            }
        }
        
        func cancelRestVote() {
            guard restVotingManager.activeRestVote != nil else { return }
            send(.restVoteFailed(reason: "Мастер отменил голосование"))
            restVotingManager.cancelSession()
        }
        
        func applyRestEffect(to character: DNDCharacter, type: RestType, store: CharacterStore) {
            switch type {
            case .short:
                let heal = Int(ceil(Double(character.hitPoints) * 0.25))
                character.currentHP = min(character.hitPoints, character.currentHP + heal)
                if character.stress > 0 { character.stress -= 1 }
                SoundManager.shared.play(.levelUp, haptic: .success)
            case .long:
                character.currentHP = character.hitPoints
                character.stress = 0
                character.rerollPoints = Constants.Character.maxRerollPoints
                SoundManager.shared.play(.levelUp, haptic: .success)
            }
            store.update(character, changed: .full)
        }
        /// Применяет эффект отдыха к персонажу БЕЗ участия UI (для надёжности).
        /// Используется когда нужно применить эффект сразу при получении restStarted,
        /// не дожидаясь пока UI отреагирует через onChange.
        func applyRestEffectImmediately(to character: DNDCharacter, type: RestType) {
            switch type {
            case .short:
                let heal = Int(ceil(Double(character.hitPoints) * 0.25))
                character.currentHP = min(character.hitPoints, character.currentHP + heal)
                if character.stress > 0 { character.stress -= 1 }
            case .long:
                character.currentHP = character.hitPoints
                character.stress = 0
                character.rerollPoints = Constants.Character.maxRerollPoints
            }
            log("💤 Эффект отдыха применён к \(character.displayName)")
        }
        
        func resetSession() {
            gameRules.resetRests()
            saveGameRules(gameRules)
            send(.restsReset)
        }
    
    private func decrementRestCounter(restType: RestType) {
        if restType == .short {
            gameRules.shortRestsAvailable -= 1
        } else {
            gameRules.longRestsAvailable -= 1
        }
        saveGameRules(gameRules)
    }

    // MARK: - Очистка ошибок

    func clearError() { self.lastError = nil }
    func clearDisconnectReason() { self.disconnectReason = nil }
}

// MARK: - MCSessionDelegate (пустой — реализация в PartyManager+Connection.swift)
// Все методы delegate вынесены в отдельный extension

