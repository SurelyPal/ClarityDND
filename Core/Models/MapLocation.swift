//
//  MapLocation.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import Foundation

struct MapLocation: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let description: String
    let xPercent: Double  // 0-100
    let yPercent: Double  // 0-100
    let icon: String
    
    /// Стартовые локации игры
    static let defaults: [MapLocation] = [
        .init(name: "Тёмный лес",
              description: "Древние деревья шепчут забытые имена. Здесь обитают волки-призраки.",
              xPercent: 25, yPercent: 40,
              icon: "tree.fill"),
        .init(name: "Замок Эрстус",
              description: "Резиденция короля. Высокие стены хранят много тайн.",
              xPercent: 65, yPercent: 30,
              icon: "building.columns.fill"),
        .init(name: "Таверна «Пьяный дракон»",
              description: "Лучший эль в королевстве. Сюда приходят за слухами и работой.",
              xPercent: 50, yPercent: 70,
              icon: "mug.fill"),
        .init(name: "Горные руины",
              description: "Останки древней цивилизации. Говорят, там спрятано сокровище.",
              xPercent: 80, yPercent: 60,
              icon: "mountain.2.fill"),
    ]
}

