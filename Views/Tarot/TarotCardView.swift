//
//  TarotCardView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct TarotCardView: View {
    @Environment(\.theme) private var theme
    @Binding var card: TarotCard
    let canEdit: Bool
    let onUse: () -> Void
    let onEdit: () -> Void
    
    @State private var isExpanded = false
    @State private var isFlipping = false
    
    private var hasEffect: Bool {
        !card.effect.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ═══════════════════════════════════════════
            // 🃏 ВЕРХНЯЯ ЧАСТЬ — кликабельная для разворачивания
            // ❌ УБРАЛИ фиксированную высоту — теперь растёт по содержимому
            // ═══════════════════════════════════════════
            Button {
                guard hasEffect else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Rectangle()
                        .fill(card.isRevealed ? theme.surface : theme.danger.opacity(0.15))
                    
                    VStack(spacing: 6) {
                        if card.isRevealed {
                            Text("🃏").font(.system(size: 28))
                        } else {
                            Text("🃏")
                                .font(.system(size: 28))
                                .rotationEffect(.degrees(180))
                                .opacity(0.5)
                        }
                        
                        Text(card.name)
                            .font(.system(size: 13, weight: .medium))
                            .tracking(0.5)
                            .foregroundColor(card.isRevealed ? theme.primary : theme.danger)
                            .multilineTextAlignment(.center)
                        
                        Text(card.arcana)
                            .font(.system(size: 9))
                            .tracking(1)
                            .foregroundColor(theme.textDim)
                        
                        if !card.isRevealed {
                            Text("ПЕРЕВЁРНУТА")
                                .font(.system(size: 8, weight: .medium))
                                .tracking(1)
                                .foregroundColor(theme.danger.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(theme.danger.opacity(0.15))
                                .cornerRadius(2)
                        }
                        
                        // Индикатор разворачивания
                        if hasEffect {
                            HStack(spacing: 4) {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                Text(isExpanded ? "Свернуть" : "Подробнее")
                                    .font(.system(size: 8, weight: .medium))
                                    .tracking(0.5)
                            }
                            .foregroundColor(theme.textDim)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(theme.surfaceAlt)
                            .cornerRadius(10)
                            .padding(.top, 2)
                        }
                    }
                    .padding(10)
                    
                    CornerOrnaments(size: 14)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!hasEffect)
            
            DSdivider()
            
            // ═══════════════════════════════════════════
            // 📖 РАЗВЁРНУТОЕ ОПИСАНИЕ
            // ═══════════════════════════════════════════
            if isExpanded && hasEffect {
                VStack(spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        Rectangle()
                            .fill(theme.primary.opacity(0.5))
                            .frame(width: 2)
                        
                        Text(card.effect)
                            .font(.system(size: 11))
                            .foregroundColor(theme.text)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surfaceAlt.opacity(0.6))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            // ═══════════════════════════════════════════
            // 🎛️ ПАНЕЛЬ ДЕЙСТВИЙ (компактная)
            // ═══════════════════════════════════════════
            HStack(spacing: 0) {
                // Использовать
                Button(action: onUse) {
                    VStack(spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: card.canUse && canEdit ? "sparkles" : "lock.fill")
                                .font(.system(size: 10))
                            Text("\(card.usesLeft)")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(card.canUse && canEdit ? theme.primary : theme.textDim)
                        Text("Исп.")
                            .font(.system(size: 8))
                            .foregroundColor(theme.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        card.canUse && canEdit
                        ? theme.primary.opacity(0.1)
                        : theme.surfaceAlt
                    )
                }
                .buttonStyle(.plain)
                .disabled(!card.canUse || !canEdit)
                
                // Разделитель
                Rectangle()
                    .fill(theme.border)
                    .frame(width: 0.5)
                
                // Перевернуть (разрешено всегда — это просмотр)
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        isFlipping = true
                        card.isRevealed.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isFlipping = false
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.system(size: 13))
                            .foregroundColor(theme.text)
                            .rotationEffect(.degrees(isFlipping ? 180 : 0))
                        Text(card.isRevealed ? "Закрыть" : "Открыть")
                            .font(.system(size: 8))
                            .foregroundColor(theme.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                // Разделитель
                Rectangle()
                    .fill(theme.border)
                    .frame(width: 0.5)
                
                // Редактировать
                Button(action: onEdit) {
                    VStack(spacing: 2) {
                        Image(systemName: canEdit ? "pencil" : "lock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(canEdit ? theme.primary : theme.textDim)
                        Text("Изменить")
                            .font(.system(size: 8))
                            .foregroundColor(theme.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)
            }
            .background(theme.surfaceAlt)
        }
        .cornerRadius(4)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        card.isRevealed ? theme.border : theme.danger.opacity(0.3),
                        lineWidth: isExpanded ? 1.5 : 1
                    )
                CornerOrnaments(size: 10)
            }
        )
        .shadow(
            color: isExpanded ? theme.primary.opacity(0.3) : Color.clear,
            radius: isExpanded ? 8 : 0
        )
        .opacity(card.canUse ? 1 : 0.6)
        .animation(.spring(response: 0.35), value: isExpanded)
    }
}

