//
//  PartyMessage.swift
//  Clarity
//

import Foundation

// 🆕 Тип отдыха
enum RestType: String, Codable, CaseIterable, Sendable {
    case short = "short"
    case long = "long"
    
    var displayName: String {
        switch self {
        case .short: return "Короткий отдых"
        case .long: return "Долгий отдых"
        }
    }
    
    var icon: String {
        switch self {
        case .short: return "moon.zzz.fill"
        case .long: return "bed.double.fill"
        }
    }
}

enum PartyMessage: Codable, Sendable {
    
    case playerJoined(
        characterID: UUID,
        name: String,
        race: String,
        characterClass: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        avatarData: Data?,
        campaignID: UUID?,
        hasOtherActiveCharacterInCampaign: Bool 
    )
    case characterUpdated(characterID: UUID, currentHP: Int, maxHP: Int, level: Int, stress: Int, rerollPoints: Int, timestamp: Date)
    case characterDetails(
        characterID: UUID,
        stats: AbilityScores,
        rerollPoints: Int,
        inventory: [InventoryItem],
        skillProficiencies: [String],
        background: String,
        alignment: DNDAlignment
    )
    case characterDeleted(characterID: UUID)  // ✅ НОВОЕ: Сообщение об удалении персонажа
    case playerLeft(characterID: UUID)
    case partyList(members: [PartyMember])
    // ✅ НОВОЕ: ДМ отправляет игроку команду привязать персонажа к кампании
    case campaignBinding(campaignID: UUID)
    // 🆕 ГОЛОСОВАНИЕ ЗА ОТДЫХ
    case restVoteRequest(
        initiatorID: UUID,
        initiatorName: String,
        restType: RestType,
        eligibleVoterIDs: Set<UUID>,
        initialVotes: [UUID: Bool]
    )
    case requestRestVote(
        restType: RestType,
        requesterID: UUID,
        requesterName: String
    )
    // 🆕 НОВОЕ: Игрок запрашивает у ДМ-а начать голосование
    case restVoteResponse(
        voterID: UUID,
        voterName: String,
        accepted: Bool
    )
    // ✅ Heartbeat сообщения
    case heartbeatRequest(timestamp: Date)
    case heartbeatResponse(timestamp: Date)
    
    // ✅ Явное уведомление об остановке хоста (для graceful shutdown)
    case hostStopped
    case restStarted(restType: RestType)
    case restVoteFailed(reason: String)
    case restsReset
    
    case ping
    case pong
    case requestCharacterSync
    // 🆕 ДМ запрашивает полную синхронизацию от игрока
    case requestSync
    case connectionRejected(reason: String)
}
