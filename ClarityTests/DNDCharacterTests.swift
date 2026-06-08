//
//  DNDCharacterTests.swift
//  ClarityTests
//
//  Created by KEBAB on 05.06.2026.
//
import XCTest
@testable import Clarity

@MainActor
final class DNDCharacterTests: XCTestCase {
    
    // MARK: - Proficiency Bonus (формула D&D 5e: 2 + (level - 1) / 4)
    
    func testProficiencyBonus_Level1to4_Returns2() {
        let char = DNDCharacter()
        for level in 1...4 {
            char.level = level
            XCTAssertEqual(char.proficiencyBonus, 2,
                           "На уровне \(level) бонус должен быть +2")
        }
    }
    
    func testProficiencyBonus_Level5to8_Returns3() {
        let char = DNDCharacter()
        for level in 5...8 {
            char.level = level
            XCTAssertEqual(char.proficiencyBonus, 3,
                           "На уровне \(level) бонус должен быть +3")
        }
    }
    
    func testProficiencyBonus_Level9to10_Returns4() {
        let char = DNDCharacter()
        for level in 9...10 {
            char.level = level
            XCTAssertEqual(char.proficiencyBonus, 4,
                           "На уровне \(level) бонус должен быть +4")
        }
    }
    
    // MARK: - isMaxLevel
    
    func testIsMaxLevel_AtMaxLevel_ReturnsTrue() {
        let char = DNDCharacter()
        char.level = Constants.Character.maxLevel
        XCTAssertTrue(char.isMaxLevel)
    }
    
    func testIsMaxLevel_OneBelowMax_ReturnsFalse() {
        let char = DNDCharacter()
        char.level = Constants.Character.maxLevel - 1
        XCTAssertFalse(char.isMaxLevel)
    }
    
    func testIsMaxLevel_AtLevel1_ReturnsFalse() {
        let char = DNDCharacter()
        char.level = 1
        XCTAssertFalse(char.isMaxLevel)
    }
    
    // MARK: - displayName
    
    func testDisplayName_WithName_ReturnsName() {
        let char = DNDCharacter()
        char.name = "Гэндальф"
        XCTAssertEqual(char.displayName, "Гэндальф")
    }
    
    func testDisplayName_Empty_ReturnsUnnamed() {
        let char = DNDCharacter()
        char.name = ""
        XCTAssertEqual(char.displayName, Constants.Character.unnamedName)
    }
    
    func testDisplayName_WhitespaceOnly_ReturnsName() {
        let char = DNDCharacter()
        char.name = "   "
        // Пустые пробелы технически не равны "", поэтому вернётся само значение
        XCTAssertEqual(char.displayName, "   ")
    }
    
    // MARK: - Combat Stats
    
    func testArmorClass_WithDex10_Returns10() {
        let char = DNDCharacter()
        char.stats.dexterity = 10  // модификатор 0
        XCTAssertEqual(char.armorClass, 10)
    }
    
    func testArmorClass_WithDex16_Returns13() {
        let char = DNDCharacter()
        char.stats.dexterity = 16  // модификатор +3
        XCTAssertEqual(char.armorClass, 13)
    }
    
    func testArmorClass_WithDex8_Returns9() {
        let char = DNDCharacter()
        char.stats.dexterity = 8  // модификатор -1
        XCTAssertEqual(char.armorClass, 9)
    }
    
    func testInitiative_EqualsDexModifier() {
        let char = DNDCharacter()
        char.stats.dexterity = 14  // модификатор +2
        XCTAssertEqual(char.initiative, 2)
        
        char.stats.dexterity = 8   // модификатор -1
        XCTAssertEqual(char.initiative, -1)
    }
    
    func testPassivePerception_WithWis12_Returns11() {
        let char = DNDCharacter()
        char.stats.wisdom = 12  // модификатор +1
        XCTAssertEqual(char.passivePerception, 11)  // 10 + 1
    }
    
    func testPassivePerception_WithWis8_Returns9() {
        let char = DNDCharacter()
        char.stats.wisdom = 8  // модификатор -1
        XCTAssertEqual(char.passivePerception, 9)  // 10 - 1
    }
    
