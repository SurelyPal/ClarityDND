//
//  HPChange.swift
//  Clarity
//
//  Created by KEBAB on 08.06.2026.
//

import Foundation

/// Запись об изменении HP персонажа
struct HPChange: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let amount: Int // Положительное = лечение, отрицательное = урон
    let reason: String // "Goblin attack", "Healing potion", "Level up"
    let timestamp: Date
    let oldHP: Int
    let newHP: Int
    
    init(
        amount: Int,
        reason: String = "",
        oldHP: Int,
        newHP: Int
    ) {
        self.id = UUID()
        self.amount = amount
        self.reason = reason
        self.timestamp = Date()
        self.oldHP = oldHP
        self.newHP = newHP
    }
    
    /// Является ли это лечением (true) или уроном (false)
    var isHealing: Bool {
        amount > 0
    }
    
    /// Форматированное время для UI
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
