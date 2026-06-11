//
//  DNDCharacter.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import Foundation
import SwiftData
import SwiftUI
/// Главная модель персонажа.
/// Хранится в SwiftData, используется как reference-type.
@Model
final class DNDCharacter {
    // MARK: - Идентификация
    @Attribute(.unique) var id: UUID
    var name: String
    var race: Race
    var characterClass: CharacterClass
    var level: Int
    var stats: AbilityScores
    var background: String
    var campaignID: UUID?
    // MARK: - HP
    // 🔑 ВАЖНО: hitPoints = МАКСИМАЛЬНОЕ здоровье
    //           currentHP = ТЕКУЩЕЕ здоровье (уменьшается при уроне)
    var hitPoints: Int
    var currentHP: Int
    var alignment: DNDAlignment
    var stress: Int
    var rerollPoints: Int
    var isDeleted: Bool = false 
    var instrument: String?
    
    // MARK: - Коллекции
    var inventory: [InventoryItem]
    var tarotCards: [TarotCard]
    var instrumentModStorage: [InstrumentModEntry]

    // 🆕 История изменений HP (последние 50 записей)
    var hpHistory: [HPChange] = []
    // MARK: - Бинарные данные (хранятся отдельно от SQLite)
    @Attribute(.externalStorage) var avatarData: Data?
    
    // MARK: - Initializer
    init() {
        self.id = UUID()
        self.name = ""
        self.race = .human
        self.characterClass = .fighter
        self.level = 1
        self.stats = AbilityScores()
        self.background = ""
        self.hitPoints = Constants.Character.defaultHP
        self.isDeleted = false
        self.currentHP = Constants.Character.defaultHP  // 🔑 НОВОЕ: текущее = максимуму при создании
        self.alignment = .trueNeutral
        self.stress = 0
        self.rerollPoints = 0
        self.instrument = nil
        self.inventory = []
        self.tarotCards = []
        self.instrumentModStorage = []
        self.avatarData = nil
        self.hpHistory = [] // 🆕 Инициализация истории
    }
}

// MARK: - Вспомогательный тип для хранения модификаций

extension DNDCharacter {
    struct InstrumentModEntry: Codable {
        let instrument: InstrumentType
        let slot: InstrumentModificationSlot
        var modification: InstrumentModification
    }
}

// MARK: - Модификации инструментов (только для барда)

extension DNDCharacter {
    /// Удобный словарь для UI: инструмент → (слот → модификация).
    var instrumentModifications: [InstrumentType: [InstrumentModificationSlot: InstrumentModification]] {
        var dict: [InstrumentType: [InstrumentModificationSlot: InstrumentModification]] = [:]
        for entry in instrumentModStorage {
            var slots = dict[entry.instrument] ?? [:]
            slots[entry.slot] = entry.modification
            dict[entry.instrument] = slots
        }
        return dict
    }
    
    func setModification(
        _ modification: InstrumentModification,
        for instrument: InstrumentType,
        slot: InstrumentModificationSlot
    ) {
        instrumentModStorage.removeAll { $0.instrument == instrument && $0.slot == slot }
        instrumentModStorage.append(
            InstrumentModEntry(instrument: instrument, slot: slot, modification: modification)
        )
    }
    
    func removeModification(
        for instrument: InstrumentType,
        slot: InstrumentModificationSlot
    ) {
        instrumentModStorage.removeAll { $0.instrument == instrument && $0.slot == slot }
    }
}

// MARK: - Detection экипированного инструмента

extension DNDCharacter {
    var hasEquippedInstrument: Bool {
        guard characterClass == .bard else { return false }
        return inventory.contains { item in
            item.isEquipped && InstrumentType.from(name: item.name) != nil
        }
    }
    
    var equippedInstrumentType: InstrumentType? {
        guard characterClass == .bard else { return nil }
        return inventory
            .first { $0.isEquipped }
            .flatMap { InstrumentType.from(name: $0.name) }
    }
}

// MARK: - Computed Properties: Общие

extension DNDCharacter {
    var isMaxLevel: Bool {
        level >= Constants.Character.maxLevel
    }
    
    var displayName: String {
        name.isEmpty ? Constants.Character.unnamedName : name
    }
}

// MARK: - Combat Stats

extension DNDCharacter {
    var armorClass: Int {
        10 + stats.modifier(for: \.dexterity)
    }
    
    var initiative: Int {
        stats.modifier(for: \.dexterity)
    }
    
    var proficiencyBonus: Int {
        2 + (level - 1) / 4
    }
    
    var passivePerception: Int {
        10 + stats.modifier(for: \.wisdom)
    }
    
    var speed: Int {
        race.baseSpeedMeters
    }
}

// MARK: - Methods

