//
//  InstrumentType.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import Foundation
import SwiftUI

enum InstrumentType: String, CaseIterable, Codable {
    case lute = "Лютня"
    case flute = "Флейта"
    case drum = "Барабан"
    
    /// Иконка инструмента
    var icon: String {
        switch self {
        case .lute:  return "🎸"
        case .flute: return "🎵"
        case .drum:  return "🥁"
        }
    }
    
    /// Акцентный цвет для UI (как Color)
    var accentColor: Color {
        switch self {
        case .lute:  return Color.dsGold
        case .flute: return Color.dsBlue
        case .drum:  return Color.dsRed
        }
    }
    
    /// Цвет свечения для слотов модификаций
    var glowColor: Color {
        switch self {
        case .lute:  return Color.dsGold.opacity(0.4)
        case .flute: return Color.dsBlue.opacity(0.4)
        case .drum:  return Color.dsRed.opacity(0.4)
        }
    }
    
    /// Фоновый цвет (приглушённый)
    var backgroundColor: Color {
        accentColor.opacity(0.08)
    }
    
    /// Лор-описание инструмента для тематического заголовка
    var loreDescription: String {
        switch self {
        case .lute:  return "Струны хранят эхо древних бардов"
        case .flute: return "Ветер шепчет в её отверстиях"
        case .drum:  return "Ритм, от которого дрожит земля"
        }
    }
    
    /// SF Symbol для модификаций по умолчанию
    var sfSymbol: String {
        switch self {
        case .lute:  return "guitars"
        case .flute: return "wind"
        case .drum:  return "circle.grid.cross"
        }
    }
    
    /// Определяет тип инструмента по названию
    static func from(name: String) -> InstrumentType? {
        let normalized = name.lowercased()
        switch normalized {
        case let s where s.contains("лютня"): return .lute
        case let s where s.contains("флейт"): return .flute
        case let s where s.contains("барабан"): return .drum
        default: return nil
        }
    }
}

