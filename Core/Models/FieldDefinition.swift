//
//  FieldDefinition.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import Foundation
import SwiftData

/// Определение динамического поля (метаданные)
/// Описывает, какое поле есть у персонажа и как его отображать
@Model
final class FieldDefinition {
    // MARK: - Уникальный идентификатор
    @Attribute(.unique) var id: UUID
    
    // MARK: - Идентификация
    var name: String              // "Стресс", "Деньги", "Очки переброса"
    var key: String               // "stress", "money", "rerollPoints" (латиница, уникальный)
    
    // MARK: - Тип и настройки
    var fieldType: FieldType      // Тип поля (число, текст, булево и т.д.)
    var defaultValue: String      // "0" (JSON-encoded)
    
    // MARK: - Ограничения (только для integer)
    var minValue: Int?
    var maxValue: Int?
    
    // MARK: - Отображение
    var displayColor: String?     // HEX цвет (например, "#FF5733")
    var showOnSheet: Bool         // Показывать ли в листе персонажа
    var isEditableByPlayer: Bool  // Может ли игрок редактировать
    
    // MARK: - Связь с шаблоном
    var gameTemplate: GameTemplate?
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        key: String,
        fieldType: FieldType,
        defaultValue: String = "0",
        minValue: Int? = nil,
        maxValue: Int? = nil,
        displayColor: String? = nil,
        showOnSheet: Bool = true,
        isEditableByPlayer: Bool = true
    ) {
        self.id = id
        self.name = name
        self.key = key
        self.fieldType = fieldType
        self.defaultValue = defaultValue
        self.minValue = minValue
        self.maxValue = maxValue
        self.displayColor = displayColor
        self.showOnSheet = showOnSheet
        self.isEditableByPlayer = isEditableByPlayer
    }
}
