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

    func syncBasic(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState,
              let session = session,
              !session.connectedPeers.isEmpty else { return }

        let now = Date()
        // ✅ Увеличен throttling с 0.5 до 1.0 секунды
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
            rerollPoints: character.rerollPoints,
            timestamp: Date()  // ✅ Добавлено
        )
        send(message)
    }

    func syncFull(_ character: DNDCharacter) {
        guard role == .player,
              case .connected = connectionState else { return }
        syncBasic(character)
        sendCharacterDetails(for: character)
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

    private func scheduleThrottledSync(for character: DNDCharacter) {
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
            let remaining = (self?.basicSyncThrottle ?? 1.0) - elapsed

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
    }

    // MARK: - Broadcast

    func broadcastPartyList() {
        guard role == .dungeonMaster,
              let session = session,
              !session.connectedPeers.isEmpty else { return }

        let now = Date()
        guard now.timeIntervalSince(lastBroadcastTime) >= broadcastThrottle else { return }

        lastBroadcastTime = now
        send(PartyMessage.partyList(members: partyMembers))
    }
    // MARK: - Обработка запроса голосования от игрока

    private func handleRequestRestVote(restType: RestType, requesterID: UUID, requesterName: String) {
        guard role == .dungeonMaster else { return }
        
        // ✅ ДМ НЕ участвует — формирует список ТОЛЬКО из игроков
        var eligibleIDs: Set<UUID> = []
        for member in partyMembers where member.isConnected {
            eligibleIDs.insert(member.id)
        }
        
        // Если нет игроков (странная ситуация) — отклоняем
        guard !eligibleIDs.isEmpty else {
            log("⚠️ Запрос голосования отклонён: нет игроков")
            return
        }
        
        log("🎲 ДМ формирует голосование по запросу \(requesterName): \(eligibleIDs.count) игроков")
        
        // Рассылаем restVoteRequest всем (ДМ не голосует, только рассылает)
        let message = PartyMessage.restVoteRequest(
            initiatorID: requesterID,
            initiatorName: requesterName,
            restType: restType,
            eligibleVoterIDs: eligibleIDs  // только игроки, без ДМ
        )
        send(message)
        
        // ДМ ведёт локальный подсчёт, но НЕ голосует
        restVotingManager.startSession(
            initiatorID: requesterID,
            initiatorName: requesterName,
            restType: restType,
            eligibleVoterIDs: eligibleIDs,
            initiatorAutoVote: false  // ✅ ДМ не голосует, даже локально
        )
    }
    // MARK: - Helpers

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
        case .playerJoined(let charID, let name, let raceRaw, let cls, let level, let currentHP, let maxHP, let avatarData):
            handlePlayerJoined(charID: charID, peerID: peerID, name: name, raceRaw: raceRaw, cls: cls, level: level, currentHP: currentHP, maxHP: maxHP, avatarData: avatarData)

        case .characterDetails(let charID, let stats, let rerollPoints, let inventory, let skillProficiencies, let background, let alignment):
            handleCharacterDetails(charID: charID, stats: stats, rerollPoints: rerollPoints, inventory: inventory, skillProficiencies: skillProficiencies, background: background, alignment: alignment)

        case .characterUpdated(let charID, let currentHP, let maxHP, let level, let stress, let rerollPoints, let timestamp):
            handleCharacterUpdated(charID: charID, currentHP: currentHP, maxHP: maxHP, level: level, stress: stress, rerollPoints: rerollPoints, timestamp: timestamp)

        case .partyList(let members):
            handlePartyList(members: members)

        case .playerLeft(let charID):
            partyMembers.removeAll { $0.id == charID }
            savePartyState()
            
            // 🆕 Игрок запросил начать голосование — ДМ формирует список и рассылает
        case .requestRestVote(let restType, let requesterID, let requesterName):
                handleRequestRestVote(restType: restType, requesterID: requesterID, requesterName: requesterName)
            
        case .restVoteRequest(let initiatorID, let initiatorName, let restType, let eligibleVoterIDs):
            handleRestVoteRequest(initiatorID: initiatorID, initiatorName: initiatorName, restType: restType, eligibleVoterIDs: eligibleVoterIDs)

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

        case .ping: send(.pong)
        case .pong, .requestCharacterSync: break
        }
    }

    // MARK: - Message Handlers (приватные)

    private func handlePlayerJoined(charID: UUID, peerID: MCPeerID, name: String, raceRaw: String, cls: String, level: Int, currentHP: Int, maxHP: Int, avatarData: Data?) {
        guard role == .dungeonMaster else { return }
        guard peerID.displayName != self.localPeerID.displayName else { return }

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
        } else {
            partyMembers.append(member)
        }
        savePartyState()
        broadcastPartyList()
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

        // ✅ ВЕРСИОНИРОВАНИЕ: игнорируем устаревшие сообщения
        if let lastUpdate = lastUpdateTime[charID], timestamp <= lastUpdate {
            log("⏰ Игнорируем устаревшее обновление от \(charID) (timestamp: \(timestamp))")
            return
        }
        
        lastUpdateTime[charID] = timestamp

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
        broadcastPartyList()
    }

    private func handlePartyList(members: [PartyMember]) {
        guard role == .player else { return }
        self.partyMembers = members
        log("📋 Получен список партии: \(members.count) игроков")
    }

    private func handleRestVoteRequest(initiatorID: UUID, initiatorName: String, restType: RestType, eligibleVoterIDs: Set<UUID>) {
        // ✅ Определяем: я ли инициатор?
        let isInitiator = (selectedCharacter?.id == initiatorID)
        
        if isInitiator {
            // ✅ Я ИНИЦИАТОР: уже создал сессию локально в initiateRestVote
            // Теперь просто ОБНОВЛЯЕМ eligibleVoterIDs на актуальный список от ДМ-а
            if var session = restVotingManager.activeRestVote {
                // Сохраняем уже отданные голоса (мой голос ЗА)
                let existingVotes = session.votes
                session.eligibleVoterIDs = eligibleVoterIDs
                session.votes = existingVotes
                restVotingManager.activeRestVote = session
                
                log("🔄 Инициатор: обновил eligibleVoterIDs с \(existingVotes.count) до \(eligibleVoterIDs.count)")
                
                // Проверяем: вдруг уже все проголосовали (если партия из 1 игрока)
                if existingVotes.count >= eligibleVoterIDs.count {
                    let allAccepted = existingVotes.values.allSatisfy { $0 }
                    if allAccepted {
                        let result: RestVotingManager.VoteResult = .success(session.restType, session.initiatorName)
                        restVotingManager.activeRestVote = nil
                        // Обработка успеха произойдёт в sendRestVote
                    }
                }
            }
            return
        }
        
        // ✅ Я НЕ инициатор — создаём сессию с нуля
        if selectedCharacter != nil || role == .dungeonMaster {
            restVotingManager.startSession(
                initiatorID: initiatorID,
                initiatorName: initiatorName,
                restType: restType,
                eligibleVoterIDs: eligibleVoterIDs,
                initiatorAutoVote: false  // ✅ Я не инициатор — не голосую автоматически
            )
            
            log("📥 Получен restVoteRequest: инициатор=\(initiatorName), eligible=\(eligibleVoterIDs.count), я=голосующий")
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
}
