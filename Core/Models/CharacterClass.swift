//
//  CharacterClass.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import Foundation

enum CharacterClass: String, CaseIterable, Codable, Identifiable{
    case fighter = "Воин"
    case rogue = "Плут"
    case cleric = "Жрец"
    case ranger = "Следопыт"
    case barbarian = "Варвар"
    case mystic = "Мистик"
    case bard = "Бард"
    var id: String { self.rawValue }
    var hasTarotAccess: Bool {
            self == .mystic
        }
    /// Иконка класса
    /// Иконка класса (SF Symbol)
    var icon: String {
        switch self {
        case .fighter: return "shield.lefthalf.filled"   // ⚔️ Воин — бронированный щит
        case .rogue: return "eye.slash.fill"             // 🗡️ Плут — скрытность
        case .cleric: return "hands.sparkles.fill"       // ✝️ Жрец — благословение
        case .ranger: return "scope"                     // 🏹 Следопыт — прицел
        case .barbarian: return "flame.fill"             // 🪓 Варвар — ярость
        case .mystic: return "sparkles.fill"      // 🃏 Мистик — карты таро
        case .bard: return "music.note"                  // 🎵 Бард — музыка
        }
    }
    
    /// Описание класса для карточки создания
    var shortDescription: String {
        switch self {
        case .fighter: return "Мастер боевых искусств"
        case .rogue: return "Мастер теней"
        case .cleric: return "Служитель богов"
        case .ranger: return "Страж дикой природы"
        case .barbarian: return "Неистовый воин"
        case .mystic: return "Читатель судеб"
        case .bard: return "Мастер музыки и историй"
        }
    }
}

