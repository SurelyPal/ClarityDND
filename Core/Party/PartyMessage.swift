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

enum PartyMessage: Codable {
    
    case playerJoined(
        characterID: UUID,
        name: String,
        race: String,
        characterClass: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        avatarData: Data?
    )
    case characterUpdated(
        characterID: UUID,
        currentHP: Int,
        maxHP: Int,
        level: Int,
        stress: Int,
        rerollPoints: Int
    )
    case characterDetails(
        characterID: UUID,
        stats: AbilityScores,
        rerollPoints: Int,
        inventory: [InventoryItem],
        skillProficiencies: [String],
        background: String,
        alignment: DNDAlignment
    )
    case playerLeft(characterID: UUID)
    case partyList(members: [PartyMember])
    
    // 🆕 ГОЛОСОВАНИЕ ЗА ОТДЫХ
    case restVoteRequest(
        initiatorID: UUID,
        initiatorName: String,
        restType: RestType,
        eligibleVoterIDs: Set<UUID>
    )
    case restVoteResponse(
        voterID: UUID,
        voterName: String,
        accepted: Bool
    )
    case restStarted(restType: RestType)
    case restVoteFailed(reason: String)
    case restsReset
    
    case ping
    case pong
    case requestCharacterSync
    // 🆕 ДМ запрашивает полную синхронизацию от игрока
    case requestSync
}