    // MARK: - Speed (зависит от расы)
    
    func testSpeed_Human_Returns9() {
        let char = DNDCharacter()
        char.race = .human
        XCTAssertEqual(char.speed, 9)
    }
    
    func testSpeed_Illicit_Returns9() {
        let char = DNDCharacter()
        char.race = .illicit
        XCTAssertEqual(char.speed, 9)
    }
    
    // MARK: - Ability Modifier (формула с floor — D&D 5e)
    
    func testAbilityModifier_StandardValues() {
        XCTAssertEqual(Constants.Stat.modifier(for: 10), 0)
        XCTAssertEqual(Constants.Stat.modifier(for: 11), 0)
        XCTAssertEqual(Constants.Stat.modifier(for: 12), 1)
        XCTAssertEqual(Constants.Stat.modifier(for: 13), 1)
        XCTAssertEqual(Constants.Stat.modifier(for: 14), 2)
        XCTAssertEqual(Constants.Stat.modifier(for: 15), 2)
        XCTAssertEqual(Constants.Stat.modifier(for: 20), 5)
    }
    
    func testAbilityModifier_NegativeValues_FloorBehavior() {
        // Критический тест: 9 должен давать -1, а не 0
        // Это баг, который был исправлен через floor()
        XCTAssertEqual(Constants.Stat.modifier(for: 9), -1,
                       "Характеристика 9 должна давать модификатор -1 (floor от -0.5)")
        XCTAssertEqual(Constants.Stat.modifier(for: 8), -1)
        XCTAssertEqual(Constants.Stat.modifier(for: 7), -2)
        XCTAssertEqual(Constants.Stat.modifier(for: 6), -2)
        XCTAssertEqual(Constants.Stat.modifier(for: 3), -4)
        XCTAssertEqual(Constants.Stat.modifier(for: 1), -5)
    }
    
    // MARK: - Formatted Modifier
    
    func testFormattedModifier_Positive_HasPlusSign() {
        XCTAssertEqual(Constants.Stat.formattedModifier(2), "+2")
        XCTAssertEqual(Constants.Stat.formattedModifier(0), "+0")
        XCTAssertEqual(Constants.Stat.formattedModifier(5), "+5")
    }
    
    func testFormattedModifier_Negative_HasMinusSign() {
        XCTAssertEqual(Constants.Stat.formattedModifier(-1), "-1")
        XCTAssertEqual(Constants.Stat.formattedModifier(-3), "-3")
    }
    
    // MARK: - Level Up
    
    func testLevelUp_IncreasesLevelAndHP() {
        let char = DNDCharacter()
        let initialHP = char.hitPoints
        let initialLevel = char.level
        
        char.levelUp()
        
        XCTAssertEqual(char.level, initialLevel + 1)
        XCTAssertEqual(char.hitPoints, initialHP + Constants.Character.hpPerLevel)
    }
    
    func testLevelUp_WithCustomHPBonus() {
        let char = DNDCharacter()
        let initialHP = char.hitPoints
        
        char.levelUp(hpBonus: 10)
        
        XCTAssertEqual(char.hitPoints, initialHP + 10)
    }
    
    func testLevelUp_MultipleTimes_AccumulatesHP() {
        let char = DNDCharacter()
        let initialHP = char.hitPoints
        
        char.levelUp()
        char.levelUp()
        char.levelUp()
        
        XCTAssertEqual(char.level, 4)
        XCTAssertEqual(char.hitPoints, initialHP + 3 * Constants.Character.hpPerLevel)
    }
    
    // MARK: - Instrument Detection
    
    func testHasEquippedInstrument_NonBard_ReturnsFalse() {
        let char = DNDCharacter()
        char.characterClass = .fighter
        
        // Даже если есть экипированный инструмент — воин не бард
        var flute = InventoryItem()
        flute.name = "Флейта"
        flute.slot = .misc
        flute.isEquipped = true
        char.inventory.append(flute)
        
        XCTAssertFalse(char.hasEquippedInstrument)
    }
    
