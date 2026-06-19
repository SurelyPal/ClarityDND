//
//  FieldType.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import Foundation

/// Типы полей для динамической системы
/// Определяет, как рендерить и валидировать значение поля
enum FieldType: String, Codable, CaseIterable, Identifiable {
    case integer      // Целое число (Stepper)
    case text         // Текст (TextField)
    case boolean      // Да/Нет (Toggle)
    case enumType     // Выбор из списка (Picker)
    case dice         // Кости (DiceRoller)
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .integer: return "Число"
        case .text: return "Текст"
        case .boolean: return "Да/Нет"
        case .enumType: return "Выбор из списка"
        case .dice: return "Кости"
        }
    }
    
    var icon: String {
        switch self {
        case .integer: return "number"
        case .text: return "text.alignleft"
        case .boolean: return "checkmark.circle"
        case .enumType: return "list.bullet"
        case .dice: return "dice"
        }
    }
}
