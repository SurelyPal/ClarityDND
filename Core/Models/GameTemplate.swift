//
//  GameTemplate.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import Foundation
import SwiftData

/// Шаблон игровой системы (D&D 5e, Pathfinder, кастомный)
/// Определяет набор полей и механик для кампании
@Model
final class GameTemplate {
    // MARK: - Уникальный идентификатор
    @Attribute(.unique) var id: UUID
    
    // MARK: - Идентификация
    var name: String              // "D&D 5e", "Pathfinder", "Моя система"
    var templateDescription: String       // Описание шаблона
    var isBuiltIn: Bool           // Встроенный (нельзя удалить) или пользовательский
    var createdAt: Date
        
    // MARK: - Коллекции
    @Relationship(deleteRule: .cascade) var fieldDefinitions: [FieldDefinition] = []
    @Relationship(deleteRule: .cascade, inverse: \Mechanic.gameTemplate)
    var mechanics: [Mechanic] = []
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        templateDescription: String = "",
        isBuiltIn: Bool = false,
        fieldDefinitions: [FieldDefinition] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.templateDescription = templateDescription
        self.isBuiltIn = isBuiltIn
        self.fieldDefinitions = fieldDefinitions
        self.createdAt = createdAt
    }
    
    // MARK: - Вспомогательные методы
    
    /// Получает определение поля по ключу
    func getFieldDefinition(forKey key: String) -> FieldDefinition? {
        return fieldDefinitions.first { $0.key == key }
    }
    
    /// Создаёт значение поля для персонажа с дефолтным значением
    func createFieldValue(for characterID: UUID, fieldDefinition: FieldDefinition) -> FieldValue {
        let fieldValue = FieldValue(
            characterID: characterID,
            fieldKey: fieldDefinition.key
        )
        
        // Устанавливаем значение по умолчанию в зависимости от типа
        switch fieldDefinition.fieldType {
        case .integer:
            let defaultValue = Int(fieldDefinition.defaultValue) ?? 0
            fieldValue.setIntValue(defaultValue)
            
        case .text:
            fieldValue.setStringValue(fieldDefinition.defaultValue)
            
        case .boolean:
            let defaultValue = Bool(fieldDefinition.defaultValue) ?? false
            fieldValue.setBoolValue(defaultValue)
            
        case .enumType, .dice:
            // Для сложных типов используем JSON
            fieldValue.jsonValue = fieldDefinition.defaultValue
        }
        
        return fieldValue
    }
    
    /// Инициализирует все значения полей для нового персонажа
    func initializeFieldValues(for characterID: UUID, context: ModelContext) {
        for fieldDef in fieldDefinitions {
            let fieldValue = createFieldValue(for: characterID, fieldDefinition: fieldDef)
            context.insert(fieldValue)
        }
    }
}
