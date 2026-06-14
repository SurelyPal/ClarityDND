//
//  HPHistorySheet.swift
//  Clarity
//
//  Created by KEBAB on 08.06.2026.
//

import SwiftUI

struct HPHistorySheet: View {
    @Environment(\.theme) private var theme
    let hpHistory: [HPChange]
    let onClearHistory: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Заголовок
                HStack {
                    Text("✦ ИСТОРИЯ ЗДОРОВЬЯ ✦")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(2)
                        .foregroundColor(theme.primary)
                    
                    Spacer()
                    
                    if !hpHistory.isEmpty {
                        Button("Очистить") {
                            onClearHistory()
                        }
                        .font(.system(size: 13))
                        .foregroundColor(theme.danger)
                    }
                    
                    Button("Закрыть") {
                        dismiss()
                    }
                    .font(.system(size: 13))
                    .foregroundColor(theme.textDim)
                }
                
                DSdivider()
                
                if hpHistory.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "scroll")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textDim.opacity(0.5))
                        
                        Text("История пуста")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textDim)
                        
                        Text("Изменения HP будут записываться здесь")
                            .font(.system(size: 13))
                            .foregroundColor(theme.textDim.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    
                    Spacer()
                } else {
                    // Список изменений
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(hpHistory) { change in
                                HPChangeRow(change: change)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Строка истории изменений

struct HPChangeRow: View {
    @Environment(\.theme) private var theme 
    let change: HPChange
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка и количество
            VStack(spacing: 2) {
                Image(systemName: change.isHealing ? "heart.fill" : "heart.slash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(change.isHealing ? .green : theme.danger)
                
                Text(change.isHealing ? "+\(change.amount)" : "\(change.amount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(change.isHealing ? .green : theme.danger)
            }
            .frame(width: 50)
            
            // Детали
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(change.reason.isEmpty ? "Изменение HP" : change.reason)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.text)
                    
                    Spacer()
                    
                    Text(change.formattedTime)
                        .font(.system(size: 11))
                        .foregroundColor(theme.textDim)
                }
                
                HStack(spacing: 4) {
                    Text("\(change.oldHP)")
                        .foregroundColor(theme.textDim)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textDim)
                    
                    Text("\(change.newHP)")
                        .foregroundColor(change.isHealing ? .green : theme.danger)
                }
                .font(.system(size: 12))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(change.isHealing ? Color.green.opacity(0.3) : theme.danger.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HPHistorySheet(hpHistory: [
        HPChange(amount: -5, reason: "Урон от гоблина", oldHP: 20, newHP: 15),
        HPChange(amount: 8, reason: "Зелье лечения", oldHP: 15, newHP: 23),
        HPChange(amount: -12, reason: "Критический удар", oldHP: 23, newHP: 11),
        HPChange(amount: 20, reason: "Полное восстановление", oldHP: 11, newHP: 31)
    ], onClearHistory: {})
    .preferredColorScheme(.dark)
}
