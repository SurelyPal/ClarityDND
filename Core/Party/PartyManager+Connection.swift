//
//  PartyManager+Connection.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import Foundation
import MultipeerConnectivity

// MARK: - MCSessionDelegate

extension PartyManager: MCSessionDelegate {

    // (добавлен параметр peerID)
    nonisolated func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        Task { @MainActor in
            switch state {
            case .connected:
                self.handlePeerConnected(peerID: peerID, session: session)
            case .connecting:
                self.log("⏳ Подключение: \(peerID.displayName)")
                self.connectionState = .connecting(peerName: peerID.displayName)
            case .notConnected:
                self.handlePeerDisconnected(peerID: peerID, session: session)
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Task { @MainActor [weak self] in
         guard let self = self else { return }
         self.receiveMessage(data, from: peerID)
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // Не используется
    }

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // Не используется
    }

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        // Не используется
    }

    nonisolated func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        certificateHandler(true)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (ДМ создаёт комнату)

extension PartyManager: MCNearbyServiceAdvertiserDelegate {

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            // ✅ Теперь role и session доступны из nonisolated контекста
            guard self.role == .dungeonMaster
            else {
                // ✅ Используем Task для логирования (log() требует MainActor)
        Task { @MainActor in
                    self.log("⚠️ Отклоняем приглашение от \(peerID.displayName): мы не ДМ")
                }
                invitationHandler(false, nil)
                return
            }
        }
        if let session = self.session,
           session.connectedPeers.contains(peerID) {
            Task { @MainActor in
                self.log("ℹ️ Пир \(peerID.displayName) уже подключён, отклоняем дубль")
            }
            invitationHandler(false, nil)
            return
        }

        Task { @MainActor in
            self.log("📥 Приглашение от \(peerID.displayName) — принимаем")
        }

        if self.session == nil {
            self.session = MCSession(
                peer: self.localPeerID,
                securityIdentity: nil,
                encryptionPreference: .none
            )
            self.session?.delegate = self
            Task { @MainActor in
                self.log("⚠️ Fallback: MCSession создан в advertiser delegate")
            }
        }

        invitationHandler(true, self.session)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.log("✅ Приглашение от \(peerID.displayName) принято, session передан")
        }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        Task { @MainActor in
            let errorMessage = "Не удалось создать комнату: \(error.localizedDescription)"
            self.log("⚠️ \(errorMessage)")
            self.lastError = errorMessage
            self.connectionState = .disconnected
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Игрок ищет комнату)

extension PartyManager: MCNearbyServiceBrowserDelegate {

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        let roomCode = info?["roomCode"] ?? "???"
        let campaignIDString = info?["campaignID"]
        let campaignName = info?["campaignName"] ?? "Без названия"
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Получаем правила игры от ДМа
            if let rulesString = info?["gameRules"],
               let rulesData = rulesString.data(using: .utf8),
               let rules = try? JSONDecoder().decode(GameRules.self, from: rulesData) {
                self.gameRules = rules
                self.saveGameRules(rules)
                self.log("📜 Получены правила от ДМа")
            }
            
            self.log("👀 Найдена комната: \(roomCode) от \(peerID.displayName)")
            
            // 🆕 МЯГКАЯ ПРОВЕРКА КАМПАНИИ (не блокирует подключение)
            if let selectedChar = self.selectedCharacter {
                if let charCampaignID = selectedChar.campaignID {
                    // Персонаж привязан к кампании
                    if let roomCampaignIDString = campaignIDString,
                       let roomCampaignID = UUID(uuidString: roomCampaignIDString) {
                        
                        if charCampaignID != roomCampaignID {
                            self.log("⚠️ Внимание: комната '\(campaignName)' принадлежит другой кампании")
                            self.log("ℹ️ Попытка подключения всё равно будет выполнена. ДМ решит, пустить ли вас.")
                            // 🟢 НЕ делаем return! Разрешаем попытку подключения.
                            // Окончательную проверку сделает ДМ в handlePlayerJoined.
                        } else {
                            self.log("✅ Кампания совпадает: '\(campaignName)'")
                        }
                    } else {
                        self.log("ℹ️ У комнаты нет campaignID — подключаемся как гость")
                    }
                } else {
                    self.log("ℹ️ Персонаж не привязан к кампании — подключаемся к любой комнате")
                }
            } else {
                self.log("⚠️ selectedCharacter == nil. Убедитесь, что персонаж выбран перед поиском.")
            }
            
