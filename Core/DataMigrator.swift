//
//  DataMigrator.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


//
//  DataMigrator.swift
//  Clarity
//
//  Created for Phase 1: Dynamic Fields Migration
//

import Foundation
import SwiftData

/// Мигратор для переноса старых захардкоженных полей (stress, money, rerollPoints) в новую систему
@MainActor
final class DataMigrator {
    
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// Проверяет, нужна ли миграция
    func needsMigration() -> Bool {
        // Проверяем, есть ли хотя бы один персонаж без fieldValues
        let descriptor = FetchDescriptor<DNDCharacter>(
            predicate: #Predicate { $0.fieldValues.isEmpty }
        )
        
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }
    
    /// Выполняет миграцию всех персонажей
    func migrateAllCharacters() throws {
        print("🔄 Начинаю миграцию старых данных в новую систему полей...")
        
        // 1. Получаем или создаём шаблон D&D 5e
        let template = try getOrCreateDefaultTemplate()
        
        // 2. Загружаем всех персонажей
        let descriptor = FetchDescriptor<DNDCharacter>(
            predicate: #Predicate { !$0.isDeleted }
        )
        let characters = try context.fetch(descriptor)
        
        // 3. Для каждого персонажа создаём значения полей
        for character in characters {
            try migrateCharacter(character, template: template)
        }
        
        try context.save()
        print("✅ Миграция завершена: перенесено \(characters.count) персонажей")
    }
    
    /// Создаёт стандартный шаблон D&D 5e если его нет
    /// Вызывается при каждом запуске приложения
    func ensureDefaultTemplateExists() throws {
        // Проверяем, существует ли уже шаблон
        let descriptor = FetchDescriptor<GameTemplate>(
            predicate: #Predicate { $0.name == "D&D 5e" }
        )
        
        if let _ = try context.fetch(descriptor).first {
            print("✅ Шаблон D&D 5e уже существует")
            return
        }
        
        print("🆕 Создаём стандартный шаблон D&D 5e...")
        
        // Создаём стандартные поля D&D 5e
        let stressField = FieldDefinition(
            name: "Стресс",
            key: "stress",
            fieldType: .integer,
            defaultValue: "0",
            minValue: 0,
            displayColor: "#FF5733",
            showOnSheet: true,
            isEditableByPlayer: true
        )
        
        let moneyField = FieldDefinition(
            name: "Деньги (золото)",
            key: "money",
            fieldType: .integer,
            defaultValue: "0",
            minValue: 0,
            displayColor: "#FFD700",
            showOnSheet: true,
            isEditableByPlayer: true
        )
        
        let rerollField = FieldDefinition(
            name: "Очки переброса",
            key: "rerollPoints",
            fieldType: .integer,
            defaultValue: "0",
            minValue: 0,
            displayColor: "#4A90E2",
            showOnSheet: true,
            isEditableByPlayer: true
        )
        
        let template = GameTemplate(
            name: "D&D 5e",
            templateDescription: "Стандартная система Dungeons & Dragons 5th Edition",
            isBuiltIn: true
        )
        
        // Добавляем поля к шаблону
        template.fieldDefinitions = [stressField, moneyField, rerollField]
        
        // Сохраняем в базу данных
        context.insert(template)
        try context.save()
        
        print("✅ Шаблон D&D 5e создан с 3 полями")
    }
    
    /// Получает или создаёт стандартный шаблон D&D 5e
    private func getOrCreateDefaultTemplate() throws -> GameTemplate {
        let descriptor = FetchDescriptor<GameTemplate>(
            predicate: #Predicate { $0.name == "D&D 5e" }
        )
        
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        
        // Создаём стандартные поля D&D 5e
        let stressField = FieldDefinition(
            name: "Стресс",
            key: "stress",
            fieldType: .integer,
            defaultValue: "0",
            minValue: 0,
            displayColor: "#FF5733",
            showOnSheet: true,
            isEditableByPlayer: true
        )
        
        let moneyField = FieldDefinition(
            name: "Деньги (золото)",
            key: "money",
            fieldType: .integer,
            defaultValue: "0",
            minValue: 0,
            displayColor: "#FFD700",
            showOnSheet: true,
            isEditableByPlayer: true
        )
        
        let rerollField = FieldDefinition(
            name: "Очки переброса",
            key: "rerollPoints",
            fieldType: .integer,
            defaultValue: "0",
            minValue: 0,
            displayColor: "#4A90E2",
            showOnSheet: true,
            isEditableByPlayer: true
        )
        
        let template = GameTemplate(
            name: "D&D 5e",
            templateDescription: "Стандартная система Dungeons & Dragons 5th Edition",
            isBuiltIn: true,
            fieldDefinitions: [stressField, moneyField, rerollField]
        )
        
        context.insert(template)
        try context.save()
        
        return template
    }
    
    /// Мигрирует одного персонажа
    private func migrateCharacter(_ character: DNDCharacter, template: GameTemplate) throws {
        print("🔄 Миграция персонажа: \(character.name)")
        
        // Мигрируем Stress
        if let stressDef = template.getFieldDefinition(forKey: "stress") {
            let stressValue = template.createFieldValue(for: character.id, fieldDefinition: stressDef)
            stressValue.setIntValue(character.stress)
            context.insert(stressValue)
            character.fieldValues.append(stressValue)
        }
        
        // Мигрируем Money
        if let moneyDef = template.getFieldDefinition(forKey: "money") {
            let moneyValue = template.createFieldValue(for: character.id, fieldDefinition: moneyDef)
            moneyValue.setIntValue(character.money)
            context.insert(moneyValue)
            character.fieldValues.append(moneyValue)
        }
        
        // Мигрируем Reroll Points
        if let rerollDef = template.getFieldDefinition(forKey: "rerollPoints") {
            let rerollValue = template.createFieldValue(for: character.id, fieldDefinition: rerollDef)
            rerollValue.setIntValue(character.rerollPoints)
            context.insert(rerollValue)
            character.fieldValues.append(rerollValue)
        }
        
        print("✅ Персонаж \(character.name) мигрирован")
    }
}
