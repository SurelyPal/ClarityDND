//
//  DNDAlignment.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import Foundation

enum DNDAlignment: String, CaseIterable, Codable, Identifiable, Equatable {
    case lawfulGood     = "Законно-добрый"
    case neutralGood    = "Нейтрально-добрый"
    case chaoticGood    = "Хаотично-добрый"
    case lawfulNeutral  = "Законно-нейтральный"
    case trueNeutral    = "Истинно нейтральный"
    case chaoticNeutral = "Хаотично-нейтральный"
    case lawfulEvil     = "Законно-злой"
    case neutralEvil    = "Нейтрально-злой"
    
    case chaoticEvil    = "Хаотично-злой"
    
    var id: String { self.rawValue }
    
    
    /// Краткое название для UI
    var shortName: String {
        switch self {
        case .lawfulGood:     return "ЗД"
        case .neutralGood:    return "НД"
        case .chaoticGood:    return "ХД"
        case .lawfulNeutral:  return "ЗН"
        case .trueNeutral:    return "ИН"
        case .chaoticNeutral: return "ХН"
        case .lawfulEvil:     return "ЗЗ"
        case .neutralEvil:    return "НЗ"
        case .chaoticEvil:    return "ХЗ"
        }
    }
    
    /// Ось морали (добрый/нейтральный/злой)
    var moralAxis: String {
        switch self {
        case .lawfulGood, .neutralGood, .chaoticGood: return "Добрый"
        case .lawfulEvil, .neutralEvil, .chaoticEvil: return "Злой"
        default: return "Нейтральный"
        }
    }
}
