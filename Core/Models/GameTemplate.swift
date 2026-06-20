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
     
    // 🆕 НОВОЕ: Доступные опции для создания персонажей
        var availableRaces: [String] = [] // Массив rawValue рас
        var availableClasses: [String] = [] // Массив rawValue классов
    
    // MARK: - Коллекции
    @Relationship(deleteRule: .cascade) var fieldDefinitions: [FieldDefinition] = []
    @Relationship(deleteRule: .cascade, inverse: \Mechanic.gameTemplate)
    var mechanics: [Mechanic] = []

    // 🆕 ДОБАВЛЕНО: Обратная связь с кампаниями (один шаблон может использоваться в нескольких кампаниях)
    @Relationship(inverse: \Campaign.gameTemplate)
    var campaigns: [Campaign] = []
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        templateDescription: String = "",
        isBuiltIn: Bool = false,
        fieldDefinitions: [FieldDefinition] = [],
        createdAt: Date = Date(),
        availableRaces: [String] = [],
        availableClasses: [String] = []
    ) {
        self.id = id
        self.name = name
        self.templateDescription = templateDescription
        self.isBuiltIn = isBuiltIn
        self.fieldDefinitions = fieldDefinitions
        self.createdAt = createdAt
        self.availableRaces = availableRaces
        self.availableClasses = availableClasses
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
    func isRaceAvailable(_ race: Race) -> Bool {
            // Если список пустой — все расы доступны
            if availableRaces.isEmpty { return true }
            return availableRaces.contains(race.rawValue)
        }
        
        /// Проверяет, доступен ли класс в этом шаблоне
    func isClassAvailable(_ characterClass: CharacterClass) -> Bool {
            // Если список пустой — все классы доступны
            if availableClasses.isEmpty { return true }
            return availableClasses.contains(characterClass.rawValue)
        }
}
// MARK: - Заглушки для экспорта/импорта (TODO на будущее)
extension GameTemplate {
    /// Экспортирует механику в Data для передачи в другие кампании
    /// TODO: Реализовать позже через Codable
    func exportMechanic(_ mechanic: Mechanic) -> Data? {
        // Пока возвращаем nil — это заглушка
        print("⚠️ exportMechanic() ещё не реализован для \(mechanic.name)")
        return nil
    }
    
    /// Экспортирует определение поля в Data
    /// TODO: Реализовать позже
    func exportFieldDefinition(_ field: FieldDefinition) -> Data? {
        print("⚠️ exportFieldDefinition() ещё не реализован для \(field.key)")
        return nil
    }
    
    /// Импортирует механику из Data
    /// TODO: Реализовать позже
    func importMechanic(from data: Data) -> Mechanic? {
        print("⚠️ importMechanic() ещё не реализован")
        return nil
    }
    
    /// Импортирует определение поля из Data
    /// TODO: Реализовать позже
    func importFieldDefinition(from data: Data) -> FieldDefinition? {
        print("⚠️ importFieldDefinition() ещё не реализован")
        return nil
    }
}
