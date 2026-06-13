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
        // ✅ ИСПРАВЛЕНИЕ КРАША: MCSession не потокобезопасен.
        // Всегда выполняем чтение пиров и отправку на главном потоке.
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let session = self.session else {
                #if DEBUG
                self?.log("⚠️ send: session nil")
                #endif
                return
            }

            // ✅ Безопасно копируем массив пиров в локальную переменную
            let peers = session.connectedPeers
            
            guard !peers.isEmpty else {
                #if DEBUG
                self.log("⚠️ send: нет connected peers")
                #endif
                return
            }

            do {
                let data = try JSONEncoder().encode(message)
                #if DEBUG
                self.log("📦 Отправка \(data.count) байт \(peers.count) peer(ам)")
                #endif
                // ✅ Используем локальную копию peers для отправки
                try session.send(data, toPeers: peers, with: .reliable)
            } catch {
                #if DEBUG
                self.log("❌ Ошибка отправки: \(error)")
                #endif
            }
        }
    }

    func sendJoinMessage(for character: DNDCharacter.Snapshot) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }

        let effectiveCampaignID = pendingCampaignID ?? character.campaignID
        
        // ✅ ВЫЧИСЛЯЕМ: есть ли другие активные персонажи в этой кампании
        // ВАЖНО: работаем только с уже загруженными @Model объектами на MainActor
        let hasOtherActiveCharacter: Bool
        if let campaignID = effectiveCampaignID {
            let otherCharsInCampaign = self.availableCharacters.filter {
                // Безопасное сравнение: используем snapshot.id (value type)
                $0.campaignID == campaignID && $0.id != character.id
            }
            hasOtherActiveCharacter = !otherCharsInCampaign.isEmpty
            
            if hasOtherActiveCharacter {
                let names = otherCharsInCampaign.map { $0.displayName }.joined(separator: ", ")
                log("⚠️ На устройстве есть другие персонажи в этой кампании: \(names)")
            }
        } else {
            hasOtherActiveCharacter = false
        }

        let message = PartyMessage.playerJoined(
            characterID: character.id,
            name: character.displayName,
            race: character.race.rawValue,
            characterClass: character.characterClass.rawValue,
            level: character.level,
            currentHP: character.currentHP,
            maxHP: character.hitPoints,
            avatarData: character.avatarData,
            campaignID: effectiveCampaignID,
            hasOtherActiveCharacterInCampaign: hasOtherActiveCharacter
        )
        send(message)
        log("📤 playerJoined отправлен для \(character.displayName) (hasOtherActive: \(hasOtherActiveCharacter))")

        sendCharacterDetails(for: character)
        log("📋 characterDetails отправлен при подключении")
    }

    func sendCharacterDetails(for snapshot: DNDCharacter.Snapshot) {
        guard let session = session, !session.connectedPeers.isEmpty else { return }

        // Безопасно получаем оригинальный @Model объект по ID из snapshot
        guard let character = availableCharacters.first(where: { $0.id == snapshot.id })
                ?? selectedCharacter else {
            log("⚠️ sendCharacterDetails: не найден персонаж с ID \(snapshot.id)")
            return
        }

        let proficientSkills = getProficientSkills(for: character)

        let message = PartyMessage.characterDetails(
            characterID: character.id,
            stats: character.stats,
            rerollPoints: character.rerollPoints,
            inventory: character.inventory,
            skillProficiencies: Array(proficientSkills),
            background: character.background,
            alignment: character.alignment,
            money: character.money
        )
        send(message)
    }
  
// MARK: - Синхронизация

    func syncFull(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState else { return }
        syncBasic(character)
        // ✅ Принудительная синхронизация — обходим throttling
            
        let snapshot = DNDCharacter.Snapshot(from: character)
        sendCharacterDetails(for: snapshot)
        
        // ✅ ДОБАВЛЕНО: логирование
            log("📤 syncFull: HP=\(character.currentHP)/\(character.hitPoints), level=\(character.level), inventory=\(character.inventory.count)")
    }
    
