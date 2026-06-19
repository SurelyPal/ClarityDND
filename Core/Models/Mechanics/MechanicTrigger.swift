//
//  MechanicTrigger.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import Foundation

/// Перечисление событий, которые могут запускать механику
enum MechanicTrigger: String, CaseIterable, Codable, Identifiable {
    case manual = "manual"              // Запуск вручную
    case onDiceRoll = "onDiceRoll"      // При броске кубика
    case onShortRest = "onShortRest"    // При коротком отдыхе
    case onLongRest = "onLongRest"      // При долгом отдыхе
    case onLevelUp = "onLevelUp"        // При повышении уровня
    case onCombatStart = "onCombatStart" // При начале боя
    
    var id: String { rawValue }
    
    /// Человекочитаемое название для UI
    var displayName: String {
        switch self {
        case .manual:
            return "Вручную"
        case .onDiceRoll:
            return "При броске кубика"
        case .onShortRest:
            return "При коротком отдыхе"
        case .onLongRest:
            return "При долгом отдыхе"
        case .onLevelUp:
            return "При повышении уровня"
        case .onCombatStart:
            return "При начале боя"
        }
    }
    
    /// Описание триггера
    var description: String {
        switch self {
        case .manual:
            return "Механика запускается только по нажатию кнопки"
        case .onDiceRoll:
            return "Автоматически срабатывает после любого броска кубика"
        case .onShortRest:
            return "Срабатывает при использовании короткого отдыха"
        case .onLongRest:
            return "Срабатывает при использовании долгого отдыха"
        case .onLevelUp:
            return "Срабатывает при повышении уровня персонажа"
        case .onCombatStart:
            return "Срабатывает при начале боевого столкновения"
        }
    }
    
    /// Иконка для UI
    var iconName: String {
        switch self {
        case .manual:
            return "hand.tap"
        case .onDiceRoll:
            return "dice"
        case .onShortRest:
            return "clock"
        case .onLongRest:
            return "bed.double"
        case .onLevelUp:
            return "arrow.up.circle"
        case .onCombatStart:
            return "shield.lefthalf.filled"
        }
    }
}