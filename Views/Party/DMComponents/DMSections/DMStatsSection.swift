//
//  DMStatsSection.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct DMStatsSection: View {
    @Environment(\.theme) private var theme
    let member: PartyMember
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ХАРАКТЕРИСТИКИ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(theme.textDim)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if let stats = member.stats {
                VStack(spacing: 0) {
                    StatRow(name: "Сила", value: stats.strength, isLast: false)
                    StatRow(name: "Ловкость", value: stats.dexterity, isLast: false)
                    StatRow(name: "Телосложение", value: stats.constitution, isLast: false)
                    StatRow(name: "Интеллект", value: stats.intelligence, isLast: false)
                    StatRow(name: "Мудрость", value: stats.wisdom, isLast: false)
                    StatRow(name: "Харизма", value: stats.charisma, isLast: true)
                }
                .dsCard()
                .padding(.horizontal, 16)
            } else {
                Text("Данные ещё не получены")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
                    .padding()
            }
        }
    }
}
