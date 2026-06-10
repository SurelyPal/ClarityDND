//
//  PartyManager+Messages.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import Foundation
import MultipeerConnectivity

// MARK: - 📨 Отправка сообщений

extension PartyManager {
    func send(_ message: PartyMessage) {
        #if DEBUG
        log("📤 send() вызван")
        #endif

        guard let session = session else {
            #if DEBUG
            log("⚠️ send: session nil")
            #endif
            return
        }

        guard !session.connectedPeers.isEmpty else {
            #if DEBUG
            log("⚠️ send: нет connected peers")
            #endif
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            #if DEBUG
            log("📦 Отправка \(data.count) байт \(session.connectedPeers.count) peer(ам)")
            #endif
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            #if DEBUG
            log("❌ Ошибка отправки: \(error)")
            #endif
        }
    }

    func sendJoinMessage(for character: DNDCharacter) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }

        // ✅ Используем pendingCampaignID, если он есть, иначе character.campaignID
        let effectiveCampaignID = pendingCampaignID ?? character.campaignID

        let message = PartyMessage.playerJoined(
            characterID: character.id,
            name: character.displayName,
            race: character.race.rawValue,
            characterClass: character.characterClass.rawValue,
            level: character.level,
            currentHP: character.currentHP,
            maxHP: character.hitPoints,
            avatarData: character.avatarData,
            campaignID: effectiveCampaignID
        )
        send(message)
        log("📤 playerJoined отправлен для \(character.displayName) (кампания: \(effectiveCampaignID?.uuidString.prefix(8) ?? "nil"))")

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
    }

    // MARK: - Синхронизация

    func syncFull(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState else { return }
        syncBasic(character)
        // ✅ Принудительная синхронизация — обходим throttling
            
        sendCharacterDetails(for: character)
        // ✅ ДОБАВЛЕНО: логирование
            log("📤 syncFull: HP=\(character.currentHP)/\(character.hitPoints), level=\(character.level), inventory=\(character.inventory.count)")
    }

    func requestFullSync() async {
        guard role == .dungeonMaster,
              case .connected = connectionState else {
            log("⚠️ requestFullSync: нет подключения или я не ДМ")
            return
        }

        send(.requestSync)
        log("🔄 requestFullSync: запросил свежие данные")
        try? await Task.sleep(for: .milliseconds(500))
    }

  /* private func scheduleThrottledSync(for character: DNDCharacter) {
        throttledSyncTask?.cancel()

        let characterID = character.id
        let currentHP = character.currentHP
        let maxHP = character.hitPoints
        let level = character.level
        let stress = character.stress
        let rerollPoints = character.rerollPoints

        throttledSyncTask = Task { [weak self] in
            // ✅ Увеличен debounce с 0.5 до 1.0 секунды для стабильности
            let elapsed = Date().timeIntervalSince(self?.lastBasicSyncTime ?? .distantPast)
            let remaining = (self?.basicSyncThrottle ?? 0.9) - elapsed

            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }

            guard !Task.isCancelled, let self = self else { return }

            self.lastBasicSyncTime = Date()

            let message = PartyMessage.characterUpdated(
                characterID: characterID,
                currentHP: currentHP,
                maxHP: maxHP,
                level: level,
                stress: stress,
                rerollPoints: rerollPoints,
                timestamp: Date()  // ✅ Добавлено
            )
            self.send(message)
        }
    } */

    // MARK: - Broadcast

    func broadcastPartyList() {
        guard role == .dungeonMaster,
              let session = session,
              !session.connectedPeers.isEmpty else { return }

        let now = Date()
        if now.timeIntervalSince(lastBroadcastTime) < broadcastThrottle {
            // ✅ Откладываем через throttledBroadcastTask
            throttledBroadcastTask?.cancel()
            
            throttledBroadcastTask = Task { [weak self] in
                guard let self = self else { return }
                let elapsed = Date().timeIntervalSince(self.lastBroadcastTime)
                let remaining = self.broadcastThrottle - elapsed
                
                if remaining > 0 {
                    try? await Task.sleep(for: .seconds(remaining))
                }
                
                guard !Task.isCancelled else { return }
                
                self.lastBroadcastTime = Date()
                self.send(PartyMessage.partyList(members: self.partyMembers))
            }
            return
        }

        lastBroadcastTime = now
        
        send(PartyMessage.partyList(members: partyMembers))
        log("📤 broadcastPartyList: \(partyMembers.count) игроков")
    }
    // MARK: - Обработка запроса голосования от игрока

    private func handleRestVoteRequest(initiatorID: UUID, initiatorName: String, restType: RestType, eligibleVoterIDs: Set<UUID>, initialVotes: [UUID: Bool]) {
        let isInitiator = (selectedCharacter?.id == initiatorID)
                
                if isInitiator {
                    // Я ИНИЦИАТОР: у меня уже есть локальная сессия с моим голосом ЗА
                    guard var session = restVotingManager.activeRestVote else {
                        // Fallback: если локальная сессия почему-то отсутствует
                        restVotingManager.startSession(
                            initiatorID: initiatorID,
                            initiatorName: initiatorName,
                            restType: restType,
                            eligibleVoterIDs: eligibleVoterIDs,
                            initiatorAutoVote: true,
                            initialVotes: initialVotes
                        )
                        return
                    }
                    
                    // Сохраняем мой уже отданный голос
                    let myVote = session.votes[initiatorID] ?? true
                    
                    // Обновляем eligibleIDs
                    session.eligibleVoterIDs = eligibleVoterIDs
                    session.votes[initiatorID] = myVote
                    
                    restVotingManager.activeRestVote = session
                    log("🔄 Инициатор: обновил eligibleVoterIDs до \(eligibleVoterIDs.count), мой голос сохранён")
                    return
                }
                
                // Я НЕ инициатор — создаём сессию с initialVotes от ДМ-а
                if selectedCharacter != nil {
                    restVotingManager.startSession(
                        initiatorID: initiatorID,
                        initiatorName: initiatorName,
                        restType: restType,
                        eligibleVoterIDs: eligibleVoterIDs,
                        initiatorAutoVote: false,
                        initialVotes: initialVotes
                    )
                    
                    log("📥 Получен restVoteRequest: инициатор=\(initiatorName), eligible=\(eligibleVoterIDs.count), initialVotes=\(initialVotes.count)")
                }
            }    // MARK: - Helpers

    private func getProficientSkills(for character: DNDCharacter) -> Set<String> {
        ClassProficiencies.forClass(character.characterClass)
    }
}

