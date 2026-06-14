//
//  HPSection.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct HPSection: View, Equatable {
    @Environment(\.theme) private var theme
    @Binding var character: DNDCharacter
    @Binding var currentHP: Int
    let canEdit: Bool
    @Binding var showEditBlockedAlert: Bool
    @EnvironmentObject var store: CharacterStore
    
    // 🆕 Сравнение для оптимизации redraw
    static func == (lhs: HPSection, rhs: HPSection) -> Bool {
        lhs.character.hitPoints == rhs.character.hitPoints &&
        lhs.currentHP == rhs.currentHP &&
        lhs.canEdit == rhs.canEdit
    }
    
    var body: some View {
        VStack(spacing: 12) {
            DSSectionHeader(title: "Жизненная сила")
            
            VStack(spacing: 12) {
                HStack {
                    Text("♥").foregroundColor(theme.danger)
                    Text("Очки здоровья")
                        .font(.system(size: 14))
                        .foregroundColor(theme.text)
                    Spacer()
                    Text("\(currentHP) / \(character.hitPoints)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(hpColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.surfaceAlt)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hpColor)
                            .frame(width: geo.size.width * hpFraction, height: 8)
                            .animation(.spring(), value: currentHP)
                    }
                }
                .frame(height: 8)
                
                HStack(spacing: 8) {
                    DSHPButton(label: "-5", color: .dsRed) {
                        guardedEdit {
                            currentHP = max(0, currentHP - 5)
                        }
                    }
                    DSHPButton(label: "-1", color: .dsRed) {
                        guardedEdit {
                            currentHP = max(0, currentHP - 1)
                        }
                    }
                    DSHPButton(label: "↺", color: .dsTextDim) {
                        guardedEdit {
                            currentHP = character.hitPoints
                        }
                    }
                    DSHPButton(label: "+1", color: .dsGoldDim) {
                        guardedEdit {
                            currentHP = min(character.hitPoints, currentHP + 1)
                        }
                    }
                    DSHPButton(label: "+5", color: .dsGoldDim) {
                        guardedEdit {
                            currentHP = min(character.hitPoints, currentHP + 5)
                        }
                    }                }
            }
            .padding(16)
            .dsCard()
            .padding(.horizontal, 16)
        }
        .onChange(of: currentHP) { oldValue, newValue in
            // 🆕 Защита от рекурсии: если model уже имеет это значение
            // (например, при синхронизации извне) — не отправляем лишний sync
            guard character.currentHP != newValue else { return }
            
            character.currentHP = newValue
            // ✅ Явно указываем что это быстрое изменение (только HP)
            store.update(character, changed: .basic)
        }
    }
    private func guardedEdit(_ action: () -> Void) {
        if canEdit {
            action()
        } else {
            showEditBlockedAlert = true
        }
    }
    
    private var hpFraction: Double {
        guard character.hitPoints > 0 else { return 0 }
        return Double(currentHP) / Double(character.hitPoints)
    }
    
    private var hpColor: Color {
        if hpFraction > 0.5 { return theme.primary }
        if hpFraction > 0.25 { return .orange }
        return theme.danger
    }
}

// MARK: - Wrapper для стресса
struct StressSection: View, Equatable {
    @Binding var character: DNDCharacter
    let canEdit: Bool
    
    // 🆕 Сравнение для оптимизации redraw
    static func == (lhs: StressSection, rhs: StressSection) -> Bool {
        lhs.character.stress == rhs.character.stress &&
        lhs.character.rerollPoints == rhs.character.rerollPoints &&
        lhs.canEdit == rhs.canEdit
    }
    
    var body: some View {
        VStack(spacing: 12) {
            DSSectionHeader(title: "Душевное состояние")
            StressTrackerView(character: $character, canEdit: canEdit)
                .padding(.horizontal, 16)
        }
    }
}