extension DNDCharacter {
    /// Повышает уровень персонажа.
    /// 🔑 ВАЖНО: увеличивает и МАКСИМУМ (hitPoints), и ТЕКУЩЕЕ (currentHP)
    func levelUp() {
        level += 1
        hitPoints += 5
        currentHP = hitPoints  // ✅ HP восстанавливается до максимума при level up
        
        print("🎯 levelUp(): level=\(level), hitPoints=\(hitPoints), currentHP=\(currentHP)")
    }}

// MARK: - Codable (для миграции с UserDefaults)

extension DNDCharacter: Codable {
    // 🔑 Добавлен currentHP
    private enum CodingKeys: String, CodingKey {
        case id, name, race, characterClass, level, stats, background
        case hitPoints, currentHP, alignment, stress, rerollPoints, instrument
        case inventory, tarotCards, instrumentModStorage, avatarData
        case hpHistory
    }
    
    convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id             = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name           = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.race           = try container.decodeIfPresent(Race.self, forKey: .race) ?? .human
        self.characterClass = try container.decodeIfPresent(CharacterClass.self, forKey: .characterClass) ?? .fighter
        self.level          = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        self.stats          = try container.decodeIfPresent(AbilityScores.self, forKey: .stats) ?? AbilityScores()
        self.background     = try container.decodeIfPresent(String.self, forKey: .background) ?? ""
        self.hitPoints      = try container.decodeIfPresent(Int.self, forKey: .hitPoints) ?? Constants.Character.defaultHP
        
        // 🔑 НОВОЕ: currentHP с fallback на hitPoints (для старых данных)
        self.currentHP      = try container.decodeIfPresent(Int.self, forKey: .currentHP) ?? self.hitPoints
        
        self.alignment      = try container.decodeIfPresent(DNDAlignment.self, forKey: .alignment) ?? .trueNeutral
        self.stress         = try container.decodeIfPresent(Int.self, forKey: .stress) ?? 0
        self.rerollPoints   = try container.decodeIfPresent(Int.self, forKey: .rerollPoints) ?? 0
        self.instrument     = try container.decodeIfPresent(String.self, forKey: .instrument)
        
        self.inventory      = try container.decodeIfPresent([InventoryItem].self, forKey: .inventory) ?? []
        self.tarotCards     = try container.decodeIfPresent([TarotCard].self, forKey: .tarotCards) ?? []
        self.avatarData     = try container.decodeIfPresent(Data.self, forKey: .avatarData)
        self.instrumentModStorage = try container.decodeIfPresent([InstrumentModEntry].self, forKey: .instrumentModStorage) ?? []
        self.hpHistory = try container.decodeIfPresent([HPChange].self, forKey: .hpHistory) ?? [] // 🆕
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(race, forKey: .race)
        try container.encode(characterClass, forKey: .characterClass)
        try container.encode(level, forKey: .level)
        try container.encode(stats, forKey: .stats)
        try container.encode(background, forKey: .background)
        try container.encode(hitPoints, forKey: .hitPoints)
        try container.encode(currentHP, forKey: .currentHP)  // 🔑 НОВОЕ
        try container.encode(alignment, forKey: .alignment)
        try container.encode(stress, forKey: .stress)
        try container.encode(rerollPoints, forKey: .rerollPoints)
        try container.encodeIfPresent(instrument, forKey: .instrument)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(tarotCards, forKey: .tarotCards)
        try container.encode(instrumentModStorage, forKey: .instrumentModStorage)
        try container.encodeIfPresent(avatarData, forKey: .avatarData)
        try container.encode(hpHistory, forKey: .hpHistory) // 🆕
    }
    
}
// MARK: - UI helpers
extension DNDCharacter {
    /// Цвет индикатора HP в зависимости от его процента
    /// >50% → золото, >25% → оранжевый, ≤25% → красный
    var hpColor: Color {
        guard hitPoints > 0 else { return Color.dsRed }
        let fraction = Double(currentHP) / Double(hitPoints)
        if fraction > 0.5 { return Color.dsGold }
        if fraction > 0.25 { return .orange }
        return Color.dsRed
    }
}
    // MARK: - HP History Management

    extension DNDCharacter {
        /// Записывает изменение HP в историю
        /// - Parameters:
        ///   - oldHP: Старое значение HP
        ///   - newHP: Новое значение HP
        ///   - reason: Причина изменения (опционально)
        func recordHPChange(oldHP: Int, newHP: Int, reason: String = "") {
            let amount = newHP - oldHP
            
            // Не записываем если ничего не изменилось
            guard amount != 0 else { return }
            
            let change = HPChange(
                amount: amount,
                reason: reason,
                oldHP: oldHP,
                newHP: newHP
            )
            
            hpHistory.insert(change, at: 0) // Новые записи в начало
            
            // Ограничиваем историю последними 50 записями
            if hpHistory.count > 50 {
                hpHistory = Array(hpHistory.prefix(50))
            }
        }
        
        /// Очищает историю изменений HP
        func clearHPHistory() {
            hpHistory.removeAll()
        }
    }



