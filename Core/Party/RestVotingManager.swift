//
//  RestVotingManager.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import Foundation

/// Отдельный менеджер для системы голосования за отдых.
/// Отвечает ТОЛЬКО за: создание сессий, подсчёт голосов, применение эффектов.
@MainActor
@Observable
final class RestVotingManager {
    // MARK: - Published State
    var activeRestVote: RestVoteSession? = nil
    var myVoteSent: Bool? = nil
    var activeRestEffect: RestEffectEvent? = nil

    // MARK: - Nested Types

    struct RestVoteSession: Identifiable, Equatable {
        let id = UUID()
        let initiatorID: UUID
        let initiatorName: String
        let restType: RestType
        var votes: [UUID: Bool] = [:]
        var eligibleVoterIDs: Set<UUID> = []

        var totalVoters: Int { eligibleVoterIDs.count }
    }

    struct RestEffectEvent: Identifiable, Equatable {
        let id = UUID()
        let restType: RestType
        let initiatorName: String
        let timestamp: Date
    }

    enum VoteResult {
        case success(RestType, String)
        case failed
        case inProgress
    }

    // MARK: - Vote Lifecycle

    /// Создаёт новую сессию голосования
    func startSession(
        initiatorID: UUID,
        initiatorName: String,
        restType: RestType,
        eligibleVoterIDs: Set<UUID>
    ) {
        activeRestVote = RestVoteSession(
            initiatorID: initiatorID,
            initiatorName: initiatorName,
            restType: restType,
            votes: [initiatorID: true], // Инициатор голосует ЗА
            eligibleVoterIDs: eligibleVoterIDs
        )
        myVoteSent = true
    }

    /// Регистрирует голос в активной сессии
    /// - Returns: результат голосования, если сессия завершена
    func registerVote(voterID: UUID, accepted: Bool) -> VoteResult {
        guard var session = activeRestVote else { return .inProgress }

        session.votes[voterID] = accepted
        activeRestVote = session

        // Проверяем: все проголосовали?
        if session.votes.count >= session.totalVoters {
            let allAccepted = session.votes.values.allSatisfy { $0 }
            if allAccepted {
                let result: VoteResult = .success(session.restType, session.initiatorName)
                activeRestVote = nil
                return result
            } else {
                activeRestVote = nil
                return .failed
            }
        }

        return .inProgress
    }

    /// Отменяет активную сессию
    func cancelSession() {
        activeRestVote = nil
        myVoteSent = nil
    }

    /// Начинает эффект отдыха (анимация)
    func startEffect(restType: RestType, initiatorName: String) {
        activeRestEffect = RestEffectEvent(
            restType: restType,
            initiatorName: initiatorName,
            timestamp: Date()
        )
    }

    /// Сбрасывает эффект (после завершения анимации)
    func clearEffect() {
        activeRestEffect = nil
    }

    /// Отмечает локальный голос пользователя
    func markMyVote(_ accepted: Bool) {
        myVoteSent = accepted
    }

    /// Полный сброс состояния
    func resetAll() {
        activeRestVote = nil
        myVoteSent = nil
        activeRestEffect = nil
    }
}