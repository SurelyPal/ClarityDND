//
//  RaceStepView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

// RaceStepView.swift
// Clarity
//
// Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct RaceStepView: View {
    @Environment(\.theme) private var theme
    @Binding var selected: Race
    let template: GameTemplate? // 🆕 НОВОЕ
    
    // 🆕 НОВОЕ: Фильтруем расы по шаблону
    private var availableRaces: [Race] {
        guard let template = template else {
            return Race.allCases
        }
        return Race.allCases.filter { template.isRaceAvailable($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                stepHeader

                DSdivider().padding(.bottom, 8)
                
                if availableRaces.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(availableRaces) { race in
                            RaceCard(
                                icon: race.icon,
                                name: race.rawValue,
                                desc: race.shortDescription,
                                isSelected: selected == race
                            )
                            .onTapGesture {
                                selected = race
                                SoundManager.shared.play(.pageTurn, haptic: .light)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Шаг 2 из 5") // 🆕 ИЗМЕНЕНО: было "Шаг 1 из 4"
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(theme.textDim)
            Text("Выберите расу")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(theme.primary)
                .padding(.bottom, 8)
            
            if let template = template {
                Text("Доступно для шаблона: \(template.name)")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 40))
                .foregroundColor(theme.textDim.opacity(0.5))
            
            Text("Нет доступных рас")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("В этом шаблоне не определены расы. Обратитесь к Гейм Мастеру.")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