// MARK: - 📥 Обработка входящих сообщений

extension PartyManager {
    func receiveMessage(_ data: Data, from peerID: MCPeerID) {
        log("📥 Получено \(data.count) байт от \(peerID.displayName)")
        
        do {
            let message = try JSONDecoder().decode(PartyMessage.self, from: data)
            handle(message: message, from: peerID)
        } catch {
            log("📥 ❌ Ошибка декодирования: \(error)")
        }
    }
    
    private func handle(message: PartyMessage, from peerID: MCPeerID) {
        switch message {
        case .playerJoined(
            let charID,
            let name,
            let raceRaw,
            let cls,
            let level,
            let currentHP,
            let maxHP,
            let avatarData,
            let campaignID
        ):
            handlePlayerJoined(
                charID: charID,
                peerID: peerID,
                name: name,
                raceRaw: raceRaw,
                cls: cls,
                level: level,
                currentHP: currentHP,
                maxHP: maxHP,
                avatarData: avatarData,
                campaignID: campaignID
            )
            
        case .characterDetails(let charID, let stats, let rerollPoints, let inventory, let skillProficiencies, let background, let alignment):
            handleCharacterDetails(charID: charID, stats: stats, rerollPoints: rerollPoints, inventory: inventory, skillProficiencies: skillProficiencies, background: background, alignment: alignment)
            
        case .characterUpdated(let charID, let currentHP, let maxHP, let level, let stress, let rerollPoints, let timestamp):
            handleCharacterUpdated(charID: charID, currentHP: currentHP, maxHP: maxHP, level: level, stress: stress, rerollPoints: rerollPoints, timestamp: timestamp)
            
        case .partyList(let members):
            handlePartyList(members: members)
            
        case .playerLeft(let charID):
            partyMembers.removeAll { $0.id == charID }
            savePartyState()
            // ✅ НОВОЕ: Обработка привязки к кампании
        case .campaignBinding(let campaignID):
                    handleCampaignBinding(campaignID: campaignID)
            // 🆕 Игрок запросил начать голосование — ДМ формирует список и рассылает
        case .requestRestVote(let restType, let requesterID, let requesterName):
            handleRequestRestVote(restType: restType, requesterID: requesterID, requesterName: requesterName)
            
        case .restVoteRequest(let initiatorID, let initiatorName, let restType, let eligibleVoterIDs, let initialVotes):
            handleRestVoteRequest(initiatorID: initiatorID, initiatorName: initiatorName, restType: restType, eligibleVoterIDs: eligibleVoterIDs, initialVotes: initialVotes)
            
        case .restVoteResponse(let voterID, _, let accepted):
            handleRestVoteResponse(voterID: voterID, accepted: accepted)
            
        case .restStarted(let restType):
            handleRestStarted(restType: restType)
            
        case .restVoteFailed(let reason):
            log("❌ Голосование отменено: \(reason)")
            restVotingManager.cancelSession()
            
        case .campaignBinding(let campaignID):  // ✅ НОВОЕ: обработка привязки
            handleCampaignBinding(campaignID: campaignID)
        
        case .restsReset:
            handleRestsReset()
            
        case .requestSync:
            if let char = selectedCharacter { syncFull(char) }
            
            // ✅ Heartbeat: ДМ отвечает на запросы игрока
        case .heartbeatRequest(let timestamp):
            // ДМ отвечает на heartbeat
            if role == .dungeonMaster {
                send(.heartbeatResponse(timestamp: timestamp))
            }
            
        case .heartbeatResponse(let timestamp):
            // Игрок получил ответ от ДМ-а
            if role == .player {
                lastHeartbeatReceived = Date()
                missedHeartbeats = 0
                // Не логируем каждый heartbeat чтобы не спамить
            }
            
            // ✅ ДМ явно уведомил об остановке хоста
        case .hostStopped:
            if role == .player {
                log("🛑 ДМ остановил хост")
                handleHostLost()
            }
            
        case .connectionRejected(let reason):
            guard role == .player else { return }
            
            log("❌ Подключение отклонено: \(reason)")
            lastError = reason
            
            // 🆕 Останавливаем соединение, но НЕ присваиваем nil
            // (так как сеттер session закрыт)
            session?.disconnect()
            browser?.stopBrowsingForPeers()
            
            // Очищаем состояние подключения
            partyMembers = []
            connectionState = .disconnected
            
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .ping: send(.pong)
        case .pong, .requestCharacterSync: break
            
        }
    }
    
