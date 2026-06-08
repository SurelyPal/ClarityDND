//
//  StatsTabView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.

import SwiftUI

struct StatsTabView: View {
    let character: DNDCharacter
    
    // Массив характеристик для отображения
    private var stats: [(short: String, value: Int)] {
        [
            ("СИЛ", character.stats.strength),
            ("ЛОВ", character.stats.dexterity),
            ("ТЕЛ", character.stats.constitution),
            ("ИНТ", character.stats.intelligence),
            ("ВОЛ", character.stats.wisdom),
            ("ХАР", character.stats.charisma),
        ]
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Сетка характеристик 3x2
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 12
            ) {
                ForEach(stats, id: \.short) { stat in
                    DSStatCard(short: stat.short, value: stat.value)
                }
            }
            .padding(.horizontal, 16)
            
            // Боевые параметры (КД, инициатива и т.д.)
            DSCombatStatsView(character: character)
        }
        .padding(.bottom, 20)
    }
}
