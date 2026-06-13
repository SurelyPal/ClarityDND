//
//  AbilityScores.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import Foundation

struct AbilityScores: Codable, Equatable, Hashable, Sendable {
    var strength: Int = Constants.Stat.minValue
    var dexterity: Int = Constants.Stat.minValue
    var constitution: Int = Constants.Stat.minValue
    var intelligence: Int = Constants.Stat.minValue
    var wisdom: Int = Constants.Stat.minValue
    var charisma: Int = Constants.Stat.minValue

    /// Вычисляет модификатор для характеристики
    /// ✅ ИСПРАВЛЕНО: добавлены дженерик-параметры к KeyPath
    func modifier(for stat: KeyPath<AbilityScores, Int>) -> Int {
        Constants.Stat.modifier(for: self[keyPath: stat])
    }

    /// Сбрасывает все характеристики к минимальным значениям
    mutating func reset() {
        strength = Constants.Stat.minValue
        dexterity = Constants.Stat.minValue
        constitution = Constants.Stat.minValue
        intelligence = Constants.Stat.minValue
        wisdom = Constants.Stat.minValue
        charisma = Constants.Stat.minValue
    }
}
