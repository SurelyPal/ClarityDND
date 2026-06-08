//
//  InstrumentModificationSlot.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import Foundation

enum InstrumentModificationSlot: String, CaseIterable, Codable {
    case resonance = "Резонанс"
    case enchantment = "Чары"
    case mastery = "Мастерство"
    
    var icon: String {
        switch self {
        case .resonance: return "waveform"
        case .enchantment: return "sparkles"
        case .mastery: return "star.fill"
        }
    }
    
    var description: String {
        switch self {
        case .resonance: return "Усиливает звук и дальность"
        case .enchantment: return "Добавляет магические эффекты"
        case .mastery: return "Повышает мастерство исполнения"
        }
    }
}
