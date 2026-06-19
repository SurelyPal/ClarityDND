//
//  Player.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import Foundation
import SwiftData

/// Локальный профиль игрока (тот, кто использует приложение)
/// Хранит список кампаний, где он ГМ, и где он игрок
@Model
final class Player {
    
    // MARK: - Уникальный идентификатор
    @Attribute(.unique) var id: UUID
    
    // MARK: - Идентификация
    var playerName: String // Имя локального игрока
    
    // MARK: - Связи
    @Relationship(deleteRule: .cascade) var createdCampaigns: [Campaign] = [] // Кампании, где я ГМ
    @Relationship var joinedCampaigns: [Campaign] = [] // Кампании, где я игрок
    @Relationship(deleteRule: .cascade) var archivedCharacters: [ArchivedCharacter] = [] // Архив персонажей
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        playerName: String = "Локальный игрок",
        createdCampaigns: [Campaign] = [],
        joinedCampaigns: [Campaign] = [],
        archivedCharacters: [ArchivedCharacter] = []
    ) {
        self.id = id
        self.playerName = playerName
        self.createdCampaigns = createdCampaigns
        self.joinedCampaigns = joinedCampaigns
        self.archivedCharacters = archivedCharacters
    }
}

// MARK: - Helper методы
extension Player {
    /// Проверяет, является ли этот игрок владельцем (ГМ-ом) данной кампании
    func isOwner(of campaign: Campaign) -> Bool {
        return campaign.owner?.id == self.id
    }
    
    /// Проверяет, участвует ли этот игрок в данной кампании (как игрок, не ГМ)
    func isParticipant(in campaign: Campaign) -> Bool {
        return joinedCampaigns.contains { $0.id == campaign.id }
    }
    
    /// Возвращает все кампании, где этот игрок участвует (ГМ + игрок)
    var allCampaigns: [Campaign] {
        return createdCampaigns + joinedCampaigns
    }
}
