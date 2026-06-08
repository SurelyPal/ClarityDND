//
//  PartyManager.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import Foundation
import MultipeerConnectivity
import Combine

@MainActor
final class PartyManager: NSObject, ObservableObject {
    static let shared = PartyManager()
    
    @Published var role: Role = .player
    @Published var localPeerName: String = UIDevice.current.name
    @Published var partyMembers: [PartyMember] = []
    @Published var connectionState: ConnectionState = .disconnected
    @Published var roomCode: String = ""
    @Published var gameRules: GameRules = .default
    
    @Published var debugLog: String = ""
    @Published var lastError: String? = nil
    @Published var disconnectReason: String? = nil
    // 🆕 Голосование за отдых
    @Published var activeRestVote: RestVoteSession? = nil
    @Published var myVoteSent: Bool? = nil
    @Published var activeRestEffect: RestEffectEvent? = nil
    
    struct RestVoteSession: Identifiable, Equatable {
        let id = UUID()
        let initiatorID: UUID
        let initiatorName: String
        let restType: RestType
        var votes: [UUID: Bool] = [:]
        var eligibleVoterIDs: Set<UUID> = []  // 🆕 Кто имеет право голосовать
        
        var totalVoters: Int { eligibleVoterIDs.count }
    }
    
    struct RestEffectEvent: Identifiable, Equatable {
        let id = UUID()
        let restType: RestType
        let initiatorName: String
        let timestamp: Date
    }
    
    private let serviceType = "clarity-dnd"
    private let localPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private(set) var selectedCharacter: DNDCharacter?
    
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
    
    private override init() {
        self.localPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
        
        loadPartyState()
        loadGameRules()  // 🆕 Загружаем сохранённые правила
    }
    
    private func log(_ message: String) {
        print(message)
        self.debugLog += "\(Date().formatted(date: .omitted, time: .standard)) \(message)\n"
    }
    
    // MARK: - 🎲 ДМ
    
    func startHosting() {
        // 🆕 Сначала показываем экран настройки правил
        self.role = .dungeonMaster
        self.partyMembers = []
        self.connectionState = .configuringRules
        self.log("⚙️ ДМ настраивает правила игры")
    }

    /// 🆕 Применяет выбранные правила и создаёт комнату
    /// Применяет выбранные правила и создаёт комнату
    func applyRulesAndStartHosting(_ rules: GameRules) {
        self.gameRules = rules
        self.roomCode = String((100000..<999999).randomElement()!)
        
        // 🆕 Сохраняем правила в UserDefaults чтобы они пережили перезапуск
        saveGameRules(rules)
        
        self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: .none)
        self.session?.delegate = self
        
