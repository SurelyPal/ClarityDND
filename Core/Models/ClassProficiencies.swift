//
//  ClassProficiencies.swift
//  Clarity
//
//  📁 Путь: Core/Models/
//  Единый источник proficient-навыков для всех классов.
//  Используется и в UI (SkillsTabView), и в мультиплеере (PartyManager).
//

import Foundation

enum ClassProficiencies {
    
    /// Набор proficient-навыков для каждого класса (D&D 5e упрощённо)
    /// В будущем сюда добавятся бонусы от предысторий (background)
    static let byClass: [CharacterClass: Set<String>] = [
        .fighter:   ["Атлетика", "Запугивание"],
        .rogue:     ["Скрытность", "Акробатика", "Обман", "Восприятие"],
        .cleric:    ["Религия", "Медицина", "Убеждение"],
        .ranger:    ["Выживание", "Восприятие", "Уход за животными"],
        .barbarian: ["Атлетика", "Запугивание", "Природа"],
        .mystic:    ["Магия", "Анализ", "Восприятие", "Религия"],
        .bard:      ["Убеждение", "Обман", "Акробатика"],
    ]
    
    /// Возвращает proficient навыки для конкретного класса
    static func forClass(_ characterClass: CharacterClass) -> Set<String> {
        byClass[characterClass] ?? []
    }
    
    /// Проверяет, владеет ли персонаж конкретным навыком
    static func isProficient(_ skill: String, for characterClass: CharacterClass) -> Bool {
        forClass(characterClass).contains(skill)
    }
}