    // MARK: - Message Handlers (приватные)
    
    private func handlePlayerJoined(
        charID: UUID,
        peerID: MCPeerID,
        name: String,
        raceRaw: String,
        cls: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        avatarData: Data?,
        campaignID: UUID?
    ) {
        guard role == .dungeonMaster else { return }
        guard peerID.displayName != self.localPeerID.displayName else { return }

        // ✅ ИСПРАВЛЕНО: Автоматическая привязка к кампании вместо отклонения
        if let activeCampaignID = currentCampaignID {
            if let characterCampaignID = campaignID {
                // У персонажа уже есть campaignID
                if characterCampaignID != activeCampaignID {
                    log("⚠️ Отклонено: \(name) привязан к другой кампании")
                    sendRejection(to: peerID, reason: "Персонаж привязан к другой кампании")
                    return
                }
                log("✅ Кампания совпадает: \(name) может подключиться")
            } else {
                // ✅ НОВОЕ: У персонажа нет campaignID — НЕ отклоняем, а принимаем и привязываем
                log("ℹ️ \(name) не привязан к кампании — принимаем и привязываем автоматически")
                sendCampaignBinding(to: peerID, campaignID: activeCampaignID)
            }
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
            partyMembers = newMembers
            log("🔄 Обновлён игрок: \(name)")
        } else {
            partyMembers.append(member)
            log("🎭 ДМ: \(name) в партии (аватар: \(avatarData != nil ? "✅" : "❌"))")
        }
        savePartyState()

        broadcastPartyList()
    }
    
    /// Отправляет сообщение об отклонении подключения игроку
    private func sendRejection(to peerID: MCPeerID, reason: String) {
        let message = PartyMessage.connectionRejected(reason: reason)
        
        do {
            let data = try JSONEncoder().encode(message)
            try session?.send(data, toPeers: [peerID], with: .reliable)
            log("📤 Отправлено отклонение: \(reason)")
        } catch {
            log("❌ Ошибка отправки отклонения: \(error)")
        }
    }
    
