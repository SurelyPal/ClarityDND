//
//  StressTrackerView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct StressTrackerView: View, Equatable {
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    
    // 🆕 Сравнение для оптимизации redraw
    static func == (lhs: StressTrackerView, rhs: StressTrackerView) -> Bool {
        lhs.character.stress == rhs.character.stress &&
        lhs.character.rerollPoints == rhs.character.rerollPoints &&
        lhs.canEdit == rhs.canEdit
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ДУШЕВНОЕ СОСТОЯНИЕ")
                    .font(.system(size: 9))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
                Text(Constants.Stress.label(for: character.stress).uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(color(for: character.stress))
            }
            
            HStack(spacing: 5) {
                ForEach(Constants.Stress.levels, id: \.self) { level in
                    DSStressBox(
                        level: level,
                        currentStress: character.stress,
                        color: color(for: level)
                    ) {
                        handleStressChange(level)
                    }
                }
            }
            
            HStack {
                Text("Паника")
                    .font(.system(size: 9))
                    .tracking(1)
                    .foregroundColor(Color.dsRed.opacity(0.6))
                Spacer()
                Text("Баланс")
                    .font(.system(size: 9))
                    .tracking(1)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
                Text("Дзен")
                    .font(.system(size: 9))
                    .tracking(1)
                    .foregroundColor(Color.dsBlue.opacity(0.6))
            }
            
            DSdivider()
            
             RerollPointsSection(character: $character, canEdit: canEdit)  // 🆕
        }
        .padding(16)
        .dsCard()
        .disabled(!canEdit)                    // 🆕 Блокируем всё
        .opacity(canEdit ? 1.0 : 0.6)          // 🆕 Приглушаем
    }
    
    // MARK: - Обработка стресса
    
    private func handleStressChange(_ level: Int) {
        let wasAtMax = character.stress == Constants.Stress.levels.last
        let wasAtMin = character.stress == Constants.Stress.levels.first
        
        // ═══════════════════════════════════════════
        // 🌟 ДОСТИЖЕНИЕ +3 (ДЗЕН) — награда
        // ═══════════════════════════════════════════
        if level == Constants.Stress.levels.last && !wasAtMax {
            let hasFullRerolls = character.rerollPoints >= Constants.Character.maxRerollPoints
            
            if hasFullRerolls {
                // 🎯 Шкала переброса ЗАПОЛНЕНА — оставляем стресс на +3
                character.stress = level
                SoundManager.shared.play(.levelUp, haptic: .success)
            } else {
                // 📈 Есть место для переброса — даём +1 и сбрасываем стресс
                character.rerollPoints = min(
                    character.rerollPoints + 1,
                    Constants.Character.maxRerollPoints
                )
                SoundManager.shared.play(.levelUp, haptic: .success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4)) {
                        character.stress = 0
                    }
                    store.update(character, changed: .basic)
                }
            }
        }
        // ═══════════════════════════════════════════
        // 💀 ДОСТИЖЕНИЕ -3 (ПАНИКА) — наказание
        // ═══════════════════════════════════════════
        else if level == Constants.Stress.levels.first && !wasAtMin {
            if character.rerollPoints > 0 {
                // 🛡️ Есть перебросы → теряем 1 и сбрасываем до -1 (амортизация)
                character.rerollPoints -= 1
                SoundManager.shared.play(.demotion, haptic: .warning)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4)) {
                        character.stress = -1  // Сброс до -1, не до 0!
                    }
                    store.update(character, changed: .basic)
                }
            } else {
                // 💀 Нет перебросов → застреваем на -3 (паника)
                character.stress = level
                SoundManager.shared.play(.demotion, haptic: .error)
            }
        }
        // ═══════════════════════════════════════════
        // 📊 Обычное изменение стресса
        // ═══════════════════════════════════════════
        else {
            character.stress = level
        }
        
        store.update(character, changed: .basic)
    }
    
    private func color(for level: Int) -> Color {
        switch level {
        case -3, -2: return Color.dsRed
        case -1:     return .orange
        case 0:      return Color.dsTextDim
        case 1:      return Color.dsGoldDim
        case 2, 3:   return Color.dsBlue
        default:     return Color.dsTextDim
        }
    }
}

// MARK: - Очки переброса

struct RerollPointsSection: View {
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ОЧКИ ПЕРЕБРОСА")
                    .font(.system(size: 9))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                
                HStack(spacing: 8) {
                    ForEach(0..<Constants.Character.maxRerollPoints, id: \.self) { index in
                        RerollPointIcon(isFilled: index < character.rerollPoints)
                    }
                }
            }
            
            Spacer()
            
            Button {
                guard character.rerollPoints > 0 else { return }
                withAnimation(.spring(response: 0.3)) {
                    character.rerollPoints -= 1
                    
                    // 💥 Цена за использование переброса
                    if character.stress == Constants.Stress.levels.last {
                        // При +3 (Дзен) → сброс в 0
                        character.stress = 0
                    } else if character.stress == Constants.Stress.levels.first {
                        // При -3 (Паника) → сброс в -1
                        character.stress = -1
                    }
                }
                
                SoundManager.shared.play(.equip, haptic: .medium)
                store.update(character, changed: .basic)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11))
                    Text("Перебросить")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.5)
                }
                .foregroundColor(character.rerollPoints > 0 ? Color.dsBackground : Color.dsTextDim)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(character.rerollPoints > 0 ? Color.dsGold : Color.dsSurfaceAlt)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.dsBorder, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .disabled(character.rerollPoints == 0 || !canEdit)  // 🆕
        }
    }
        }
   

// MARK: - Компоненты

struct RerollPointIcon: View {
    let isFilled: Bool
    
    var body: some View {
        ZStack {
            Image(systemName: "diamond.fill")
                .font(.system(size: 22))
                .foregroundColor(isFilled ? Color.dsGold.opacity(0.15) : Color.dsSurfaceAlt)
            
            Image(systemName: "diamond.fill")
                .font(.system(size: 22))
                .foregroundColor(isFilled ? Color.dsGold : Color.clear)
            
            Image(systemName: "diamond")
                .font(.system(size: 22))
                .foregroundColor(isFilled ? Color.dsGold : Color.dsBorder)
            
            if isFilled {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundColor(Color.dsBackground)
            }
        }
        .animation(.spring(response: 0.3), value: isFilled)
    }
}

struct DSStressBox: View {
    let level: Int
    let currentStress: Int
    let color: Color
    let action: () -> Void
    
    private var isSelected: Bool { currentStress == level }
    private var isFilled: Bool {
        if currentStress >= 0 {
            return level >= 0 && level <= currentStress
        } else {
            return level <= 0 && level >= currentStress
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isFilled ? color.opacity(0.25) : Color.dsSurfaceAlt)
                    .frame(height: 38)
                
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? color : Color.dsBorder,
                            lineWidth: isSelected ? 1.5 : 0.5)
                    .frame(height: 38)
                
                Text(level > 0 ? "+\(level)" : "\(level)")
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isFilled ? color : Color.dsTextDim)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