    func testHasEquippedInstrument_BardWithEquippedFlute_ReturnsTrue() {
        let char = DNDCharacter()
        char.characterClass = .bard
        
        var flute = InventoryItem()
        flute.name = "Флейта"
        flute.isEquipped = true
        char.inventory.append(flute)
        
        XCTAssertTrue(char.hasEquippedInstrument)
    }
    
    func testHasEquippedInstrument_BardWithUnequippedFlute_ReturnsFalse() {
        let char = DNDCharacter()
        char.characterClass = .bard
        
        var flute = InventoryItem()
        flute.name = "Флейта"
        flute.isEquipped = false  // в рюкзаке, не в руках
        char.inventory.append(flute)
        
        XCTAssertFalse(char.hasEquippedInstrument)
    }
    
    func testHasEquippedInstrument_BardWithEmptyInventory_ReturnsFalse() {
        let char = DNDCharacter()
        char.characterClass = .bard
        char.inventory = []
        
        XCTAssertFalse(char.hasEquippedInstrument)
    }
    
    func testEquippedInstrumentType_DetectsLute() {
        let char = DNDCharacter()
        char.characterClass = .bard
        
        var lute = InventoryItem()
        lute.name = "Лютня"
        lute.isEquipped = true
        char.inventory.append(lute)
        
        XCTAssertEqual(char.equippedInstrumentType, .lute)
    }
    
    func testEquippedInstrumentType_DetectsDrum() {
        let char = DNDCharacter()
        char.characterClass = .bard
        
        var drum = InventoryItem()
        drum.name = "Барабан"
        drum.isEquipped = true
        char.inventory.append(drum)
        
        XCTAssertEqual(char.equippedInstrumentType, .drum)
    }
    
    func testEquippedInstrumentType_NonBard_ReturnsNil() {
        let char = DNDCharacter()
        char.characterClass = .mystic
        
        var flute = InventoryItem()
        flute.name = "Флейта"
        flute.isEquipped = true
        char.inventory.append(flute)
        
        XCTAssertNil(char.equippedInstrumentType)
    }
    
    // MARK: - Instrument Modifications
    
    func testSetModification_SingleSlot() {
        let char = DNDCharacter()
        let mod = InstrumentModification(
            name: "Эхо гор",
            description: "Test",
            effect: "Test",
            slot: .resonance,
            rarity: .rare
        )
        
        char.setModification(mod, for: .lute, slot: .resonance)
        
        XCTAssertEqual(char.instrumentModifications[.lute]?[.resonance]?.name, "Эхо гор")
        XCTAssertEqual(char.instrumentModStorage.count, 1)
    }
    
    func testSetModification_ReplacesExisting() {
        let char = DNDCharacter()
        let mod1 = InstrumentModification(
            name: "Первая",
            description: "", effect: "", slot: .resonance, rarity: .common
        )
        let mod2 = InstrumentModification(
            name: "Вторая",
            description: "", effect: "", slot: .resonance, rarity: .rare
        )
        
        char.setModification(mod1, for: .lute, slot: .resonance)
        char.setModification(mod2, for: .lute, slot: .resonance)
        
        // Должна остаться только вторая
        XCTAssertEqual(char.instrumentModifications[.lute]?[.resonance]?.name, "Вторая")
        XCTAssertEqual(char.instrumentModStorage.count, 1,
                       "Не должно быть дублей для одного инструмента+слота")
    }
    
    func testSetModification_DifferentInstruments_Independent() {
        let char = DNDCharacter()
        let modLute = InstrumentModification(
            name: "Мод для лютни",
            description: "", effect: "", slot: .resonance, rarity: .rare
        )
        let modDrum = InstrumentModification(
            name: "Мод для барабана",
            description: "", effect: "", slot: .resonance, rarity: .rare
        )
        
        char.setModification(modLute, for: .lute, slot: .resonance)
        char.setModification(modDrum, for: .drum, slot: .resonance)
        
        XCTAssertEqual(char.instrumentModifications[.lute]?[.resonance]?.name, "Мод для лютни")
        XCTAssertEqual(char.instrumentModifications[.drum]?[.resonance]?.name, "Мод для барабана")
        XCTAssertEqual(char.instrumentModStorage.count, 2)
    }
    