    /// Отправляет игроку команду привязать его персонажа к текущей кампании
    private func sendCampaignBinding(to peerID: MCPeerID, campaignID: UUID) {
        let message = PartyMessage.campaignBinding(campaignID: campaignID)
        do {
            let data = try JSONEncoder().encode(message)
            try session?.send(data, toPeers: [peerID], with: .reliable)
            log("📤 Отправлена привязка к кампании \(campaignID) для \(peerID.displayName)")
        } catch {
            log("❌ Ошибка отправки привязки к кампании: \(error)")
        }
    }
    
    private func handleCharacterDetails(charID: UUID, stats: AbilityScores, rerollPoints: Int, inventory: [InventoryItem], skillProficiencies: [String], background: String, alignment: DNDAlignment) {
        guard role == .dungeonMaster else { return }
        guard let idx = partyMembers.firstIndex(where: { $0.id == charID }) else { return }
        
        var updatedMember = partyMembers[idx]
        updatedMember.stats = stats
        updatedMember.rerollPoints = rerollPoints
        updatedMember.inventory = inventory
        updatedMember.skillProficiencies = skillProficiencies
        updatedMember.background = background
        updatedMember.alignment = alignment
        
        var newMembers = partyMembers
        newMembers[idx] = updatedMember
        partyMembers = newMembers
        
        savePartyState()
        broadcastPartyList()
    }
    
    private func handleCharacterUpdated(charID: UUID, currentHP: Int, maxHP: Int, level: Int, stress: Int, rerollPoints: Int, timestamp: Date) {
        guard role == .dungeonMaster else { return }
        guard let idx = partyMembers.firstIndex(where: { $0.id == charID }) else { return }
        
        if let lastUpdate = lastUpdateTime[charID], timestamp <= lastUpdate {
            return
        }
        
        lastUpdateTime[charID] = timestamp

        // ✅ Запоминаем СТАРЫЙ level для сравнения
        let oldLevel = partyMembers[idx].level
        
        var updatedMember = partyMembers[idx]
        updatedMember.currentHP = currentHP
        updatedMember.maxHP = maxHP
        updatedMember.level = level
        updatedMember.stress = stress
        updatedMember.rerollPoints = rerollPoints
        updatedMember.lastSeen = Date()

        var newMembers = partyMembers
        newMembers[idx] = updatedMember
        partyMembers = newMembers

        savePartyState()
        
        // ✅ Если level изменился — принудительный broadcast (обходит throttling)
        if oldLevel != level {
            log("🎯 Level изменился: \(oldLevel) → \(level), принудительный broadcast")
            forceBroadcastPartyList()
        } else {
            // Обычный broadcast с throttling
            broadcastPartyList()
        }
        
        log("📥 Обновлён игрок \(updatedMember.name): HP=\(currentHP)/\(maxHP), level=\(level)")
    }
    
    private func handlePartyList(members: [PartyMember]) {
        guard role == .player else { return }
        
        log("📥 handlePartyList: получено \(members.count) игроков")
        for (i, member) in members.enumerated() {
            log("   [\(i)] \(member.name) — connected=\(member.isConnected), id=\(member.id.uuidString.prefix(8))")
        }
        
        // ✅ УМНЫЙ MERGE: защищаемся от race condition
        // Если пришёл пустой список — НЕ обнуляем локальный (это явно ошибка timing)
        if members.isEmpty {
            log("⚠️ Получен пустой partyList — сохраняем локальный список (\(partyMembers.count) игроков)")
            return
        }
        
        // ✅ УМНЫЙ MERGE:
        // 1. Все игроки из incoming — актуальные (берём как есть)
        // 2. Локальные игроки, которых НЕТ в incoming — помечаем как offline (но НЕ удаляем)
        // 3. Это защищает от неполных broadcast'ов при throttling
        
        var mergedMembers: [PartyMember] = []
        let incomingIDs = Set(members.map { $0.id })
        
        // Добавляем всех incoming игроков (они актуальные)
        for incomingMember in members {
            mergedMembers.append(incomingMember)
        }
        
        
        // Проверяем локальных игроков, которых нет в incoming
        for localMember in self.partyMembers {
            if !incomingIDs.contains(localMember.id) {
                // Игрок был локально, но ДМ его не видит в сети
                if localMember.isConnected {
                    // Помечаем как offline, но НЕ удаляем (защита от временных race conditions)
                    var offlineMember = localMember
                    offlineMember.isConnected = false
                    offlineMember.lastSeen = Date()
                    mergedMembers.append(offlineMember)
                    log("🔴 \(localMember.name) помечен как offline (нет в списке ДМ-а)")
                } else {
                    // Уже offline — сохраняем как есть
                    mergedMembers.append(localMember)
                }
            }
        }
        
        // Для непустого списка — применяем с проверкой изменений
        let oldCount = self.partyMembers.count
        let newCount = members.count
        
        self.partyMembers = members
        
        if oldCount != newCount {
            log("📋 partyList применён: было \(oldCount), стало \(newCount) игроков")
        } else {
            log("📋 partyList: количество не изменилось (\(newCount))")
        }
    }
    
