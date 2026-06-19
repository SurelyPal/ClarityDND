//
//  Mechanic.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import Foundation
import SwiftData

/// Модель механики (визуального скрипта)
@Model
class Mechanic {
    /// Уникальный идентификатор механики
    @Attribute(.unique) var id: UUID
    
    /// Название механики (например, "Восстановление стресса")
    var name: String
    
    /// Событие, при котором срабатывает механика
    var trigger: MechanicTrigger
    
    /// Активна ли механика (можно отключить без удаления)
    var isEnabled: Bool
    
    /// Ссылка на игровой шаблон
    var gameTemplate: GameTemplate?
    
    /// Список действий механики (автоматически сортируется по order)
    @Relationship(deleteRule: .cascade, inverse: \Action.mechanic)
    var actions: [Action] = []
    
    init(
        id: UUID = UUID(),
        name: String = "Новая механика",
        trigger: MechanicTrigger = .manual,
        isEnabled: Bool = true,
        gameTemplate: GameTemplate? = nil
    ) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.isEnabled = isEnabled
        self.gameTemplate = gameTemplate
    }
    
    /// Получить отсортированный список действий по порядку
    var sortedActions: [Action] {
        actions.sorted { $0.order < $1.order }
    }
    
    /// Добавить новое действие в конец списка
    func addAction(_ action: Action) {
        action.order = actions.count
        actions.append(action)
    }
    
    /// Удалить действие по ID
    func removeAction(id: UUID) {
        actions.removeAll { $0.id == id }
        // Переиндексируем оставшиеся действия
        for (index, action) in sortedActions.enumerated() {
            action.order = index
        }
    }
    
    /// Переместить действие на новую позицию
    func moveAction(from oldIndex: Int, to newIndex: Int) {
        guard oldIndex != newIndex,
              oldIndex >= 0, oldIndex < actions.count,
              newIndex >= 0, newIndex < actions.count else { return }
        
        let sorted = sortedActions
        var newActions = sorted
        let action = newActions.remove(at: oldIndex)
        newActions.insert(action, at: newIndex)
        
        // Обновляем порядок
        for (index, act) in newActions.enumerated() {
            act.order = index
        }
    }
}