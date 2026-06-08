//
//  InstrumentModification.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI
import Foundation

struct InstrumentModification: Identifiable, Codable, Equatable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var description: String = ""
    var effect: String = ""
    var slot: InstrumentModificationSlot = .resonance
    
    /// Цветовая схема модификации
    var rarity: Rarity = .common
    
    enum Rarity: String, Codable, CaseIterable {
        case common = "Обычная"
        case rare = "Редкая"
        case epic = "Эпическая"
        case legendary = "Легендарная"
        
        var color: Color {
            switch self {
            case .common: return Color.dsTextDim
            case .rare: return Color.dsBlue
            case .epic: return Color.dsGold
            case .legendary: return Color.dsRed
            }
        }
    }
}
