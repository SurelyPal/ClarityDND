//
//  RuleEngine.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import Foundation
import SwiftData
import OSLog

/// Движок для выполнения механик
/// Принимает механику и персонажа, выполняет все действия по порядку
@Observable
class RuleEngine {
    private let logger = Logger(subsystem: "ClarityDND", category: "RuleEngine")
    
    /// Контекст SwiftData для сохранения изменений
    private var modelContext: ModelContext
    
    /// Последний результат броска кубика (можно использовать в следующих действиях)
    private var lastDiceRoll: Int = 0
    
    /// Сообщения для показа пользователю
    private(set) var messages: [String] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Выполнить механику для конкретного персонажа
    /// - Parameters:
    ///   - mechanic: Механика для выполнения
    ///   - character: Персонаж, к которому применяется механика
    func execute(mechanic: Mechanic, character: DNDCharacter) {
        guard mechanic.isEnabled else {
            logger.info("Механика '\(mechanic.name)' отключена, пропускаем")
            return
        }
        
        logger.info("Начинаем выполнение механики '\(mechanic.name)' для персонажа \(character.name)")
        
        // Сбрасываем состояние перед выполнением
        messages = []
        lastDiceRoll = 0
        
        // Получаем отсортированные действия
        let sortedActions = mechanic.sortedActions
        
        // Выполняем каждое действие по порядку
        for action in sortedActions {
            execute(action: action, character: character)
        }
        
        // Сохраняем изменения в базе данных
        do {
            try modelContext.save()
            logger.info("Механика '\(mechanic.name)' выполнена успешно")
        } catch {
            logger.error("Ошибка при сохранении: \(error.localizedDescription)")
        }
    }
    
    /// Выполнить одно действие
    private func execute(action: Action, character: DNDCharacter) {
        logger.debug("Выполняем действие типа \(action.type.rawValue)")
        
        switch action.type {
        case .setField:
            executeSetField(action: action, character: character)
        case .incrementField:
            executeIncrementField(action: action, character: character)
        case .decrementField:
            executeDecrementField(action: action, character: character)
        case .rollDice:
            executeRollDice(action: action)
        case .showMessage:
            executeShowMessage(action: action)
        }
    }
    
    // MARK: - Реализация конкретных действий
    
    /// Установить значение поля
    private func executeSetField(action: Action, character: DNDCharacter) {
        guard let params = try? JSONDecoder().decode(SetFieldParameters.self, from: action.parameters) else {
            logger.error("Не удалось декодировать параметры для setField")
            return
        }
        
        // Ищем значение поля у персонажа
        if let fieldValue = character.fieldValues.first(where: { $0.fieldKey == params.fieldKey }) {
            fieldValue.intValue = params.value
            logger.info("Установлено значение \(params.value) для поля \(params.fieldKey)")
        } else {
            // Если поле не найдено, создаём новое
            let newFieldValue = FieldValue(
                characterID: character.id,
                fieldKey: params.fieldKey,
                intValue: params.value
            )
            character.fieldValues.append(newFieldValue)
            modelContext.insert(newFieldValue)
            logger.info("Создано новое поле \(params.fieldKey) со значением \(params.value)")
        }
    }
    
    /// Увеличить значение поля
    private func executeIncrementField(action: Action, character: DNDCharacter) {
        guard let params = try? JSONDecoder().decode(IncrementFieldParameters.self, from: action.parameters) else {
            logger.error("Не удалось декодировать параметры для incrementField")
            return
        }
        
        if let fieldValue = character.fieldValues.first(where: { $0.fieldKey == params.fieldKey }) {
            let currentValue = fieldValue.intValue ?? 0
            fieldValue.intValue = currentValue + params.amount
            logger.info("Увеличено значение поля \(params.fieldKey): \(currentValue) → \(currentValue + params.amount)")
        } else {
            let newFieldValue = FieldValue(
                characterID: character.id,
                fieldKey: params.fieldKey,
                intValue: params.amount
            )
            character.fieldValues.append(newFieldValue)
            modelContext.insert(newFieldValue)
            logger.info("Создано новое поле \(params.fieldKey) со значением \(params.amount)")
        }
    }
    
    /// Уменьшить значение поля
    private func executeDecrementField(action: Action, character: DNDCharacter) {
        guard let params = try? JSONDecoder().decode(DecrementFieldParameters.self, from: action.parameters) else {
            logger.error("Не удалось декодировать параметры для decrementField")
            return
        }
        
        if let fieldValue = character.fieldValues.first(where: { $0.fieldKey == params.fieldKey }) {
            let currentValue = fieldValue.intValue ?? 0
            fieldValue.intValue = currentValue - params.amount
            logger.info("Уменьшено значение поля \(params.fieldKey): \(currentValue) → \(currentValue - params.amount)")
        } else {
            let newFieldValue = FieldValue(
                characterID: character.id,
                fieldKey: params.fieldKey,
                intValue: -params.amount
            )
            character.fieldValues.append(newFieldValue)
            modelContext.insert(newFieldValue)
            logger.info("Создано новое поле \(params.fieldKey) со значением \(-params.amount)")
        }
    }
    
    /// Бросить кубик
    private func executeRollDice(action: Action) {
        guard let params = try? JSONDecoder().decode(RollDiceParameters.self, from: action.parameters) else {
            logger.error("Не удалось декодировать параметры для rollDice")
            return
        }
        
        var total = 0
        for _ in 0..<params.diceCount {
            let roll = Int.random(in: 1...params.diceSides)
            total += roll
        }
        total += params.modifier
        
        lastDiceRoll = total
        logger.info("Брошен кубик: \(params.diceCount)d\(params.diceSides)+\(params.modifier) = \(total)")
    }
    
    /// Показать сообщение
    private func executeShowMessage(action: Action) {
        guard let params = try? JSONDecoder().decode(ShowMessageParameters.self, from: action.parameters) else {
            logger.error("Не удалось декодировать параметры для showMessage")
            return
        }
        
        messages.append(params.message)
        logger.info("Добавлено сообщение: \(params.message)")
    }
}
