//
//  TarotCardView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct TarotCardView: View {
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
                        .fill(card.isRevealed ? Color.dsSurface : Color.dsRed.opacity(0.15))
                    
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
                            .foregroundColor(card.isRevealed ? Color.dsGold : Color.dsRed)
                            .multilineTextAlignment(.center)
                        
                        Text(card.arcana)
                            .font(.system(size: 9))
                            .tracking(1)
                            .foregroundColor(Color.dsTextDim)
                        
                        if !card.isRevealed {
                            Text("ПЕРЕВЁРНУТА")
                                .font(.system(size: 8, weight: .medium))
                                .tracking(1)
                                .foregroundColor(Color.dsRed.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.dsRed.opacity(0.15))
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
                            .foregroundColor(Color.dsTextDim)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.dsSurfaceAlt)
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
                            .fill(Color.dsGold.opacity(0.5))
                            .frame(width: 2)
                        
                        Text(card.effect)
                            .font(.system(size: 11))
                            .foregroundColor(Color.dsText)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dsSurfaceAlt.opacity(0.6))
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
                        .foregroundColor(card.canUse && canEdit ? Color.dsGold : Color.dsTextDim)
                        Text("Исп.")
                            .font(.system(size: 8))
                            .foregroundColor(Color.dsTextDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        card.canUse && canEdit
                        ? Color.dsGold.opacity(0.1)
                        : Color.dsSurfaceAlt
                    )
                }
                .buttonStyle(.plain)
                .disabled(!card.canUse || !canEdit)
                
                // Разделитель
                Rectangle()
                    .fill(Color.dsBorder)
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
                            .foregroundColor(Color.dsText)
                            .rotationEffect(.degrees(isFlipping ? 180 : 0))
                        Text(card.isRevealed ? "Закрыть" : "Открыть")
                            .font(.system(size: 8))
                            .foregroundColor(Color.dsTextDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                // Разделитель
                Rectangle()
                    .fill(Color.dsBorder)
                    .frame(width: 0.5)
                
                // Редактировать
                Button(action: onEdit) {
                    VStack(spacing: 2) {
                        Image(systemName: canEdit ? "pencil" : "lock.fill")
                            .font(.system(size: 13))
                            .foregroundColor(canEdit ? Color.dsGold : Color.dsTextDim)
                        Text("Изменить")
                            .font(.system(size: 8))
                            .foregroundColor(Color.dsTextDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)
            }
            .background(Color.dsSurfaceAlt)
        }
        .cornerRadius(4)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        card.isRevealed ? Color.dsBorder : Color.dsRed.opacity(0.3),
                        lineWidth: isExpanded ? 1.5 : 1
                    )
                CornerOrnaments(size: 10)
            }
        )
        .shadow(
            color: isExpanded ? Color.dsGold.opacity(0.3) : Color.clear,
            radius: isExpanded ? 8 : 0
        )
        .opacity(card.canUse ? 1 : 0.6)
        .animation(.spring(response: 0.35), value: isExpanded)
    }
}

