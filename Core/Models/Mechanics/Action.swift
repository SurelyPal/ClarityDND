//
//  Action.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import Foundation
import SwiftData

/// Модель одного действия в механике
@Model
class Action {
    /// Уникальный идентификатор действия
    @Attribute(.unique) var id: UUID
    
    /// Ссылка на механику, к которой принадлежит действие
    var mechanic: Mechanic?
    
    /// Порядок выполнения действия в списке
    var order: Int
    
    /// Тип действия (что именно делать)
    var type: ActionType
    
    /// Параметры действия в формате JSON
    /// Структура зависит от типа действия
    var parameters: Data
    
    init(
        id: UUID = UUID(),
        mechanic: Mechanic? = nil,
        order: Int = 0,
        type: ActionType,
        parameters: Data = Data()
    ) {
        self.id = id
        self.mechanic = mechanic
        self.order = order
        self.type = type
        self.parameters = parameters
    }
}

/// Структуры параметров для разных типов действий
struct SetFieldParameters: Codable {
    var fieldKey: String        // Ключ поля (например, "stress")
    var value: Int              // Значение для установки
}

struct IncrementFieldParameters: Codable {
    var fieldKey: String        // Ключ поля
    var amount: Int             // На сколько увеличить
}

struct DecrementFieldParameters: Codable {
    var fieldKey: String        // Ключ поля
    var amount: Int             // На сколько уменьшить
}

struct RollDiceParameters: Codable {
    var diceCount: Int          // Количество кубиков
    var diceSides: Int          // Количество граней (d6, d20 и т.д.)
    var modifier: Int           // Модификатор к броску
}

struct ShowMessageParameters: Codable {
    var message: String         // Текст сообщения
}