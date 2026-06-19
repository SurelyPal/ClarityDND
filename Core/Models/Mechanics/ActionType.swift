//
//  ActionType.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import Foundation

/// Перечисление всех возможных действий в механике
enum ActionType: String, CaseIterable, Codable, Identifiable {
    // Действия с полями
    case setField = "setField"           // Установить значение поля
    case incrementField = "incrementField" // Увеличить значение поля
    case decrementField = "decrementField" // Уменьшить значение поля
    
    // Действия с кубиками
    case rollDice = "rollDice"           // Бросить кубик
    
    // Информационные действия
    case showMessage = "showMessage"     // Показать сообщение
    
    var id: String { rawValue }
    
    /// Человекочитаемое название для UI
    var displayName: String {
        switch self {
        case .setField:
            return "Установить значение поля"
        case .incrementField:
            return "Увеличить значение поля"
        case .decrementField:
            return "Уменьшить значение поля"
        case .rollDice:
            return "Бросить кубик"
        case .showMessage:
            return "Показать сообщение"
        }
    }
    
    /// Описание действия для UI
    var description: String {
        switch self {
        case .setField:
            return "Устанавливает конкретное значение для выбранного поля"
        case .incrementField:
            return "Увеличивает значение поля на указанное число"
        case .decrementField:
            return "Уменьшает значение поля на указанное число"
        case .rollDice:
            return "Бросает кубик (результат можно использовать далее)"
        case .showMessage:
            return "Показывает текстовое сообщение пользователю"
        }
    }
    
    /// Иконка для UI
    var iconName: String {
        switch self {
        case .setField:
            return "equal.square"
        case .incrementField:
            return "plus.square"
        case .decrementField:
            return "minus.square"
        case .rollDice:
            return "dice"
        case .showMessage:
            return "text.bubble"
        }
    }
}