            // Останавливаем поиск и подключаемся
            browser.stopBrowsingForPeers()
            self.joinRoom(peerID: peerID, roomCode: roomCode)
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            self.log("👻 Потеряна: \(peerID.displayName)")
        }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            let errorMessage = "Не удалось начать поиск: \(error.localizedDescription)"
            self.log("⚠️ \(errorMessage)")
            
            // 🆕 БЕЗОПАСНО: показываем ошибку, но НЕ меняем connectionState агрессивно
            self.lastError = errorMessage
            
            // Только если мы действительно в состоянии поиска — возвращаем к выбору
            if case .searching = self.connectionState {
                self.connectionState = .selectingCharacter
                self.log("ℹ️ Возврат к выбору персонажа после ошибки browser")
            }
        }
    }
}

// MARK: - Private Connection Handlers

private extension PartyManager {

    // MARK: - Peer Connected

    func handlePeerConnected(peerID: MCPeerID, session: MCSession) {
        log("✅ Подключено: \(peerID.displayName)")
        connectionState = .connected(peersCount: session.connectedPeers.count)
        disconnectReason = nil

        // ДМ: переподключение уже известного игрока
        if role == .dungeonMaster,
           let idx = partyMembers.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
            var updatedMember = partyMembers[idx]
            updatedMember.isConnected = true
            updatedMember.lastSeen = Date()

            var newMembers = partyMembers
            newMembers[idx] = updatedMember
            partyMembers = newMembers

            log("🟢 Игрок \(peerID.displayName) снова онлайн!")
            savePartyState()
            broadcastPartyList()
        }
        

        // Игрок: отправляем данные и запускаем heartbeat
        if role == .player, let char = selectedCharacter {
            sendJoinMessage(for: char)
            startHeartbeat()
        }
        // ✅ НОВОЕ: Устанавливаем онлайн статус ТОЛЬКО если персонаж не удалён
        // 1. Находим участника партии по его peerID
        if let memberIndex = activeCampaign?.members.firstIndex(where: { $0.peerID == peerID.data }) {
            
            // 2. Проверяем, помечен ли его персонаж как удалённый
            if activeCampaign!.members[memberIndex].isCharacterDeleted {
                log("⚠️ Игрок подключился с удалённым персонажем. Онлайн статус НЕ обновляем.")
            } else {
                // 3. Если персонаж НЕ удалён, ставим его онлайн
                activeCampaign?.members[memberIndex].isOnline = true
                
                // 4. Синхронизируем состояние кампании (если у тебя есть такой метод)
                // syncCampaignState()
            }
        }
    }

    // MARK: - Peer Disconnected (главный диспетчер)

    func handlePeerDisconnected(peerID: MCPeerID, session: MCSession) {
        log("❌ Отключено: \(peerID.displayName)")

        if role == .dungeonMaster {
            handleDMPeerDisconnected(peerID: peerID, session: session)
        } else {
            handlePlayerPeerDisconnected(peerID: peerID, session: session)
        }
    }

    // MARK: - ДМ: отключение игрока

    func handleDMPeerDisconnected(peerID: MCPeerID, session: MCSession) {
        guard let idx = partyMembers.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) else {
            log("⚠️ Отключился неизвестный пир \(peerID.displayName)")
            return
        }

        let disconnectedMemberID = partyMembers[idx].id
        var updatedMember = partyMembers[idx]
        updatedMember.isConnected = false
        updatedMember.lastSeen = Date()

        var newMembers = partyMembers
        newMembers[idx] = updatedMember
        partyMembers = newMembers

        log("🔴 Игрок \(peerID.displayName) отключился (теперь офлайн)")
        savePartyState()

        // Если отключился инициатор голосования — отменяем его
        if let voteSession = restVotingManager.activeRestVote,
           voteSession.initiatorID == disconnectedMemberID {
            log("❌ Инициатор голосования отключился — отменяем")
            let failMsg = PartyMessage.restVoteFailed(reason: "Инициатор отключился")
            send(failMsg)
            restVotingManager.cancelSession()
        }

        broadcastPartyList()

        let count = session.connectedPeers.count
        if count > 0 {
            connectionState = .connected(peersCount: count)
        } else {
            connectionState = .hosting(code: roomCode)
            log("📭 Все игроки отключились")
        }
    }

    // MARK: - Игрок: отключение (возможно, ДМ)

    func handlePlayerPeerDisconnected(peerID: MCPeerID, session: MCSession) {
        stopHeartbeat()

        let count = session.connectedPeers.count

        if count == 0 {
            // Связь с ДМ потеряна — полная очистка
            log("🔴 Связь с ДМ-ом потеряна — полная очистка")

            partyMembers = []
            restVotingManager.resetAll()

            connectionState = .disconnected
            disconnectReason = "Мастер неожиданно отключился"
            lastError = "Связь с Мастером потеряна"


            savePartyState()
        } else {
            connectionState = .connected(peersCount: count)
        }
    }
}

// MARK: - Heartbeat (активная проверка связи с ДМ-ом)

extension PartyManager {