        // 🆕 Кодируем правила в JSON для передачи игрокам через discoveryInfo
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
        log("📜 Правила: canEditOutsideParty=\(rules.canEditCharacterOutsideParty)")
    }
    
    func stopHosting() {
        self.advertiser?.stopAdvertisingPeer()
        self.advertiser = nil
        self.session?.disconnect()
        self.session = nil
        self.partyMembers = []
        self.role = .player
        self.roomCode = ""
        // 🆕 Сбрасываем состояние голосования
        self.activeRestVote = nil
        self.myVoteSent = nil
        self.activeRestEffect = nil
        self.connectionState = .disconnected
        self.log("🛑 ДМ остановил хостинг")
    }
    
    // MARK: - 🗡️ Игрок
    
    func beginPlayerFlow() {
        self.role = .player
        self.connectionState = .selectingCharacter
        self.log("👤 Игрок начал выбор персонажа")
    }

    /// 🆕 Пытается автоматически переподключиться если был в партии
    private var didTryAutoReconnect = false  // 🆕 Добавляем флаг

    func tryAutoReconnect(characters: [DNDCharacter]) {
        // 🆕 Проверяем что ещё не пытались и не подключены
        guard !didTryAutoReconnect,
              connectionState == .disconnected,
              let savedCharID = loadSelectedCharacterID(),
              let character = characters.first(where: { $0.id == savedCharID }) else {
            return
        }
        
        didTryAutoReconnect = true  // 🆕 Помечаем что попытались
        log("🔄 Автопереподключение с персонажем: \(character.displayName)")
        
        self.role = .player
        self.selectedCharacter = character
        self.connectionState = .searching
        
        // Начинаем поиск автоматически
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

    /// 🆕 Очищает сохранённого персонажа (при явном выходе)
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
        self.log("🔍 Поиск комнат с персонажем: \(character.displayName)")
    }
    
    func setSelectedCharacter(_ character: DNDCharacter?) {
        self.selectedCharacter = character
        saveSelectedCharacterID(character?.id)
    }
    
    func joinRoom(peerID: MCPeerID, roomCode: String) {
        guard let session = self.session else {
            self.log("❌ joinRoom: session nil")
            return
        }
        self.connectionState = .connecting(peerName: peerID.displayName)
        self.browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        self.log("🚪 Приглашение отправлено к \(peerID.displayName)")
    }
    
    func leaveRoom() {
        self.selectedCharacter = nil
        self.browser?.stopBrowsingForPeers()
        self.browser = nil
        self.session?.disconnect()
        self.session = nil
        self.activeRestVote = nil
        self.myVoteSent = nil
        self.activeRestEffect = nil  // 🆕
        self.connectionState = .disconnected
        self.log("👋 Вышел из комнаты")
    }
    
    // MARK: - 📨 Отправка сообщений
    
    func sendJoinMessage(for character: DNDCharacter) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        
        let message = PartyMessage.playerJoined(
            characterID: character.id,
            name: character.displayName,
            race: character.race.rawValue,
            characterClass: character.characterClass.rawValue,
            level: character.level,
            currentHP: character.currentHP,
            maxHP: character.hitPoints,
            avatarData: character.avatarData
        )
        send(message)
        log("📤 playerJoined отправлен для \(character.displayName)")
        
        sendCharacterDetails(for: character)
        log("📋 characterDetails отправлен при подключении")
    }
    
    func sendCharacterDetails(for character: DNDCharacter) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        
        let proficientSkills = getProficientSkills(for: character)
        
        let message = PartyMessage.characterDetails(
            characterID: character.id,
            stats: character.stats,
            rerollPoints: character.rerollPoints,
            inventory: character.inventory,
            skillProficiencies: Array(proficientSkills),
            background: character.background,
            alignment: character.alignment
        )
        send(message)
        log("📋 characterDetails отправлен для \(character.displayName)")
    }
    // MARK: - 📋 Рассылка списка партии

    /// Отправляет всем игрокам обновлённый список партии
    private func broadcastPartyList() {
        guard role == .dungeonMaster,
              let session = session,
              !session.connectedPeers.isEmpty else { return }
        
        let message = PartyMessage.partyList(members: partyMembers)
        send(message)
        log("📋 Отправлен список партии (\(partyMembers.count) игроков) всем")
    }
    // MARK: - 🚀 Разделённая синхронизация
    
    private var lastBasicSyncTime: Date = .distantPast
    private let basicSyncThrottle: TimeInterval = 0.5
    
    func syncBasic(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState,
              let session = session,
              !session.connectedPeers.isEmpty else {
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastBasicSyncTime) < basicSyncThrottle {
            scheduleThrottledSync(for: character)
            return
        }
        
        lastBasicSyncTime = now
        
        let message = PartyMessage.characterUpdated(
            characterID: character.id,
            currentHP: character.currentHP,
            maxHP: character.hitPoints,
            level: character.level,
            stress: character.stress,
            rerollPoints: character.rerollPoints
        )
        send(message)
        log("🔄 syncBasic: currentHP=\(character.currentHP), stress=\(character.stress)")
    }
    
    func syncFull(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState,
              let session = session,
              !session.connectedPeers.isEmpty else {
            return
        }
        
        syncBasic(character)
        sendCharacterDetails(for: character)
        log("📋 syncFull: все данные отправлены для \(character.displayName)")
    }
    
    private var throttledSyncTask: Task<Void, Never>?
    
    private func scheduleThrottledSync(for character: DNDCharacter) {
        throttledSyncTask?.cancel()
        
        throttledSyncTask = Task { [weak self] in
            let elapsed = Date().timeIntervalSince(self?.lastBasicSyncTime ?? .distantPast)
            let remaining = (self?.basicSyncThrottle ?? 0.5) - elapsed
            
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
            
            guard !Task.isCancelled, let self = self else { return }
            
            self.lastBasicSyncTime = Date()
            
            let message = PartyMessage.characterUpdated(
                characterID: character.id,
                currentHP: character.currentHP,
                maxHP: character.hitPoints,
                level: character.level,
                stress: character.stress,
                rerollPoints: character.rerollPoints
            )
            self.send(message)
            self.log("⏰ syncBasic (throttled): currentHP=\(character.currentHP)")
        }
    }
    
    func autoSync(_ character: DNDCharacter) {
        syncBasic(character)
    }
    
    private func getProficientSkills(for character: DNDCharacter) -> Set<String> {
        ClassProficiencies.forClass(character.characterClass)
    }
    
    private func send(_ message: PartyMessage) {
        log("📤 send() вызван")
        
        guard let session = session else {
            log("⚠️ send: session nil")
            return
        }
        
        log("📤 Session существует, connectedPeers: \(session.connectedPeers.count)")
        
        guard !session.connectedPeers.isEmpty else {
            log("⚠️ send: нет connected peers")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            log("📦 Отправка \(data.count) байт \(session.connectedPeers.count) peer(ам)")
            log("📦 Peers: \(session.connectedPeers.map { $0.displayName }.joined(separator: ", "))")
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            log("✅ session.send() выполнен успешно")
        } catch {
            log("❌ Ошибка отправки: \(error)")
            log("❌ Детали: \(error.localizedDescription)")
        }
    }

    /// 🆕 Отправляет правила игры всем подключённым игрокам
    private func sendGameRules() {
        // Пока используем простой способ — через characterDetails
        // В будущем можно добавить отдельный case в PartyMessage
        log("📜 Правила игры сохранены: canEditOutsideParty=\(gameRules.canEditCharacterOutsideParty)")
    }
    // MARK: - 🛏️ Система отдыха

    /// Игрок/ДМ инициирует голосование за отдых
    func initiateRestVote(type: RestType, from character: DNDCharacter) {
        log("🔵 initiateRestVote: начало")
           log("🔵 Роль: \(role == .dungeonMaster ? "ДМ" : "Игрок")")
           log("🔵 Session: \(session != nil ? "создан" : "nil")")
           log("🔵 Connected peers: \(session?.connectedPeers.count ?? 0)")
        if type == .short && !gameRules.canShortRest {
            log("⚠️ Короткие отдыхи закончились")
            return
        }
        if type == .long && !gameRules.canLongRest {
            log("⚠️ Долгие отдыхи закончились")
            return
        }
        
        // 🆕 Собираем всех eligible voters: инициатор + все текущие члены партии
        var eligibleIDs: Set<UUID> = [character.id]
        for member in partyMembers where member.isConnected {
            eligibleIDs.insert(member.id)
        }
        log("🔵 Eligible voters: \(eligibleIDs.count)")
        
        log("🗳️ Eligible voters: \(eligibleIDs.count) (\(eligibleIDs.map { $0.uuidString.prefix(8) }.joined(separator: ", ")))")
        
        let message = PartyMessage.restVoteRequest(
            initiatorID: character.id,
            initiatorName: character.displayName,
            restType: type,
            eligibleVoterIDs: eligibleIDs
        )
        log("🔵 Пытаемся отправить сообщение...")
        send(message)
        log("🔵 После send()")

        // 🆕 Подсчитываем totalVoters как количество eligible voters (без ДМа)
        // ДМ не голосует, поэтому не учитывается
        let voterCount = eligibleIDs.count

        // Показываем плашку у инициатора локально
        activeRestVote = RestVoteSession(
            initiatorID: character.id,
            initiatorName: character.displayName,
            restType: type,
            votes: [character.id: true],
            eligibleVoterIDs: eligibleIDs
        )
        myVoteSent = true
        
        // Если в партии только инициатор — отдых начинается сразу
        if partyMembers.isEmpty {
            log("ℹ️ Инициатор один — отдых начинается автоматически")
            handleLocalVote(voterID: character.id, accepted: true)
        }
        
        log("📢 \(character.displayName) инициировал голосование за \(type.displayName)")
    }

    /// Игрок отправляет свой голос
    func sendRestVote(accepted: Bool, from character: DNDCharacter) {
        // 🆕 Сразу обновляем UI — пользователь видит что проголосовал
        myVoteSent = accepted
        
        let message = PartyMessage.restVoteResponse(
            voterID: character.id,
            voterName: character.displayName,
            accepted: accepted
        )
        
        // 🆕 ДМ не отправляет сообщение сам себе через send()
        // Его голос обрабатывается локально ниже
        if role == .dungeonMaster {
            // Обрабатываем свой голос как если бы получили от другого
            handleLocalVote(voterID: character.id, accepted: accepted)
            log("🗳️ ДМ проголосовал локально: \(accepted ? "ЗА" : "ПРОТИВ")")
        } else {
            // Игрок отправляет голос ДМу
            send(message)
            log("🗳️ \(character.displayName) проголосовал: \(accepted ? "ЗА" : "ПРОТИВ")")
        }
    }
    // 🆕 Голос ДМа как наблюдателя (когда он не играет за персонажа)
    func sendDMVote(accepted: Bool) {
        myVoteSent = accepted
        
        // ДМ голосует локально — его голос обрабатывается как "локальный"
        handleLocalVote(voterID: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, accepted: accepted)
        log("🗳️ ДМ (наблюдатель) проголосовал: \(accepted ? "ЗА" : "ПРОТИВ")")
    }
    /// 🆕 ДМ отменяет активное голосование
    func cancelRestVote() {
        guard activeRestVote != nil else { return }
        
        let failMsg = PartyMessage.restVoteFailed(reason: "Мастер отменил голосование")
        send(failMsg)
        
        activeRestVote = nil
        myVoteSent = nil
        log("❌ ДМ отменил голосование")
    }

    /// 🆕 Локальная обработка голоса (для ДМа-инициатора и инициатора-игрока)
    private func handleLocalVote(voterID: UUID, accepted: Bool) {
        guard var session = activeRestVote else { return }
        
        session.votes[voterID] = accepted
        activeRestVote = session
        
        log("🗳️ Локальный голос: \(accepted ? "ЗА" : "ПРОТИВ") (\(session.votes.count)/\(session.totalVoters))")
        
        // Проверяем: все проголосовали?
        if session.votes.count >= session.totalVoters {
            let allAccepted = session.votes.values.allSatisfy { $0 }
            
            if allAccepted {
                // Все "за" → начинаем отдых
                let startMsg = PartyMessage.restStarted(restType: session.restType)
                send(startMsg)
                
                // Уменьшаем счётчик
                if session.restType == .short {
                    gameRules.shortRestsAvailable -= 1
                } else {
                    gameRules.longRestsAvailable -= 1
                }
                saveGameRules(gameRules)
                
                // 🆕 Применяем эффект локально
                activeRestEffect = RestEffectEvent(
                    restType: session.restType,
                    initiatorName: session.initiatorName,
                    timestamp: Date()
                )
                
                activeRestVote = nil
                log("✅ Отдых \(session.restType.displayName) начался!")
            } else {
                // Кто-то "против" → отмена
                let failMsg = PartyMessage.restVoteFailed(reason: "Кто-то проголосовал против")
                send(failMsg)
                activeRestVote = nil
                log("❌ Голосование провалилось")
            }
        }
    }

    /// ДМ сбрасывает сессию (все отдыхи восстанавливаются)
    func resetSession() {
        gameRules.resetRests()
        saveGameRules(gameRules)
        
        let message = PartyMessage.restsReset
        send(message)
        log("🔄 ДМ сбросил сессию: отдыхи восстановлены (\(gameRules.shortRestsAvailable)S/\(gameRules.longRestsAvailable)L)")
    }

    /// Локально применяет эффект отдыха
    func applyRestEffect(to character: DNDCharacter, type: RestType, store: CharacterStore) {
        switch type {
        case .short:
            // +25% maxHP (округление вверх)
            let heal = Int(ceil(Double(character.hitPoints) * 0.25))
            character.currentHP = min(character.hitPoints, character.currentHP + heal)
            
            // -1 стресс (если > 0)
            if character.stress > 0 {
                character.stress -= 1
            }
            
            log("💤 Short Rest: +\(heal) HP, stress -1")
            SoundManager.shared.play(.levelUp, haptic: .success)
            
        case .long:
            // Полное восстановление
            character.currentHP = character.hitPoints
            character.stress = 0
            character.rerollPoints = Constants.Character.maxRerollPoints
            
            log("🛏️ Long Rest: HP = max, stress = 0, rerolls = max")
            SoundManager.shared.play(.levelUp, haptic: .success)
        }
        
        store.update(character, changed: .full)
    }
    // MARK: - Очистка ошибок
    
    func clearError() {
        self.lastError = nil
    }
    
    func clearDisconnectReason() {
        self.disconnectReason = nil
    }
    
    // MARK: - 💾 Сохранение состояния партии между сессиями
    
    private static let partyStateKey = "clarity_party_state"
    
    private func savePartyState() {
        do {
            let data = try JSONEncoder().encode(partyMembers)
            UserDefaults.standard.set(data, forKey: Self.partyStateKey)
            log("💾 Состояние партии сохранено: \(partyMembers.count) игроков")
        } catch {
            log("❌ Ошибка сохранения состояния партии: \(error)")
        }
    }
    
    private func loadPartyState() {
        guard let data = UserDefaults.standard.data(forKey: Self.partyStateKey),
              let members = try? JSONDecoder().decode([PartyMember].self, from: data)
        else {
            log("📭 Нет сохранённого состояния партии")
            return
        }
        
        self.partyMembers = members.map { member in
            var m = member
            m.isConnected = false
            return m
        }
        
        log("📂 Загружено состояние партии: \(partyMembers.count) игроков (все офлайн)")
    }
    // MARK: - 📜 Сохранение правил игры

    private static let gameRulesKey = "clarity_game_rules"

    /// Сохраняет правила в UserDefaults
    private func saveGameRules(_ rules: GameRules) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: Self.gameRulesKey)
            log("💾 Правила сохранены локально")
        }
    }

    /// Загружает правила из UserDefaults
    private func loadGameRules() {
        guard let data = UserDefaults.standard.data(forKey: Self.gameRulesKey),
              let rules = try? JSONDecoder().decode(GameRules.self, from: data) else {
            return
        }
        self.gameRules = rules
        log("📂 Загружены правила: canEditOutsideParty=\(rules.canEditCharacterOutsideParty)")
    }
    // MARK: - 💾 Сохранение выбранного персонажа (для автопереподключения игрока)

    private static let selectedCharacterKey = "clarity_selected_character"

    /// Сохраняет ID выбранного персонажа для автопереподключения
    private func saveSelectedCharacterID(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: Self.selectedCharacterKey)
            log("💾 Сохранён ID выбранного персонажа: \(id)")
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedCharacterKey)
            log("🗑️ Удалён ID выбранного персонажа")
        }
    }

    /// Загружает ID ранее выбранного персонажа
    private func loadSelectedCharacterID() -> UUID? {
        guard let idString = UserDefaults.standard.string(forKey: Self.selectedCharacterKey),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        log("📂 Загружен ID выбранного персонажа: \(id)")
        return id
    }
}

