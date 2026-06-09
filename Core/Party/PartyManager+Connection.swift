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

    // ✅ 1. Изменение состояния подключения (ОБЯЗАТЕЛЕН)
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
            case .notConnected:
                self.handlePeerDisconnected(peerID: peerID, session: session)
            @unknown default:
                break
            }
        }
    }

    // ✅ 2. Получение данных (ОБЯЗАТЕЛЕН — ИМЕННО ЕГО Я ПРОПУСТИЛ!)
    nonisolated func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        Task { @MainActor in
            self.receiveMessage(data, from: peerID)
        }
    }

    // ✅ 3. Получение stream (ОБЯЗАТЕЛЕН, но мы не используем)
    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // Clarity не использует streams — оставляем пустым
    }

    // ✅ 4. Начало получения ресурса (файла) (ОБЯЗАТЕЛЕН)
    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // Clarity не передаёт файлы — оставляем пустым
    }

    // ✅ 5. Завершение получения ресурса (ОБЯЗАТЕЛЕН)
    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {
        // Clarity не передаёт файлы — оставляем пустым
    }

    // ✅ 6. Сертификат безопасности (ОПЦИОНАЛЕН, но рекомендуется)
    nonisolated func session(
        _ session: MCSession,
        didReceiveCertificate certificate: [Any]?,
        fromPeer peerID: MCPeerID,
        certificateHandler: @escaping (Bool) -> Void
    ) {
        // Принимаем все подключения (в D&D-партии все свои)
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
            self.log("📥 Приглашение от \(peerID.displayName)")
            invitationHandler(true, self.session)
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
        Task { @MainActor in
            // Читаем правила ДМ из discoveryInfo
            if let rulesString = info?["gameRules"],
               let rulesData = rulesString.data(using: .utf8),
               let rules = try? JSONDecoder().decode(GameRules.self, from: rulesData) {
                self.gameRules = rules
                self.saveGameRules(rules)
                self.log("📜 Получены правила от ДМ")
            }

            self.log("👀 Найдена комната: \(roomCode) от \(peerID.displayName)")
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
        Task { @MainActor in
            let errorMessage = "Не удалось начать поиск партии: \(error.localizedDescription)"
            self.log("⚠️ \(errorMessage)")
            self.lastError = errorMessage
            self.connectionState = .disconnected
        }
    }
}

// MARK: - Private Connection Handlers

private extension PartyManager {
    func handlePeerConnected(peerID: MCPeerID, session: MCSession) {
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

        if self.role == .dungeonMaster {
            self.broadcastPartyList()
        }

        if self.role == .player, let char = self.selectedCharacter {
            self.sendJoinMessage(for: char)
        }
    }

    func handlePeerDisconnected(peerID: MCPeerID, session: MCSession) {
        self.log("❌ Отключено: \(peerID.displayName)")

        let reason = self.determineDisconnectReason(peer: peerID)
        self.disconnectReason = reason
        self.lastError = reason

        if self.role == .dungeonMaster {
            handleDMPeerDisconnected(peerID: peerID, session: session)
        } else {
            handlePlayerPeerDisconnected(peerID: peerID, session: session, reason: reason)
        }
    }

    func handleDMPeerDisconnected(peerID: MCPeerID, session: MCSession) {
        if let idx = self.partyMembers.firstIndex(where: { $0.peerID.displayName == peerID.displayName }) {
            let disconnectedMemberID = self.partyMembers[idx].id
            var updatedMember = self.partyMembers[idx]
            updatedMember.isConnected = false
            updatedMember.lastSeen = Date()

            var newMembers = self.partyMembers
            newMembers[idx] = updatedMember
            self.partyMembers = newMembers

            self.log("🔴 Игрок \(peerID.displayName) отключился (теперь офлайн)")
            self.savePartyState()

            // Если отключился инициатор голосования — отменяем его
            if let voteSession = restVotingManager.activeRestVote,
               voteSession.initiatorID == disconnectedMemberID {
                self.log("❌ Инициатор голосования отключился — отменяем")
                let failMsg = PartyMessage.restVoteFailed(reason: "Инициатор отключился")
                self.send(failMsg)
                restVotingManager.cancelSession()
            }
        }

        self.broadcastPartyList()

        let count = session.connectedPeers.count
        if count > 0 {
            self.connectionState = .connected(peersCount: count)
        } else {
            self.connectionState = .hosting(code: self.roomCode)
        }
    }

    func handlePlayerPeerDisconnected(peerID: MCPeerID, session: MCSession, reason: String) {
        let count = session.connectedPeers.count

        if count == 0 {
            self.log("🔴 Связь с ДМом потеряна — полная очистка")
            self.connectionState = .disconnected

            self.partyMembers = []
            restVotingManager.resetAll()

            self.disconnectReason = reason
            self.lastError = nil
        } else {
            self.connectionState = .connected(peersCount: count)
        }
    }

    func determineDisconnectReason(peer: MCPeerID) -> String {
        if role == .dungeonMaster {
            return "Игрок \(peer.displayName) отключился от партии"
        } else {
            return "Мастер отключил вас или соединение потеряно"
        }
    }
}
