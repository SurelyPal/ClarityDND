//
//  DSCombatStatsView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.

import SwiftUI

struct DSCombatStatsView: View {
    
    let character: DNDCharacter
    
    var body: some View {
        VStack(spacing: 0) {
            // ✅ ВСЕ боевые характеристики теперь вычисляются в модели!
            DSCombatRow(icon:  "shield.fill", label:  "Класс доспеха",
                        value:  "\(character.armorClass)")
            DSCombatRow(icon:  "bolt.fill", label:  "Инициатива",
                        value: Constants.Stat.formattedModifier(character.initiative))
            DSCombatRow(icon:  "star.fill", label:  "Бонус мастерства",
                        value:  "+\(character.proficiencyBonus)")
            DSCombatRow(icon:  "eye.fill", label:  "Пассивное восприятие",
                        value:  "\(character.passivePerception)")
            DSCombatRow(icon:  "figure.walk", label:  "Скорость",
                        value:  "\(character.speed) м", isLast: true)
        }
        .dsCard()
        .padding(.horizontal, 16)
    }
}

struct DSCombatRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let label: String
    let value: String
    var isLast: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.primaryDim)
                .font(.system(size: 13))
                .frame(width: 24)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.text)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
    }
}