// MARK: - Синхронизация удаления персонажа
    
    /// Синхронизирует статус удаления персонажа с ДМ
    func syncCharacterDeletion(characterID: UUID) {
        guard case .connected = connectionState,
              role == .player else {
            return
        }
        
        /// Удаляет участника из списка партии (используется ДМом при локальном удалении)
        func removePartyMember(characterID: UUID) {
            guard role == .dungeonMaster else { return }
            
            // Ищем игрока в живом списке partyMembers
            if let memberIndex = partyMembers.firstIndex(where: { $0.id == characterID }) {
                let deletedName = partyMembers[memberIndex].name
                
                // Меняем статус на "удалён" и "оффлайн"
                var updatedMember = partyMembers[memberIndex]
                updatedMember.isConnected = false
                updatedMember.isCharacterDeleted = true
                updatedMember.lastSeen = Date()
                
                // Обновляем массив partyMembers
                var newMembers = partyMembers
                newMembers[memberIndex] = updatedMember
                partyMembers = newMembers
                
                // Также обновляем сохранённую кампанию
                if var campaign = campaignManager.activeCampaign,
                   let campaignMemberIndex = campaign.members.firstIndex(where: { $0.id == characterID }) {
                    campaign.members[campaignMemberIndex].isCharacterDeleted = true
                    campaign.members[campaignMemberIndex].isConnected = false
                    campaignManager.updateActiveCampaign(members: campaign.members)
                }
                
                // Сохраняем состояние и рассылаем обновлённый список всем
                savePartyState()
                broadcastPartyList()
                
                log("🗑️ ДМ локально удалил игрока \(deletedName) из списка партии")
            } else {
                log("⚠️ ДМ: попытка удалить \(characterID), но его нет в partyMembers")
            }
        }
        let message = PartyMessage.characterDeleted(characterID: characterID)
        send(message)
        log("🗑️ Синхронизация удаления персонажа: \(characterID)")
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
                timestamp: Date()  //  Добавлено
            )
            self.send(message)
        }
    } */

// MARK: - Broadcast

    func broadcastPartyList() {
        guard role == .dungeonMaster else { return }

        //Переносим проверку connectedPeers на главный поток
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let session = self.session,
                  !session.connectedPeers.isEmpty else { return }

            let now = Date()
            if now.timeIntervalSince(self.lastBroadcastTime) < self.broadcastThrottle {
                self.throttledBroadcastTask?.cancel()
                
                // ДОБАВЛЕНО @MainActor: задача выполняется на главном потоке
                self.throttledBroadcastTask = Task { @MainActor [weak self] in
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

            self.lastBroadcastTime = now
            self.send(PartyMessage.partyList(members: self.partyMembers))
            self.log("📤 broadcastPartyList: \(self.partyMembers.count) игроков")
        }
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
            }
// MARK: - Helpers

    private func getProficientSkills(for character: DNDCharacter) -> Set<String> {
        ClassProficiencies.forClass(character.characterClass)
    }
}

