//
//  EquipmentSlot.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import Foundation

enum EquipmentSlot: String, CaseIterable, Codable {
    case none = "Без слота"
    case mainHand = "Основная рука"
    case offHand = "Вторая рука"
    case head = "Шлем"
    case chest = "Нагрудник"
    case hands = "Перчатки"
    case legs = "Штаны"
    case feet = "Обувь"
    case ring1 = "Кольцо 1"
    case ring2 = "Кольцо 2"
    case amulet = "Амулет"
    case ammo = "Боеприпасы"
    case potion = "Зелье"
    case consumable = "Расходник"
    case misc = "Прочее"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .none: return "square.dashed"
        case .mainHand: return "hand.raised.fill"
        case .offHand: return "shield.fill"
        case .head: return "crown.fill"
        case .chest: return "tshirt.fill"
        case .hands: return "hand.thumbsup.fill"
        case .legs: return "figure.stand"
        case .feet: return "shoe.fill"
        case .ring1, .ring2: return "circle.fill"
        case .amulet: return "sparkles"
        case .ammo: return "arrow.up.forward"
        case .potion: return "drop.fill"
        case .consumable: return "fork.knife"
        case .misc: return "bag.fill"
        }
    }
    
    /// Можно ли экипировать предмет в этот слот
    var isEquippable: Bool {
        switch self {
        case .mainHand, .offHand, .head, .chest, .hands,
             .legs, .feet, .ring1, .ring2, .amulet:
            return true
        default:
            return false
        }
    }
}
