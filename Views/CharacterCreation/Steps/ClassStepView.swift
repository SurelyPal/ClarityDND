//
//  ClassStepView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct ClassStepView: View {
    @Environment(\.theme) private var theme
    @Binding var selected: CharacterClass
    let template: GameTemplate? // 🆕 НОВОЕ
    
    // 🆕 НОВОЕ: Фильтруем классы по шаблону
    private var availableClasses: [CharacterClass] {
        guard let template = template else {
            return CharacterClass.allCases
        }
        return CharacterClass.allCases.filter { template.isClassAvailable($0) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                stepHeader

                DSdivider().padding(.bottom, 8)
                
                if availableClasses.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(availableClasses) { cls in
                            RaceCard(
                                icon: cls.icon,
                                name: cls.rawValue,
                                desc: cls.shortDescription,
                                isSelected: selected == cls
                            )
                            .onTapGesture {
                                selected = cls
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
            Text("Шаг 3 из 5") // 🆕 ИЗМЕНЕНО: было "Шаг 2 из 4"
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(theme.textDim)
            Text("Выберите класс")
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
            Image(systemName: "shield.slash")
                .font(.system(size: 40))
                .foregroundColor(theme.textDim.opacity(0.5))
            
            Text("Нет доступных классов")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("В этом шаблоне не определены классы. Обратитесь к Гейм Мастеру.")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
