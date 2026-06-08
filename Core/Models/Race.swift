//
//  Race.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import Foundation

enum Race: String, CaseIterable, Codable, Identifiable {
    case human = "Человек"
    case illicit = "Иллицит"
    
    var id: String { self.rawValue }
    
    /// Базовая скорость расы в метрах (для отображения в UI)
    /// 30 футов = ~9 метров по правилам D&D 5e
    var baseSpeedMeters: Int {
        switch self {
        case .human:   return 9
        case .illicit: return 9   // Иллициты тоже быстры — тайные агенты
        }
    }
    
    var shortDescription: String {
        switch self {
        case .human:   return "+1 ко всем характеристикам"
        case .illicit: return "+2 Ловкость, тёмное зрение"
        }
    }
    // Иконка расы для UI (SF Symbol)
    var icon: String {
        switch self {
        case .human:   return "person.fill"
        case .illicit: return "ear.fill"  // Иллициты — "слушающие" тайные агенты
        }
    }
}
