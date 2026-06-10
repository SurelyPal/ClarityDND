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
    @Published var partyMembers: [PartyMember] = [] {
        didSet {
            log("🔄 partyMembers изменён: было \(oldValue.count), стало \(partyMembers.count)")
            if partyMembers.count != oldValue.count {
                for (i, member) in partyMembers.enumerated() {
                    log("   [\(i)] \(member.name) — connected=\(member.isConnected)")
                }
            }
        }
    }
    /// Менеджер кампаний
    let campaignManager = CampaignManager.shared
    /// ID текущей активной кампании (которую сейчас хостим)
    @Published var currentCampaignID: UUID?
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
    var advertiser: MCNearbyServiceAdvertiser?
    var browser: MCNearbyServiceBrowser?
    private(set) var selectedCharacter: DNDCharacter?
    private var didTryAutoReconnect = false
    // ✅ Хранилище для версионирования (игнорируем устаревшие сообщения)
    var lastUpdateTime: [UUID: Date] = [:]
    // ✅ Хранилище для троттлинга синхронизации
    // (extension не может содержать stored properties, поэтому переносим сюда)
    var lastBasicSyncTime: Date = .distantPast
    let basicSyncThrottle: TimeInterval = 0.3
    var throttledSyncTask: Task<Void, Never>?
    var lastBroadcastTime: Date = .distantPast
    let broadcastThrottle: TimeInterval = 0.5
    var throttledBroadcastTask: Task<Void, Never>?
    // ✅ Heartbeat: активная проверка связи с ДМ-ом
    var heartbeatTimer: Timer?
    var lastHeartbeatReceived: Date = .distantPast
    let heartbeatInterval: TimeInterval = 3.0
    let heartbeatTimeout: TimeInterval = 10.0
    var missedHeartbeats: Int = 0
    let maxMissedHeartbeats: Int = 3
    var lastHPBroadcastTime: Date = .distantPast
    var lastFullBroadcastTime: Date = .distantPast
   
    

    // MARK: - Init

    private override init() {
        self.localPeerID = MCPeerID(displayName: PlatformCompatibility.deviceName)
        super.init()
        loadPartyState()
        loadGameRules()
        if let campaignIDString = UserDefaults.standard.string(forKey: "lastActiveCampaignID"),
                   let campaignID = UUID(uuidString: campaignIDString) {
                    self.currentCampaignID = campaignID
                    log("📂 Загружена последняя активная кампания: \(campaignID.uuidString.prefix(8))")
                    
                    // Загружаем данные из файла кампании
                    if let campaign = campaignManager.campaigns.first(where: { $0.id == campaignID }) {
                        self.partyMembers = campaign.members
                        self.gameRules = campaign.gameRules
                        self.roomCode = campaign.roomCode
                        log("📂 Данные кампании загружены: \(campaign.name)")
                    }
                }
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

    /// Начинает хостинг указанной кампании (вызывается из CampaignSelectionView)
    func startHosting(campaign: Campaign) {
        log("🎲 Начинаем хостинг кампании: \(campaign.name)")
        UserDefaults.standard.set(campaign.id.uuidString, forKey: "lastActiveCampaignID")
                
        // Устанавливаем активную кампанию в менеджере
        campaignManager.setActiveCampaign(campaign)
        currentCampaignID = campaign.id
        
        // Загружаем данные из кампании (если есть), иначе создаём новые
        self.roomCode = campaign.roomCode.isEmpty
            ? Campaign.generateRoomCode()
            : campaign.roomCode
        self.gameRules = campaign.gameRules
        self.partyMembers = campaign.members
        
        // Останавливаем старый advertiser, если есть
        advertiser?.stopAdvertisingPeer()
        
        // Создаём новый advertiser с информацией о кампании
        advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: [
                "roomCode": roomCode,
                "campaignID": campaign.id.uuidString,
                "campaignName": campaign.name
            ],
            serviceType: "clarity-dnd"
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        connectionState = .hosting(code: roomCode)
        role = .dungeonMaster
        
        log("🎲 Хостинг кампании '\(campaign.name)' с кодом \(roomCode) запущен")
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
        send(.hostStopped)
            
            cleanupConnection(reason: "ДМ остановил хост")
    
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
        
        // ✅ ОЧИСТКА: удаляем устаревших offline игроков перед переподключением
            // Это предотвращает конфликт между старыми данными и новым списком от ДМ-а
            let onlineMembers = partyMembers.filter { $0.isConnected }
            if onlineMembers.count < partyMembers.count {
                let removedCount = partyMembers.count - onlineMembers.count
                partyMembers = onlineMembers
                log("🧹 Очищено \(removedCount) offline игроков перед автопереподключением")
            }
        
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

        if role == .dungeonMaster {
            // ДМ инициирует: голосуют ТОЛЬКО игроки (без ДМ-а)
            var eligibleIDs: Set<UUID> = []
            for member in partyMembers where member.isConnected {
                eligibleIDs.insert(member.id)
            }
            
            guard !eligibleIDs.isEmpty else {
                log("⚠️ Нет игроков для голосования")
                return
            }
            
            let dmID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            
            // 🆕 ДМ НЕ голосует, поэтому initialVotes пустой
            let message = PartyMessage.restVoteRequest(
                initiatorID: dmID,
                initiatorName: "Мастер",
                restType: type,
                eligibleVoterIDs: eligibleIDs,
                initialVotes: [:]  // 🆕 Пустой — ДМ не голосует
            )
            send(message)
            
            // ДМ НЕ голосует, только модерирует
            restVotingManager.startSession(
                initiatorID: dmID,
                initiatorName: "Мастер",
                restType: type,
                eligibleVoterIDs: eligibleIDs,
                initiatorAutoVote: false,
                initialVotes: [:]  // 🆕 Пустой
            )
            
        } else {
            // ✅ ИГРОК инициирует: создаём сессию СРАЗУ, не дожидаясь ответа ДМ-а
            // eligibleIDs пока только [свой ID] — обновится когда придёт restVoteRequest
            let preliminaryEligibleIDs: Set<UUID> = [character.id]
            
            // Отправляем запрос ДМ-у
            let request = PartyMessage.requestRestVote(
                restType: type,
                requesterID: character.id,
                requesterName: character.displayName
            )
            send(request)
            log("📨 Запросил у ДМ-а начать голосование за \(type.displayName)")
            
            // ✅ СРАЗУ создаём локальную сессию — плашка появится моментально
            restVotingManager.startSession(
                initiatorID: character.id,
                initiatorName: character.displayName,
                restType: type,
                eligibleVoterIDs: preliminaryEligibleIDs,
                initiatorAutoVote: true  // ✅ Я как инициатор голосую ЗА автоматически
            )
            
            log("🎯 Локальная сессия создана: плашка появится, мой голос учтён")
        }
    }
        func sendRestVote(accepted: Bool, from character: DNDCharacter) {
            restVotingManager.markMyVote(accepted)
            
            // ДОБАВЛЕНО: обновляем локальную сессию — игрок видит свой голос в счётчике
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
// MARK: - 🆕 Автопереподключение к партии (Pull-to-Refresh)
extension PartyManager {
    
    /// Пытается переподключиться к партии (вызывается из pull-to-refresh)
    @MainActor
    func reconnect() async -> Bool {
        log("🔄 Попытка переподключения к партии...")
        
        // Если уже подключены — ничего не делаем
        if case .connected = connectionState {
            log("✅ Уже подключены к партии")
            return true
        }
        
        // Если мы игрок — пытаемся найти комнату ДМа заново
        if role == .player {
            log("🔍 Игрок: запускаем повторный поиск комнаты ДМа")
            
            // 🆕 Явно используем self. и точные имена свойств
            self.session?.disconnect()
            self.browser?.stopBrowsingForPeers()
            
            // Запускаем поиск заново
            startBrowsingForReconnect()
            
            // Ждём 3 секунды, пока Multipeer найдёт пиров
            try? await Task.sleep(for: .seconds(3))
            
            // Проверяем результат
            if case .connected = connectionState {
                log("✅ Переподключение успешно!")
                return true
            } else {
                log("❌ Не удалось переподключиться за 3 секунды")
                return false
            }
        }
        
        // Если мы ДМ — проверяем/перезапускаем хостинг
        if role == .dungeonMaster {
            log("🎲 ДМ: проверяем статус хостинга")
            
            if case .hosting = connectionState {
                log("✅ Хостинг активен")
                return true
            } else if !roomCode.isEmpty {
                log("⚠️ Хостинг не активен — перезапускаем")
                self.advertiser?.stopAdvertisingPeer()
                restartHostingForReconnect()
                try? await Task.sleep(for: .seconds(1))
                return true
            }
        }
        
        return false
    }
    
    /// Запускает поиск комнат (для игрока) при переподключении
    private func startBrowsingForReconnect() {
        guard role == .player else { return }
        
        // 🆕 Создаём новый экземпляр, используя self. и точное имя свойства
        self.browser = MCNearbyServiceBrowser(
            peer: localPeerID,
            serviceType: "clarity-dnd"
        )
        self.browser?.delegate = self
        self.browser?.startBrowsingForPeers()
        
        log("🔍 Поиск комнат запущен")
    }
    
    /// Перезапускает хостинг (для ДМа) при переподключении
    private func restartHostingForReconnect() {
        guard role == .dungeonMaster, !roomCode.isEmpty else { return }
        
        // 🆕 Создаём новый экземпляр, используя self. и точное имя свойства
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerID,
            discoveryInfo: nil,
            serviceType: "clarity-dnd"
        )
        self.advertiser?.delegate = self
        self.advertiser?.startAdvertisingPeer()
        
        log("🎲 Хостинг перезапущен с кодом: \(roomCode)")
    }
}
