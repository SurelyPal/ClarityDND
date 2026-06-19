//
//  FieldValue.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


//
//  FieldValue.swift
//  Clarity
//
//  Created for Phase 1: Dynamic Fields
//

import Foundation
import SwiftData

/// Значение динамического поля у конкретного персонажа
/// Хранит фактические данные для каждого поля
@Model
final class FieldValue {
    // MARK: - Уникальный идентификатор
    @Attribute(.unique) var id: UUID
    
    // MARK: - Привязка к персонажу и полю
    var characterID: UUID         // ID персонажа
    var fieldKey: String          // Ключ поля (ссылка на FieldDefinition.key)
    
    // MARK: - Значения (хранится только одно, в зависимости от типа)
    var intValue: Int?
    var stringValue: String?
    var boolValue: Bool?
    var jsonValue: String?        // Для сложных типов (массивы, объекты)
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        characterID: UUID,
        fieldKey: String,
        intValue: Int? = nil,
        stringValue: String? = nil,
        boolValue: Bool? = nil,
        jsonValue: String? = nil
    ) {
        self.id = id
        self.characterID = characterID
        self.fieldKey = fieldKey
        self.intValue = intValue
        self.stringValue = stringValue
        self.boolValue = boolValue
        self.jsonValue = jsonValue
    }
    
    // MARK: - Вспомогательные методы
    
    /// Получает значение как Int (с fallback на 0)
    func getIntValue(defaultValue: Int = 0) -> Int {
        return intValue ?? defaultValue
    }
    
    /// Устанавливает Int значение
    func setIntValue(_ value: Int) {
        self.intValue = value
        self.stringValue = nil
        self.boolValue = nil
        self.jsonValue = nil
    }
    
    /// Получает значение как String (с fallback на пустую строку)
    func getStringValue(defaultValue: String = "") -> String {
        return stringValue ?? defaultValue
    }
    
    /// Устанавливает String значение
    func setStringValue(_ value: String) {
        self.stringValue = value
        self.intValue = nil
        self.boolValue = nil
        self.jsonValue = nil
    }
    
    /// Получает значение как Bool (с fallback на false)
    func getBoolValue(defaultValue: Bool = false) -> Bool {
        return boolValue ?? defaultValue
    }
    
    /// Устанавливает Bool значение
    func setBoolValue(_ value: Bool) {
        self.boolValue = value
        self.intValue = nil
        self.stringValue = nil
        self.jsonValue = nil
    }
}