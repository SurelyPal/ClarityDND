//
//  Constants.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import Foundation
import SwiftUI

enum Constants {
    
    enum Character {
        static let maxLevel = 10
        static let defaultHP = 10
        static let hpPerLevel = 5
        static let maxRerollPoints = 2
        static let unnamedName = "Безымянный"
    }
    
    enum Stat {
        static let minValue = 8
        static let maxValue = 15
        static let pointBuyTotal = 27
        
        /// Таблица стоимости очков Point Buy (D&D 5e)
        static let pointBuyCost: [Int: Int] = [
            8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9
        ]
        
        /// Стоимость повышения характеристики с `value` до `value + 1`
        static func costToIncrease(from value: Int) -> Int {
            let current = pointBuyCost[value] ?? 0
            let next = pointBuyCost[value + 1] ?? 0
            return next - current
        }
        
        /// Вычисляет модификатор характеристики (D&D формула)
        static func modifier(for value: Int) -> Int {
            Int(floor(Double(value - 10) / 2.0))
        }
        
        /// Форматирует модификатор со знаком: "+2" или "-1"
        static func formattedModifier(_ value: Int) -> String {
            value >= 0 ? "+\(value)" : "\(value)"
        }
    }
    
    enum Stress {
        static let levels = [-3, -2, -1, 0, 1, 2, 3]
        
        static func label(for level: Int) -> String {
            switch level {
            case -3: return "Паника"
            case -2: return "Страх"
            case -1: return "Тревога"
            case 0:  return "Спокойствие"
            case 1:  return "Уверенность"
            case 2:  return "Берсерк"
            case 3:  return "Дзен"
            default: return ""
            }
        }
    }
    
    enum UI {
        static let avatarMaxSize: CGFloat = 256
        static let avatarCompression: CGFloat = 0.7
        static let animationSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let debouncedSaveInterval: TimeInterval = 0.5
    }
    
    enum Storage {
        static let charactersKey = "dnd_characters"
    }
}