    private func handleRestVoteResponse(voterID: UUID, accepted: Bool) {
        guard role == .dungeonMaster else { return }
        
        // ✅ Добавляем голос игрока в локальную сессию ДМ-а
        let result = restVotingManager.registerVote(voterID: voterID, accepted: accepted)
        log("📥 Голос от игрока \(voterID): \(accepted ? "ЗА" : "ПРОТИВ"), результат: \(result)")
        
        switch result {
        case .success(let restType, let initiatorName):
            // Все игроки проголосовали ЗА — применяем отдых
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
    }
    
    private func handleRestStarted(restType: RestType) {
        log("🎉 Отдых \(restType.displayName) начался для всех!")
        restVotingManager.cancelSession()
        decrementRestCounter(restType: restType)
        
        // ✅ ИСПРАВЛЕНО: Применяем эффект сразу, не дожидаясь UI
        if role == .player, let character = selectedCharacter {
            applyRestEffectImmediately(to: character, type: restType)
        }
        
        // Визуальный эффект (анимация)
        restVotingManager.startEffect(restType: restType, initiatorName: "партии")
    }
    
    private func handleRestsReset() {
        guard role == .player else { return }
        gameRules.resetRests()
    }
    
    private func decrementRestCounter(restType: RestType) {
        if restType == .short {
            gameRules.shortRestsAvailable -= 1
        } else {
            gameRules.longRestsAvailable -= 1
        }
        saveGameRules(gameRules)
    }
    // MARK: - Обработка запроса голосования от игрока
    
    private func handleRequestRestVote(restType: RestType, requesterID: UUID, requesterName: String) {
        guard role == .dungeonMaster else { return }
        
        // ДМ НЕ участвует в голосовании — только игроки
        var eligibleIDs: Set<UUID> = []
        for member in partyMembers where member.isConnected {
            eligibleIDs.insert(member.id)
        }
        
        guard !eligibleIDs.isEmpty else {
            log("⚠️ Запрос голосования отклонён: нет игроков")
            return
        }
        
        guard eligibleIDs.contains(requesterID) else {
            log("⚠️ Инициатор \(requesterName) не в списке подключённых игроков")
            return
        }
        
        log("🎲 ДМ формирует голосование по запросу \(requesterName): \(eligibleIDs.count) игроков")
        
        // ДМ добавляет голос инициатора (ЗА) в initialVotes
        let initialVotes: [UUID: Bool] = [requesterID: true]
        
        // Рассылаем restVoteRequest всем игрокам С ГОЛОСОМ ИНИЦИАТОРА
        let message = PartyMessage.restVoteRequest(
            initiatorID: requesterID,
            initiatorName: requesterName,
            restType: restType,
            eligibleVoterIDs: eligibleIDs,
            initialVotes: initialVotes
        )
        send(message)
        
        // ДМ создаёт локальную сессию с голосом инициатора
        restVotingManager.startSession(
            initiatorID: requesterID,
            initiatorName: requesterName,
            restType: restType,
            eligibleVoterIDs: eligibleIDs,
            initiatorAutoVote: false,
            initialVotes: initialVotes
        )
        
        log("🗳️ ДМ: сессия создана с голосом инициатора: 1/\(eligibleIDs.count)")
        
        // Проверяем: вдруг в партии только 1 игрок — тогда сразу успех
        let result = restVotingManager.checkIfCompleted()
        if case .success(let completedRestType, let name) = result {
            send(.restStarted(restType: completedRestType))
            decrementRestCounter(restType: completedRestType)
            if let dmCharacter = selectedCharacter {
                applyRestEffectImmediately(to: dmCharacter, type: completedRestType)
            }
            restVotingManager.startEffect(restType: completedRestType, initiatorName: name)
        }
    }
    
    /// Обрабатывает команду от ДМа привязать персонажа к кампании
    private func handleCampaignBinding(campaignID: UUID) {
        log("🔗 Получена команда привязки к кампании: \(campaignID)")
        
        // ✅ Сохраняем campaignID в UserDefaults для будущих подключений
        UserDefaults.standard.set(campaignID.uuidString, forKey: "pendingCampaignBinding")
        self.pendingCampaignID = campaignID
        
        log("✅ CampaignID сохранён в UserDefaults: \(campaignID)")
    }
    // MARK: - Принудительная синхронизация
    
    /// Принудительная синхронизация (обходит throttling).
    /// Используется при критичных изменениях: level up, demotion, смена класса.
    func syncBasic(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState,
              let session = session,
              !session.connectedPeers.isEmpty else { return }

        // ✅ DEBOUNCE: отменяем предыдущую отложенную задачу
        throttledSyncTask?.cancel()
        
        // Захватываем текущие значения для отложенной отправки
        let characterID = character.id
        let currentHP = character.currentHP
        let maxHP = character.hitPoints
        let level = character.level
        let stress = character.stress
        let rerollPoints = character.rerollPoints
        
        // ✅ Создаём новую отложенную задачу (debounce 0.5 сек)
        throttledSyncTask = Task { [weak self] in
            // Ждём 0.5 секунды тишины
            try? await Task.sleep(for: .seconds(0.5))
            
            guard !Task.isCancelled, let self = self else { return }
            
            // Проверяем что всё ещё подключены
            guard case .connected = self.connectionState else { return }
            
            self.lastBasicSyncTime = Date()
            
            let message = PartyMessage.characterUpdated(
                characterID: characterID,
                currentHP: currentHP,
                maxHP: maxHP,
                level: level,
                stress: stress,
                rerollPoints: rerollPoints,
                timestamp: Date()
            )
            self.send(message)
            
            self.log("📤 syncBasic (debounced): HP=\(currentHP)/\(maxHP), level=\(level)")
        }
    }
    /// Принудительная синхронизация (обходит debounce).
    /// Используется при критичных изменениях: level up, demotion, смена класса.
    func forceSyncBasic(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState,
              let session = session,
              !session.connectedPeers.isEmpty else { return }
        
        // ✅ КРИТИЧНО: отменяем отложенную задачу чтобы она не перезаписала свежие данные
        throttledSyncTask?.cancel()
        throttledSyncTask = nil
        
        // Сбрасываем throttling
        lastBasicSyncTime = .distantPast
        
        let message = PartyMessage.characterUpdated(
            characterID: character.id,
            currentHP: character.currentHP,
            maxHP: character.hitPoints,
            level: character.level,
            stress: character.stress,
            rerollPoints: character.rerollPoints,
            timestamp: Date()
        )
        send(message)
        
        lastBasicSyncTime = Date()
        
        log("📤 forceSyncBasic: HP=\(character.currentHP)/\(character.hitPoints), level=\(character.level)")
    }
    // MARK: - Принудительный broadcast (обходит throttling)

    /// Принудительный broadcast всего partyList (обходит throttling).
    /// Используется при критичных изменениях: level up, demotion.
    func forceBroadcastPartyList() {
        guard role == .dungeonMaster,
              let session = session,
              !session.connectedPeers.isEmpty else { return }
        
        // Отменяем отложенные задачи
        throttledBroadcastTask?.cancel()
        throttledBroadcastTask = nil
        
        // Сбрасываем throttling
        lastBroadcastTime = .distantPast
        
        send(PartyMessage.partyList(members: partyMembers))
        
        lastBroadcastTime = Date()
        
        log("📤 forceBroadcastPartyList: \(partyMembers.count) игроков")
    }
}
