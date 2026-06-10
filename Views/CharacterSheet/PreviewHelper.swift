//
//  PreviewHelper.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//

import Foundation
import SwiftData

/// Хелпер для создания тестовых данных в Xcode Previews
/// Вынесен в отдельный файл, чтобы не конфликтовать с ViewBuilder
enum PreviewHelper {
    
    /// Создаёт in-memory ModelContainer для превью
    static func makeContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: DNDCharacter.self, configurations: config)
    }
    
    /// Плут 5 уровня с полным HP
    static func makeRogue() -> DNDCharacter {
        let c = DNDCharacter()
        c.name = "Артемис Энтрери"
        c.race = .human
        c.characterClass = .rogue
        c.level = 5
        c.hitPoints = 38
        c.currentHP = 38
        c.alignment = .chaoticNeutral
        c.background = "Преступник"
        c.stress = 2
        c.rerollPoints = 3
        
        c.stats.strength = 12
        c.stats.dexterity = 18
        c.stats.constitution = 14
        c.stats.intelligence = 10
        c.stats.wisdom = 13
        c.stats.charisma = 15
        
        return c
    }
    
    /// Воин 8 уровня с низким HP (красный индикатор)
    static func makeFighter() -> DNDCharacter {
        let c = DNDCharacter()
        c.name = "Грок Железнокулачный"
        c.race = .human
        c.characterClass = .fighter
        c.level = 8
        c.hitPoints = 76
        c.currentHP = 12  // 💀 Критически низкое HP
        c.alignment = .lawfulNeutral
        c.background = "Солдат"
        c.stress = 5
        c.rerollPoints = 1
        
        c.stats.strength = 18
        c.stats.dexterity = 14
        c.stats.constitution = 16
        c.stats.intelligence = 10
        c.stats.wisdom = 12
        c.stats.charisma = 8
        
        return c
    }
    
    /// Бард 6 уровня с инструментом
    static func makeBard() -> DNDCharacter {
        let c = DNDCharacter()
        c.name = "Лирэль Серебряный Голос"
        c.race = .illicit
        c.characterClass = .bard
        c.level = 6
        c.hitPoints = 42
        c.currentHP = 35
        c.alignment = .chaoticGood
        c.background = "Артист"
        c.instrument = "Лютня"
        c.stress = 1
        c.rerollPoints = 2
        
        c.stats.strength = 10
        c.stats.dexterity = 14
        c.stats.constitution = 12
        c.stats.intelligence = 13
        c.stats.wisdom = 11
        c.stats.charisma = 18
        
        return c
    }
    
    /// Мистик 10 уровня с таро
    static func makeMystic() -> DNDCharacter {
        let c = DNDCharacter()
        c.name = "Вираний Оракул"
        c.race = .illicit
        c.characterClass = .mystic
        c.level = 10
        c.hitPoints = 62
        c.currentHP = 48
        c.alignment = .trueNeutral
        c.background = "Мудрец"
        c.stress = 4
        c.rerollPoints = 2
        
        c.stats.strength = 8
        c.stats.dexterity = 12
        c.stats.constitution = 13
        c.stats.intelligence = 16
        c.stats.wisdom = 18
        c.stats.charisma = 15
        
        return c
    }
    
    /// Следопыт максимального уровня (20)
    static func makeRanger() -> DNDCharacter {
        let c = DNDCharacter()
        c.name = "Элрин из Сумрачного Леса"
        c.race = .human
        c.characterClass = .ranger
        c.level = 20
        c.hitPoints = 178
        c.currentHP = 178
        c.alignment = .neutralGood
        c.background = "Отшельник"
        c.stress = 0
        c.rerollPoints = 5
        
        c.stats.strength = 14
        c.stats.dexterity = 20
        c.stats.constitution = 16
        c.stats.intelligence = 12
        c.stats.wisdom = 18
        c.stats.charisma = 10
        
        return c
    }
}