// MARK: - Обработка входящих сообщений

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
            let campaignID,
            let hasOtherActiveCharacterInCampaign
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
                campaignID: campaignID,
                hasOtherActiveCharacterInCampaign: hasOtherActiveCharacterInCampaign
            )
        case .characterDetails(let charID, let stats, let rerollPoints, let inventory, let skillProficiencies, let background, let alignment, let money):
            handleCharacterDetails(charID: charID, stats: stats, rerollPoints: rerollPoints, inventory: inventory, skillProficiencies: skillProficiencies, background: background, alignment: alignment, money: money)
            
        case .characterUpdated(let characterID, let currentHP, let maxHP, let level, let stress, let rerollPoints, let timestamp, let money):
            handleCharacterUpdated(
                charID: characterID,
                currentHP: currentHP,
                maxHP: maxHP,
                level: level,
                stress: stress,
                rerollPoints: rerollPoints,
                timestamp: timestamp,
                money: money
            )
        case .characterDeleted(let characterID):
            // ✅ НОВОЕ: Обработка удаления персонажа
            handleCharacterDeletion(characterID: characterID)
            
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
            
        case .heartbeatResponse(_):
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
            
        case .moneyUpdate(let characterID, let amount, let reason):
            handleMoneyUpdate(characterID: characterID, amount: amount, reason: reason)
            
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
            
            // ✅ КРОССПЛАТФОРМЕННО: используем PlatformCompatibility
            PlatformCompatibility.hapticNotification(.error)
            
        case .ping: send(.pong)
        case .pong, .requestCharacterSync: break
        // 🆕 Обработка передачи предмета
        case .itemTransfer(let item, let fromID, let fromName, let toID):
                handleItemTransfer(
                    item: item,
                    fromCharacterID: fromID,
                    fromCharacterName: fromName,
                    toCharacterID: toID
                )
           
            // 🆕 Обработка передачи золота
        case .goldTransfer(let amount, let fromID, let fromName, let toID):
                        handleGoldTransfer(
                            amount: amount,
                            fromCharacterID: fromID,
                            fromCharacterName: fromName,
                            toCharacterID: toID
                        )
            
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
        campaignID: UUID?,
        hasOtherActiveCharacterInCampaign: Bool
    ) {
        guard role == .dungeonMaster else { return }
        guard peerID.displayName != self.localPeerID.displayName else { return }
        
        // ═══════════════════════════════════════════════════════════════
        // 1. ПРОВЕРКА МУЛЬТИБОКСИНГА НА ОСНОВЕ ФЛАГА ОТ ИГРОКА
        // ═══════════════════════════════════════════════════════════════
        if let existingIndex = partyMembers.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
            let existingMember = partyMembers[existingIndex]
            
            if existingMember.id == charID {
                // ✅ Тот же персонаж переподключается (например, после обрыва связи)
                log("🔄 Тот же персонаж \(name) переподключается. Обновляем данные.")
            } else {
                // ⚠️ Это ДРУГОЙ персонаж с того же устройства
                if hasOtherActiveCharacterInCampaign {
                    // ❌ На устройстве игрока есть другой активный персонаж — БЛОКИРУЕМ
                    log("⛔ Отклонено: На устройстве \(peerID.displayName) есть другой активный персонаж в этой кампании.")
                    sendRejection(
                        to: peerID,
                        reason: "На вашем устройстве уже есть другой активный персонаж в этой кампании. Сначала удалите его или отключите от партии."
                    )
                    return
                } else {
                    // ✅ Других активных персонажей нет — удаляем старую запись и разрешаем нового
                    log("✅ На устройстве нет других активных персонажей. Удаляем старую запись \(existingMember.name) и разрешаем нового: \(name).")
                    
                    var newMembers = partyMembers
                    newMembers.remove(at: existingIndex)
                    partyMembers = newMembers
                }
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // 2. ✅ ПРОВЕРКА НА УРОВНЕ ПАРТИИ (ЗАЩИТА ОТ МУЛЬТИАККАУНТИНГА)
        // ═══════════════════════════════════════════════════════════════
        if let incomingCampaignID = campaignID {
            // Ищем в текущем списке партии ДМа другого игрока с той же кампанией
            if let duplicateMember = partyMembers.first(where: {
                $0.campaignID == incomingCampaignID && $0.id != charID && $0.isConnected
            }) {
                log("⛔ ДМ: отклоняем подключение \(name) — в партии уже есть \(duplicateMember.name) с кампанией \(incomingCampaignID.uuidString.prefix(8))")
                sendRejection(
                    to: peerID,
                    reason: "В партии уже есть ваш персонаж: \(duplicateMember.name). Отключите его перед подключением другого."
                )
                return
            }
        }
        
        // ═══════════════════════════════════════════════════════════════
        // 3. ДОБАВЛЕНИЕ ИЛИ ОБНОВЛЕНИЕ УЧАСТНИКА В СПИСКЕ
        // ═══════════════════════════════════════════════════════════════
        let race = Race(rawValue: raceRaw) ?? .human
        
        var member = PartyMember(
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
        
        member.isConnected = true
        member.isCharacterDeleted = false
        member.lastSeen = Date()
        
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
    
    private func handleCharacterDetails(charID: UUID, stats: AbilityScores, rerollPoints: Int, inventory: [InventoryItem], skillProficiencies: [String], background: String, alignment: DNDAlignment, money: Int) {
        guard role == .dungeonMaster else { return }
        guard let idx = partyMembers.firstIndex(where: { $0.id == charID }) else { return }
        
        var updatedMember = partyMembers[idx]
        updatedMember.stats = stats
        updatedMember.rerollPoints = rerollPoints
        updatedMember.inventory = inventory
        updatedMember.skillProficiencies = skillProficiencies
        updatedMember.background = background
        updatedMember.alignment = alignment
        updatedMember.money = money 
        
        var newMembers = partyMembers
        newMembers[idx] = updatedMember
        partyMembers = newMembers
        
        savePartyState()
        broadcastPartyList()
    }
    
    private func handleCharacterUpdated(charID: UUID, currentHP: Int, maxHP: Int, level: Int, stress: Int, rerollPoints: Int, timestamp: Date, money: Int) {
        guard role == .dungeonMaster else { return }
        guard let idx = partyMembers.firstIndex(where: { $0.id == charID }) else { return }
        
        if let lastUpdate = lastUpdateTime[charID], timestamp <= lastUpdate {
            return
        }
        
        lastUpdateTime[charID] = timestamp
        
        //Запоминаем СТАРЫЙ level для сравнения
        let oldLevel = partyMembers[idx].level
        
        var updatedMember = partyMembers[idx]
        updatedMember.currentHP = currentHP
        updatedMember.maxHP = maxHP
        updatedMember.level = level
        updatedMember.stress = stress
        updatedMember.rerollPoints = rerollPoints
        updatedMember.money = money
        updatedMember.lastSeen = Date()
        
        
        var newMembers = partyMembers
        newMembers[idx] = updatedMember
        partyMembers = newMembers
        
        savePartyState()
        
        //Если level изменился — принудительный broadcast (обходит throttling)
        if oldLevel != level {
            log("🎯 Level изменился: \(oldLevel) → \(level), принудительный broadcast")
            forceBroadcastPartyList()
        } else {
            // Обычный broadcast с throttling
            broadcastPartyList()
        }
        
        log("📥 Обновлён игрок \(updatedMember.name): HP=\(currentHP)/\(maxHP), level=\(level)")
    }
    
// MARK: - Обработка удаления персонажа

    private func handleCharacterDeletion(characterID: UUID) {
        guard role == .dungeonMaster else { return }
        
        // Ищем игрока в живом списке partyMembers
        if let memberIndex = partyMembers.firstIndex(where: { $0.id == characterID }) {
            let deletedName = partyMembers[memberIndex].name
            
            // НЕ удаляем, а помечаем как "удалён" и "оффлайн"
            var updatedMember = partyMembers[memberIndex]
            updatedMember.isConnected = false
            updatedMember.isCharacterDeleted = true  // Флаг для вкладки "УДАЛЁННЫЕ"
            updatedMember.lastSeen = Date()
            
            // Обновляем массив partyMembers
            var newMembers = partyMembers
            newMembers[memberIndex] = updatedMember
            partyMembers = newMembers
            
            // Также обновляем сохранённую кампанию (для восстановления после перезапуска)
            if var campaign = campaignManager.activeCampaign,
               let campaignMemberIndex = campaign.members.firstIndex(where: { $0.id == characterID }) {
                campaign.members[campaignMemberIndex].isCharacterDeleted = true
                campaign.members[campaignMemberIndex].isConnected = false
                campaignManager.updateActiveCampaign(members: campaign.members)
            }
            
            // Сохраняем состояние и рассылаем обновлённый список всем
            savePartyState()
            broadcastPartyList()
            
            log("🗑️ ДМ: Игрок \(deletedName) удалил персонажа. Перемещён во вкладку 'УДАЛЁННЫЕ'.")
        } else {
            log("⚠️ ДМ: Получено уведомление об удалении \(characterID), но его нет в partyMembers")
        }
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
        
        self.partyMembers = mergedMembers
        
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
        
        // ✅ Записываем ID и имя кампании в модель персонажа
        if let character = selectedCharacter {
            character.campaignID = campaignID
            character.campaignName = "Текущая кампания"
            
            log("✅ CampaignID записан в модель персонажа: \(campaignID)")
        } else {
            log("⚠️ Не удалось записать CampaignID: selectedCharacter равен nil")
        }
    }
        // MARK: - Принудительная синхронизация
        
        /// Принудительная синхронизация (обходит throttling).
        /// Используется при критичных изменениях: level up, demotion, смена класса.
    func syncBasic(_ character: DNDCharacter) {
        guard role == .player else { return }
        
        // ✅ Проверку состояния и сессии делаем на главном потоке
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  case .connected = self.connectionState,
                  let session = self.session,
                  !session.connectedPeers.isEmpty else { return }
            
            self.throttledSyncTask?.cancel()
             
            let characterID = character.id
            let currentHP = character.currentHP
            let maxHP = character.hitPoints
            let level = character.level
            let stress = character.stress
            let rerollPoints = character.rerollPoints
            
            // ✅ ДОБАВЛЕНО @MainActor: задача выполняется на главном потоке
            self.throttledSyncTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(0.5))
                 
                guard !Task.isCancelled, let self = self else { return }
                guard case .connected = self.connectionState else { return }
                
                self.lastBasicSyncTime = Date()
                
                let message = PartyMessage.characterUpdated(
                    characterID: characterID,
                    currentHP: currentHP,
                    maxHP: maxHP,
                    level: level,
                    stress: stress,
                    rerollPoints: rerollPoints,
                    timestamp: Date(),
                    money: character.money
                )
                self.send(message)
                
                self.log("📤 syncBasic (debounced): HP=\(currentHP)/\(maxHP), level=\(level)")
            }
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
                timestamp: Date(),
                money: character.money
            )
            send(message)
            
            lastBasicSyncTime = Date()
            
            log("📤 forceSyncBasic: HP=\(character.currentHP)/\(character.hitPoints), level=\(character.level)")
        }
    
    // MARK: - Синхронизация удаления персонажа
    /// Помечает персонажа как удалённого (используется ДМом при локальном удалении).
    /// Персонаж НЕ удаляется из partyMembers, а перемещается во вкладку "УДАЛЁННЫЕ".
    func markCharacterAsDeleted(characterID: UUID) {
        guard role == .dungeonMaster else { return }
        
        // Ищем игрока в списке partyMembers
        guard let memberIndex = partyMembers.firstIndex(where: { $0.id == characterID }) else {
            log("⚠️ markCharacterAsDeleted: персонаж \(characterID) не найден в partyMembers")
            return
        }
        
        let deletedName = partyMembers[memberIndex].name
        
        // Помечаем как "удалён" и "оффлайн"
        var updatedMember = partyMembers[memberIndex]
        updatedMember.isConnected = false
        updatedMember.isCharacterDeleted = true  // ✅ Флаг для вкладки "УДАЛЁННЫЕ"
        updatedMember.lastSeen = Date()
        
        // Обновляем массив partyMembers
        var newMembers = partyMembers
        newMembers[memberIndex] = updatedMember
        partyMembers = newMembers
        
        // Также обновляем сохранённую кампанию (для восстановления после перезапуска)
        if var campaign = campaignManager.activeCampaign,
           let campaignMemberIndex = campaign.members.firstIndex(where: { $0.id == characterID }) {
            campaign.members[campaignMemberIndex].isCharacterDeleted = true
            campaign.members[campaignMemberIndex].isConnected = false
            campaignManager.updateActiveCampaign(members: campaign.members)
        }
        
        // Сохраняем состояние и рассылаем обновления
        savePartyState()
        broadcastPartyList()
        
        log("🗑️ ДМ локально удалил игрока \(deletedName). Перемещён во вкладку 'УДАЛЁННЫЕ'.")
    }
    /// Вызывается игроком при удалении персонажа, чтобы уведомить ДМа
    func notifyCharacterDeletion(characterID: UUID) {
        guard role == .player,
              case .connected = connectionState else {
            return
        }
        
        let message = PartyMessage.characterDeleted(characterID: characterID)
        send(message)
        log("📤 Игрок уведомил ДМа об удалении персонажа: \(characterID)")
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
    // MARK: - 💰 Синхронизация денег

   /* private func handleMoneyUpdate(characterID: UUID, amount: Int, reason: String) {
        log("💰 Получено обновление денег от ДМа: \(amount) (причина: \(reason))")
        
        // Используем selectedCharacter напрямую (@Model сохраняет изменения автоматически)
        if let character = selectedCharacter, character.id == characterID {
            character.money = amount
            log("💰 Деньги обновлены у \(character.displayName): \(amount)")
            
            // Отправляем обновлённого персонажа ДМу
            if case .connected = connectionState {
                syncCharacterUpdate(character)
            }
            
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } else {
            log("⚠️ handleMoneyUpdate: персонаж \(characterID) не является текущим selectedCharacter")
        }
    } */
    // MARK: - 🔄 Синхронизация полного обновления персонажа

    /// Отправляет полное обновление персонажа ДМу (после изменения денег/инвентаря/HP)
    func syncCharacterUpdate(_ character: DNDCharacter) {
        guard case .connected = connectionState, role == .player else { return }
        
        let message = PartyMessage.characterUpdated(
            characterID: character.id,
            currentHP: character.currentHP,
            maxHP: character.hitPoints,
            level: character.level,        // ← ОБЯЗАТЕЛЬНО перед stress
            stress: character.stress,
            rerollPoints: character.rerollPoints,
            timestamp: Date(),
            money: character.money         // ← ДОБАВИТЬ В КОНЕЦ
        )
        send(message)
        log("🔄 Отправлено обновление персонажа \(character.displayName) (HP: \(character.currentHP), золото: \(character.money))")
    }
}
// MARK: - 🆕 Передача золота

