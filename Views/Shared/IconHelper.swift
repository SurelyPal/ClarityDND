//
//  IconHelper.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import Foundation

enum IconHelper {
    /// Возвращает SF Symbol для типа предмета
    static func iconForItem(_ item: InventoryItem) -> String {
        let slotName = String(describing: item.slot).lowercased()
        
        switch slotName {
        case "none":
            return "square.dashed"
        case let s where s.contains("weapon") || s.contains("sword"):
            return "sword"
        case let s where s.contains("armor"):
            return "shield.fill"
        case let s where s.contains("shield"):
            return "shield.lefthalf.filled"
        case let s where s.contains("head") || s.contains("helm"):
            return "crown.fill"
        case let s where s.contains("hand") || s.contains("glove"):
            return "hand.fill"
        case let s where s.contains("feet") || s.contains("boot"):
            return "figure.walk"
        case let s where s.contains("ring"):
            return "circle.fill"
        case let s where s.contains("amulet") || s.contains("neck"):
            return "star.circle.fill"
        case let s where s.contains("consumable") || s.contains("potion"):
            return "pills.fill"
        case let s where s.contains("scroll"):
            return "scroll.fill"
        case let s where s.contains("wand") || s.contains("staff"):
            return "wand.and.stars"
        default:
            return "bag.fill"
        }
    }
}