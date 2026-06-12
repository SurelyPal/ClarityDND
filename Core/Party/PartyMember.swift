//
//  PartyMember.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import Foundation
import MultipeerConnectivity
import SwiftUI

/// Представление игрока в партии (видит только ДМ)
struct PartyMember: Identifiable, Equatable, Codable, Hashable, Sendable {
    let id: UUID
    /// 🔑MCPeerID нельзя сохранить в JSON, поэтому сохраняем только displayName
    /// При восстановлении создаём новый peerID с тем же именем
    private var peerDisplayName: String
    /// Публичный доступ к peerID (вычисляемое свойство)
    var peerID: MCPeerID {
        MCPeerID(displayName: peerDisplayName)
    }
    var campaignID: UUID? = nil
    var name: String
    var race: Race
    var characterClass: String
    var level: Int
    var currentHP: Int
    var maxHP: Int
    var stress: Int
    var avatarData: Data?
    var lastSeen: Date = Date()
    var isConnected: Bool = true
    var isCharacterDeleted: Bool = false
    // 🔑 НОВЫЕ поля для детального профиля
    var stats: AbilityScores?
    var rerollPoints: Int?
    var inventory: [InventoryItem]?
    var skillProficiencies: [String]?
    var background: String?
    var alignment: DNDAlignment?
    var money: Int?  // ✅ НОВОЕ: Деньги для синхронизации
    var hpFraction: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }
    
    /// Есть ли у нас полные данные персонажа
    var hasFullProfile: Bool {
        stats != nil
    }
    
    static func == (lhs: PartyMember, rhs: PartyMember) -> Bool {
        lhs.id == rhs.id
        && lhs.currentHP == rhs.currentHP
        && lhs.maxHP == rhs.maxHP
        && lhs.level == rhs.level
        && lhs.stress == rhs.stress
        && lhs.rerollPoints == rhs.rerollPoints
        && lhs.stats == rhs.stats
        && lhs.inventory == rhs.inventory
        && lhs.skillProficiencies == rhs.skillProficiencies
        && lhs.background == rhs.background
        && lhs.alignment == rhs.alignment
        && lhs.isConnected == rhs.isConnected
        && lhs.avatarData == rhs.avatarData // 🆕 ДОБАВИЛИ
        && lhs.lastSeen == rhs.lastSeen         // 🆕 ДОБАВИЛИ
        && lhs.money == rhs.money  // ✅ ДОБАВИТЬ
    }
    // MARK: - Инициализатор
    
    /// Создаёт PartyMember из MCPeerID
    init(
        id: UUID,
        peerID: MCPeerID,
        name: String,
        race: Race,
        characterClass: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        stress: Int,
        avatarData: Data?,
        isConnected: Bool = true,
        isCharacterDeleted: Bool = false
    ) {
        self.id = id
        self.peerDisplayName = peerID.displayName  // 🔑 Сохраняем имя
        self.isCharacterDeleted = isCharacterDeleted 
        self.name = name
        self.race = race
        self.characterClass = characterClass
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.stress = stress
        self.avatarData = avatarData
        self.isConnected = isConnected
    }
}
// MARK: - UI helpers
extension PartyMember {
    var hpColor: Color {
        let fraction = hpFraction
        if fraction > 0.5 { return Color.dsGold }
        if fraction > 0.25 { return .orange }
        return Color.dsRed
    }
}