extension PartyManager {
    /// ДМ отправляет обновление золота игроку
    func sendMoneyUpdate(to peerID: MCPeerID, characterID: UUID, amount: Int, reason: String) {
        guard role == .dungeonMaster else {
            log("⚠️ [DM] sendMoneyUpdate: вызвано не ДМ-ом")
            return
        }
        
        let message = PartyMessage.moneyUpdate(
            characterID: characterID,
            amount: amount,
            reason: reason
        )
        
        do {
                let data = try JSONEncoder().encode(message)
                // Отправляем конкретно этому пиру, а не всем подряд
                try session?.send(data, toPeers: [peerID], with: .reliable)
                log("✅ [DM] Золото отправлено: \(amount) для characterID: \(characterID), peer: \(peerID.displayName)")
            } catch {
                log("❌ [DM] Ошибка отправки золота: \(error.localizedDescription)")
            }
        
        send(message)
        log("💰 sendMoneyUpdate: \(amount) золота для \(characterID), причина: \(reason)")
        
        // ✅ Обновляем локального члена партии (для отображения у ДМ)
        if let idx = partyMembers.firstIndex(where: { $0.id == characterID }) {
            var updatedMember = partyMembers[idx]
            updatedMember.money = amount
            var newMembers = partyMembers
            newMembers[idx] = updatedMember
            partyMembers = newMembers
            savePartyState()
            broadcastPartyList()
        }
    }
}
// MARK: - 🆕 Обработка обновления золота