// MARK: - MCSessionDelegate
extension PartyManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.log("✅ Подключено: \(peerID.displayName)")
                self.connectionState = .connected(peersCount: session.connectedPeers.count)
                self.disconnectReason = nil
                
                if self.role == .dungeonMaster,
                   let idx = self.partyMembers.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
                    var updatedMember = self.partyMembers[idx]
                    updatedMember.isConnected = true
                    
                    var newMembers = self.partyMembers
                    newMembers[idx] = updatedMember
                    self.partyMembers = newMembers
                    
                    self.log("🟢 Игрок \(peerID.displayName) снова онлайн!")
                    self.savePartyState()
                }
                
                // 🆕 ДМ рассылает обновлённый список всем игрокам
                if self.role == .dungeonMaster {
                    self.broadcastPartyList()
                }
                
                if self.role == .player, let char = self.selectedCharacter {
                    self.sendJoinMessage(for: char)
                }
                
            case .connecting:
                self.log("⏳ Подключение: \(peerID.displayName)")
                
            case .notConnected:
                self.log("❌ Отключено: \(peerID.displayName)")
                
                let reason = self.determineDisconnectReason(peer: peerID)
                self.disconnectReason = reason
                self.lastError = reason
                
                if self.role == .dungeonMaster {
                    if let idx = self.partyMembers.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
                        let disconnectedMemberID = self.partyMembers[idx].id  // 🆕 Сохраняем ID
                        var updatedMember = self.partyMembers[idx]
                        updatedMember.isConnected = false
                        updatedMember.lastSeen = Date()
                        
                        var newMembers = self.partyMembers
                        newMembers[idx] = updatedMember
                        self.partyMembers = newMembers
                        
                        self.log("🔴 Игрок \(peerID.displayName) отключился (теперь офлайн)")
                        self.savePartyState()
                        
                        // 🆕 ЕСЛИ ОТКЛЮЧИЛСЯ ИНИЦИАТОР ГОЛОСОВАНИЯ — ОТМЕНЯЕМ ЕГО
                        if let voteSession = self.activeRestVote,
                           voteSession.initiatorID == disconnectedMemberID {
                            self.log("❌ Инициатор голосования отключился — отменяем")
                            let failMsg = PartyMessage.restVoteFailed(reason: "Инициатор отключился")
                            self.send(failMsg)
                            self.activeRestVote = nil
                            self.myVoteSent = nil
                        }
                    }
                    
                    self.broadcastPartyList()
                    
                    let count = session.connectedPeers.count
                    if count > 0 {
                        self.connectionState = .connected(peersCount: count)
                    } else {
                        self.connectionState = .hosting(code: self.roomCode)
                    }
                } else {
                    // 🆕 ИГРОК: ПОЛНАЯ очистка при потере связи с ДМом
                    let count = session.connectedPeers.count
                    
                    if count == 0 {
                        // Потеряли связь с ДМом — очищаем ВСЁ
                        self.log("🔴 Связь с ДМом потеряна — полная очистка")
                        self.connectionState = .disconnected
                        
                        // 🆕 Очищаем все состояния
                        self.partyMembers = []
                        self.activeRestVote = nil
                        self.myVoteSent = nil
                        self.activeRestEffect = nil
                        
                        // 🆕 Устанавливаем ТОЛЬКО disconnectReason (не lastError)
                        // чтобы избежать двойного alert'а
                        self.disconnectReason = reason
                        self.lastError = nil
                    } else {
                        self.connectionState = .connected(peersCount: count)
                    }
                }
            @unknown default: break
            }
        }
    }
    
    private func determineDisconnectReason(peer: MCPeerID) -> String {
        if role == .dungeonMaster {
            return "Игрок \(peer.displayName) отключился от партии"
        } else {
            return "Мастер отключил вас или соединение потеряно"
        }
    }
    
    nonisolated func session(_ session: MCSession, didFailToConnectPeer peerID: MCPeerID, withError error: Error) {
        Task { @MainActor in
            let errorMessage = "Не удалось подключиться к \(peerID.displayName): \(error.localizedDescription)"
            self.log("❌ \(errorMessage)")
            self.lastError = errorMessage
            self.connectionState = .disconnected
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.log("📥 ═══════════════════════════════════")
            self.log("📥 Получено \(data.count) байт от \(peerID.displayName)")
            self.log("📥 Моя роль: \(self.role == .dungeonMaster ? "ДМ" : "Игрок")")
            self.log("📥 Connected peers: \(session.connectedPeers.count)")
            
            // 🆕 Логируем первые 150 байт для отладки
            if let preview = String(data: data.prefix(150), encoding: .utf8) {
                self.log("📥 Превью: \(preview)")
            }
            
            do {
                let message = try JSONDecoder().decode(PartyMessage.self, from: data)
                self.log("📥 ✅ Декодировано успешно")
                self.handle(message: message, from: peerID)
            } catch {
                self.log("📥 ❌ ОШИБКА ДЕКОДИРОВАНИЯ: \(error)")
                
                // 🆕 Детализация ошибки
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        self.log("   Type mismatch: \(type)")
                        self.log("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .valueNotFound(let type, let context):
                        self.log("   Value not found: \(type)")
                        self.log("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .keyNotFound(let key, let context):
                        self.log("   Key not found: \(key.stringValue)")
                        self.log("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .dataCorrupted(let context):
                        self.log("   Data corrupted: \(context.debugDescription)")
                        self.log("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    @unknown default:
                        self.log("   Unknown error")
                    }
                }
            }
            self.log("📥 ═══════════════════════════════════")
        }
    }
    
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Обработка сообщений
extension PartyManager {
    private func handle(message: PartyMessage, from peerID: MCPeerID) {
        switch message {
        case .playerJoined(let charID, let name, let raceRaw, let cls, let level, let currentHP, let maxHP, let avatarData):
            guard role == .dungeonMaster else { return }
            if peerID.displayName == self.localPeerID.displayName {
                log("⚠️ Игнорируем playerJoined от себя")
                return
            }
            let race = Race(rawValue: raceRaw) ?? .human
            
            let member = PartyMember(
                id: charID,
                peerID: peerID,
                name: name,
                race: race,
                characterClass: cls,
                level: level,
                currentHP: currentHP,
                maxHP: maxHP,
                stress: 0,
                avatarData: avatarData
            )
            
            if let idx = partyMembers.firstIndex(where: { $0.id == charID }) {
                var newMembers = partyMembers
                newMembers[idx] = member
                partyMembers = newMembers                              // ✅ Явная замена
                log("🔄 Обновлён игрок: \(name)")
            } else {
                partyMembers.append(member)
                log("🎭 ДМ: \(name) в партии (аватар: \(avatarData != nil ? "✅" : "❌"))")
            }
            savePartyState()
            
            // 🆕 Рассылаем обновлённый список всем игрокам
            broadcastPartyList()
            
        case .characterDetails(let charID, let stats, let rerollPoints, let inventory, let skillProficiencies, let background, let alignment):
            guard role == .dungeonMaster else { return }
            if let idx = partyMembers.firstIndex(where: { $0.id == charID }) {
                // ✅ Создаём КОПИЮ
                var updatedMember = partyMembers[idx]
                updatedMember.stats = stats
                updatedMember.rerollPoints = rerollPoints
                updatedMember.inventory = inventory
                updatedMember.skillProficiencies = skillProficiencies
                updatedMember.background = background
                updatedMember.alignment = alignment
                
                // ✅ Заменяем весь массив
                var newMembers = partyMembers
                newMembers[idx] = updatedMember
                partyMembers = newMembers
                
                log("📋 Получены полные данные для \(partyMembers[idx].name)")
                savePartyState()
                broadcastPartyList()
            }
            
        case .characterUpdated(let charID, let currentHP, let maxHP, let level, let stress, let rerollPoints):
            guard role == .dungeonMaster else { return }
            if let idx = partyMembers.firstIndex(where: { $0.id == charID }) {
                let oldLevel = partyMembers[idx].level
                
                // ✅ ШАГ 1: Создаём КОПИЮ элемента
                var updatedMember = partyMembers[idx]
                updatedMember.currentHP = currentHP
                updatedMember.maxHP = maxHP
                updatedMember.level = level
                updatedMember.stress = stress
                updatedMember.rerollPoints = rerollPoints
                updatedMember.lastSeen = Date()
                
                // ✅ ШАГ 2: Заменяем ВЕСЬ массив — это триггерит @Published!
                var newMembers = partyMembers
                newMembers[idx] = updatedMember
                partyMembers = newMembers
                
                if level > oldLevel {
                    log("⬆️ \(partyMembers[idx].name): level \(oldLevel) → \(level), maxHP=\(maxHP)")
                } else {
                    log("🔄 \(partyMembers[idx].name): currentHP=\(currentHP)/\(maxHP), stress=\(stress)")
                }
                savePartyState()
                broadcastPartyList()
            }
            
        case .partyList(let members):
            guard role == .player else { return }
            
            // 🆕 Игрок получает список партии от ДМа
            self.partyMembers = members
            log("📋 Получен список партии: \(members.count) игроков")
            
            // Показываем имена для отладки
            for member in members {
                log("   - \(member.name) (\(member.isConnected ? "онлайн" : "оффлайн"))")
            }

        case .playerLeft(let charID):
            partyMembers.removeAll { $0.id == charID }
            log("👋 Игрок \(charID) вышел")
            savePartyState()
            
        case .restVoteRequest(let initiatorID, let initiatorName, let restType, let eligibleVoterIDs):
            let myID = selectedCharacter?.id
            
            // Если мы инициатор — игнорируем (плашка уже создана локально)
            if let myID = myID, myID == initiatorID {
                log("ℹ️ Игнорируем свой restVoteRequest (мы инициатор)")
                return
            }
            
            // 🆕 ВАЖНО: логируем для отладки
            log("🗳️ restVoteRequest получен: myID=\(myID?.uuidString.prefix(8) ?? "nil"), initiatorID=\(initiatorID.uuidString.prefix(8))")
            
            // Показываем плашку всем, у кого есть персонаж (игроки) или ДМу
            if selectedCharacter != nil || role == .dungeonMaster {
                activeRestVote = RestVoteSession(
                    initiatorID: initiatorID,
                    initiatorName: initiatorName,
                    restType: restType,
                    votes: [initiatorID: true],
                    eligibleVoterIDs: eligibleVoterIDs
                )
                myVoteSent = nil
                log("🗳️ ✅ Плашка голосования показана")
            } else {
                log("⚠️ Игнорируем restVoteRequest: нет выбранного персонажа")
            }

        case .restVoteResponse(let voterID, let voterName, let accepted):
            guard role == .dungeonMaster else { return }
            
            log("🗳️ Получен голос от \(voterName): \(accepted ? "ЗА" : "ПРОТИВ")")
            handleLocalVote(voterID: voterID, accepted: accepted)

        case .restStarted(let restType):
            log("🎉 Отдых \(restType.displayName) начался для всех!")
            activeRestVote = nil
            myVoteSent = nil
            
            // 🆕 УМЕНЬШАЕМ СЧЁТЧИКИ (у игрока при получении подтверждения от ДМа)
            if restType == .short {
                gameRules.shortRestsAvailable -= 1
            } else {
                gameRules.longRestsAvailable -= 1
            }
            saveGameRules(gameRules)
            log("📊 Счётчики обновлены: \(gameRules.shortRestsAvailable)S / \(gameRules.longRestsAvailable)L")
            
            activeRestEffect = RestEffectEvent(
                restType: restType,
                initiatorName: "партии",
                timestamp: Date()
            )

        case .restVoteFailed(let reason):
            log("❌ Голосование отменено: \(reason)")
            activeRestVote = nil
            myVoteSent = nil

        case .restsReset:
            guard role == .player else { return }
            gameRules.resetRests()
            log("🔄 Сессия сброшена: отдыхи восстановлены")

        case .ping: send(.pong)
        case .pong, .requestCharacterSync: break
        }
    }
}

extension PartyManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            self.log("📥 Приглашение от \(peerID.displayName)")
            invitationHandler(true, self.session)
        }
    }
    
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            let errorMessage = "Не удалось создать комнату: \(error.localizedDescription)"
            self.log("⚠️ \(errorMessage)")
            self.lastError = errorMessage
            self.connectionState = .disconnected
        }
    }
}

extension PartyManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let roomCode = info?["roomCode"] ?? "???"
        Task { @MainActor in
            // 🆕 Читаем правила ДМ из discoveryInfo
            if let rulesString = info?["gameRules"],
               let rulesData = rulesString.data(using: .utf8),
               let rules = try? JSONDecoder().decode(GameRules.self, from: rulesData) {
                self.gameRules = rules
                self.saveGameRules(rules)
                self.log("📜 Получены правила от ДМ: canEditOutsideParty=\(rules.canEditCharacterOutsideParty)")
            }
            
            self.log("👀 Найдена комната: \(roomCode) от \(peerID.displayName)")
            browser.stopBrowsingForPeers()
            self.joinRoom(peerID: peerID, roomCode: roomCode)
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.log("👻 Потеряна: \(peerID.displayName)")
        }
    }
    
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            let errorMessage = "Не удалось начать поиск партии: \(error.localizedDescription)"
            self.log("⚠️ \(errorMessage)")
            self.lastError = errorMessage
            self.connectionState = .disconnected
        }
    }
}