    /// Запускает периодическую проверку связи с ДМ-ом
    func startHeartbeat() {
        stopHeartbeat()

        lastHeartbeatReceived = Date()
        missedHeartbeats = 0

        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
         guard let self = self else { return }
         Task { @MainActor [weak self] in
         self?.sendHeartbeatRequest()
         }
    }

        log("💓 Heartbeat запущен (интервал: \(heartbeatInterval)с, таймаут: \(heartbeatTimeout)с)")
    }

    /// Останавливает heartbeat таймер
    func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    /// Отправляет heartbeat request ДМ-у и проверяет таймаут
    func sendHeartbeatRequest() {
        guard role == .player,
              case .connected = connectionState else {
            stopHeartbeat()
            return
        }

        let timeSinceLastHeartbeat = Date().timeIntervalSince(lastHeartbeatReceived)
        if timeSinceLastHeartbeat > heartbeatTimeout {
            missedHeartbeats += 1
            log("⚠️ Heartbeat пропущен (\(missedHeartbeats)/\(maxMissedHeartbeats)): \(Int(timeSinceLastHeartbeat))с без ответа")

            if missedHeartbeats >= maxMissedHeartbeats {
                log("🔴 ДМ не отвечает \(maxMissedHeartbeats) раза подряд — принудительное отключение")
                handleHostLost()
                return
            }
        } else {
            missedHeartbeats = 0
        }

        send(.heartbeatRequest(timestamp: Date()))
    }

    /// Обрабатывает потерю связи с ДМ-ом (heartbeat timeout)
    func handleHostLost() {
        stopHeartbeat()

        // Отключаем session
        session?.disconnect()
        // session = nil  // УБРАНО: setter недоступен

        
        partyMembers = []
        restVotingManager.resetAll()

        connectionState = .disconnected
        disconnectReason = "Мастер неожиданно отключился"
        lastError = "Связь с Мастером потеряна"

        savePartyState()

        log("🔴 Принудительное отключение: ДМ не отвечает")
    }

    
    
    /// Обновляет время последнего heartbeat (вызывается при получении ответа)
    func updateLastHeartbeat() {
        lastHeartbeatReceived = Date()
        missedHeartbeats = 0
    }
    // MARK: - Универсальная очистка при любом отключении

    /// Вызывается при любом отключении: ручном, автоматическом, потере связи.
    /// Останавливает heartbeat и отключает MCSession.
    func cleanupConnection(reason: String) {
        log("🧹 cleanupConnection: \(reason)")
        
        // Останавливаем heartbeat
        stopHeartbeat()
        
        // Отключаем MCSession (этого достаточно для игрока)
        // advertiser и browser не трогаем — для игрока они не существуют,
        // а для ДМ-а есть отдельная логика в stopHosting
        session?.disconnect()
        
        log("🧹 Очистка завершена")
    }
}
// MARK: - 🆕 Управление кампаниями
extension PartyManager {
    
    /// Завершает текущую сессию кампании
    func endCampaignSession() {
        log("🏁 Завершаем сессию кампании")
                
                // Сохраняем финальное состояние
                savePartyState()
                
                // Сбрасываем активную кампанию
                campaignManager.clearActiveCampaign()
                currentCampaignID = nil
                
                // 🆕 Очищаем ID из UserDefaults
                UserDefaults.standard.removeObject(forKey: "lastActiveCampaignID")
        // Сохраняем финальное состояние
        savePartyState()
        
        // Сбрасываем активную кампанию
        campaignManager.clearActiveCampaign()
        currentCampaignID = nil
        
        // Останавливаем мультиплеер
        session?.disconnect()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        
        // Очищаем состояние партии
        partyMembers = []
        restVotingManager.activeRestVote = nil
        restVotingManager.myVoteSent = nil
        restVotingManager.activeRestEffect = nil
        
        connectionState = .disconnected
        disconnectReason = nil
        lastError = nil
        
        log("🏁 Сессия кампании завершена")
    }


    /// Проверяет, может ли персонаж подключиться к текущей кампании
    /// (не закреплён ли он за другой кампанией)
    func canCharacterJoin(characterID: UUID) -> Bool {
        guard let campaignID = currentCampaignID else {
            return true // Нет активной кампании — можно подключиться
        }
        
        // Проверяем, не закреплён ли персонаж за ДРУГОЙ кампанией
        let conflictingCampaign = campaignManager.isCharacterAssignedToOtherCampaign(
            characterID: characterID,
            excludingCampaignID: campaignID
        )
        
        if let conflict = conflictingCampaign {
            log("⚠️ Персонаж уже закреплён за кампанией '\(conflict.name)'")
            return false
        }
        
        return true
    }
    
    /// Возвращает текущую активную кампанию (если есть)
    var activeCampaign: Campaign? {
        return campaignManager.activeCampaign
    }
}