extension PartyManager {
    private func handleMoneyUpdate(characterID: UUID, amount: Int, reason: String) {
        guard role == .player else {
            log("⚠️ [Игрок] handleMoneyUpdate: проигнорировано, так как роль не player")
            return
        }
        
        log("📥 [Игрок] Получено moneyUpdate: characterID=\(characterID), amount=\(amount)")
        
        guard let character = selectedCharacter, character.id == characterID else {
            log("⚠️ handleMoneyUpdate: персонаж не найден или не выбран")
            return
        }
        
        guard character.id == characterID else {
            log("❌ [Игрок] ОШИБКА: ID не совпадает! Ожидался \(characterID), а у selectedCharacter ID = \(character.id)")
            return
        }
        
        log("✅ [Игрок] Персонаж найден: \(character.name). Было золота: \(character.money). Станет: \(amount)")
        
        // ✅ Обновляем золото у локального персонажа
        character.money = amount
        
        log("💾 [Игрок] Значение в памяти изменено. Текущее значение character.money: \(character.money)")
        
        // ✅ SwiftData автоматически сохраняет изменения для @Model объектов
        // Просто логируем успешное обновление
        log("💰 handleMoneyUpdate: золото обновлено до \(amount), причина: \(reason)")
        
        // ✅ Уведомление пользователю
        PlatformCompatibility.hapticNotification(.success)
        
        // ✅ Синхронизируем изменения с ДМ
        syncBasic(character)
    }
    
    private func handleItemTransfer(
        item: InventoryItem,
        fromCharacterID: UUID,
        fromCharacterName: String,
        toCharacterID: UUID
    ) {
        guard role == .player,
              let character = selectedCharacter,
              character.id == toCharacterID else {
            log("⚠️ itemTransfer: не мой персонаж или не игрок")
            return
        }
        
        // Добавляем предмет в инвентарь
        character.inventory.append(item)
        log("📦 Получен предмет '\(item.name)' от \(fromCharacterName)")
        
        // Уведомление пользователю
        PlatformCompatibility.hapticNotification(.success)
    }
    
    // 🆕 Обработка получения золота от другого игрока
    private func handleGoldTransfer(
        amount: Int,
        fromCharacterID: UUID,
        fromCharacterName: String,
        toCharacterID: UUID
    ) {
        guard role == .player,
              let character = selectedCharacter,
              character.id == toCharacterID else {
            log("⚠️ goldTransfer: не мой персонаж или не игрок")
            return
        }
        
        character.money += amount
        log("💰 Получено \(amount) золота от \(fromCharacterName)")
        PlatformCompatibility.hapticNotification(.success)
    }
}
