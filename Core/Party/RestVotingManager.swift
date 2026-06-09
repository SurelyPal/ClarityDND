//
//  RestVotingManager.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//


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
    /// - Parameters:
    ///   - initiatorAutoVote: если true — инициатор автоматически голосует ЗА (для игроков).
    ///                        если false — инициатор не голосует (для ДМ, который только модератор)
    func startSession(
        initiatorID: UUID,
        initiatorName: String,
        restType: RestType,
        eligibleVoterIDs: Set<UUID>,
        initiatorAutoVote: Bool = true,
        initialVotes: [UUID: Bool] = [:]
    ) {
        var votes = initialVotes
        
        // Если initiatorAutoVote и инициатор в eligibleIDs — добавляем его голос
        if initiatorAutoVote, eligibleVoterIDs.contains(initiatorID), votes[initiatorID] == nil {
            votes[initiatorID] = true
            myVoteSent = true
        } else {
            // Проверяем: есть ли мой голос в initialVotes (для не-инициаторов)
            // myVoteSent остаётся nil — пользователь ещё не голосовал
            myVoteSent = nil
        }
        
        activeRestVote = RestVoteSession(
            initiatorID: initiatorID,
            initiatorName: initiatorName,
            restType: restType,
            votes: votes,
            eligibleVoterIDs: eligibleVoterIDs
        )
    }
    
    /// Регистрирует голос в активной сессии
    /// - Parameters:
    ///   - allowDuplicate: если true — разрешает повторную регистрацию (для форсирования завершения)
    func registerVote(voterID: UUID, accepted: Bool, allowDuplicate: Bool = false) -> VoteResult {
        guard var session = activeRestVote else { return .inProgress }
        
        // Проверка: имеет ли этот voter право голоса
        guard session.eligibleVoterIDs.contains(voterID) else {
            return .inProgress
        }
        
        // Защита от дубликатов (кроме форсированного случая)
        if !allowDuplicate, session.votes[voterID] != nil {
            return .inProgress
        }
        
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
    
    /// Проверяет, завершилось ли голосование (все проголосовали).
    /// Не регистрирует новый голос — только проверяет текущее состояние.
    func checkIfCompleted() -> VoteResult {
        guard let session = activeRestVote else { return .inProgress }
        
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