    func testSetModification_DifferentSlots_Independent() {
        let char = DNDCharacter()
        let resonance = InstrumentModification(
            name: "Резонанс",
            description: "", effect: "", slot: .resonance, rarity: .rare
        )
        let enchantment = InstrumentModification(
            name: "Чары",
            description: "", effect: "", slot: .enchantment, rarity: .epic
        )
        
        char.setModification(resonance, for: .lute, slot: .resonance)
        char.setModification(enchantment, for: .lute, slot: .enchantment)
        
        XCTAssertEqual(char.instrumentModifications[.lute]?[.resonance]?.name, "Резонанс")
        XCTAssertEqual(char.instrumentModifications[.lute]?[.enchantment]?.name, "Чары")
        XCTAssertEqual(char.instrumentModStorage.count, 2)
    }
    
    func testRemoveModification_RemovesEntry() {
        let char = DNDCharacter()
        let mod = InstrumentModification(
            name: "Тест",
            description: "", effect: "", slot: .resonance, rarity: .rare
        )
        
        char.setModification(mod, for: .lute, slot: .resonance)
        XCTAssertNotNil(char.instrumentModifications[.lute]?[.resonance])
        
        char.removeModification(for: .lute, slot: .resonance)
        
        XCTAssertNil(char.instrumentModifications[.lute]?[.resonance])
        XCTAssertTrue(char.instrumentModStorage.isEmpty)
    }
    
    func testRemoveModification_DoesNotAffectOtherSlots() {
        let char = DNDCharacter()
        let resonance = InstrumentModification(
            name: "Резонанс",
            description: "", effect: "", slot: .resonance, rarity: .rare
        )
        let enchantment = InstrumentModification(
            name: "Чары",
            description: "", effect: "", slot: .enchantment, rarity: .epic
        )
        
        char.setModification(resonance, for: .lute, slot: .resonance)
        char.setModification(enchantment, for: .lute, slot: .enchantment)
        
        char.removeModification(for: .lute, slot: .resonance)
        
        XCTAssertNil(char.instrumentModifications[.lute]?[.resonance])
        XCTAssertEqual(char.instrumentModifications[.lute]?[.enchantment]?.name, "Чары")
        XCTAssertEqual(char.instrumentModStorage.count, 1)
    }
    
    func testInstrumentModifications_EmptyStorage_ReturnsEmptyDict() {
        let char = DNDCharacter()
        XCTAssertTrue(char.instrumentModifications.isEmpty)
    }
    
    // MARK: - InstrumentType.from(name:)
    
    func testInstrumentTypeFrom_RecognizesExactNames() {
        XCTAssertEqual(InstrumentType.from(name: "Лютня"), .lute)
        XCTAssertEqual(InstrumentType.from(name: "Флейта"), .flute)
        XCTAssertEqual(InstrumentType.from(name: "Барабан"), .drum)
    }
    
    func testInstrumentTypeFrom_ReturnsNilForUnknown() {
        XCTAssertNil(InstrumentType.from(name: "Меч"))
        XCTAssertNil(InstrumentType.from(name: ""))
    }
    
    // MARK: - Initial State
    
    func testInitialCharacter_HasDefaultValues() {
        let char = DNDCharacter()
        
        XCTAssertEqual(char.name, "")
        XCTAssertEqual(char.race, .human)
        XCTAssertEqual(char.characterClass, .fighter)
        XCTAssertEqual(char.level, 1)
        XCTAssertEqual(char.hitPoints, Constants.Character.defaultHP)
        XCTAssertEqual(char.stress, 0)
        XCTAssertEqual(char.rerollPoints, 0)
        XCTAssertTrue(char.inventory.isEmpty)
        XCTAssertTrue(char.tarotCards.isEmpty)
        XCTAssertTrue(char.instrumentModStorage.isEmpty)
        XCTAssertNil(char.avatarData)
        XCTAssertNil(char.instrument)
    }
}
