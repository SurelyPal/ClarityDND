//
//  InventoryItemRow.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//
import SwiftUI

struct InventoryItemRow: View {
    @Binding var item: InventoryItem
    let isHighlighted: Bool
    let canEdit: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleEquip: () -> Void
    let onUpdate: () -> Void
    
    @State private var isExpanded = false
    
    private var hasDescription: Bool {
        !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ═══════════════════════════════════════════
            // 🔘 ОСНОВНАЯ СТРОКА (кликабельная для разворачивания)
            // ═══════════════════════════════════════════
            HStack(spacing: 12) {
                
                // Кнопка экипировки/снятия (тап по слоту)
                slotEquipButton
                
                // Кликабельная область: название + статы + индикатор разворачивания
                Button {
                    guard hasDescription else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(item.isEquipped ? Color.dsGold : Color.dsText)
                            if !item.stats.isEmpty {
                                Text(item.stats)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.dsGoldDim)
                            }
                        }
                        
                        Spacer(minLength: 4)
                        
                        // Индикатор возможности разворачивания
                        if hasDescription {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.dsTextDim)
                                .padding(6)
                                .background(Color.dsSurfaceAlt)
                                .clipShape(Circle())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!hasDescription)
                
                // Кнопка редактирования
                Button(action: onEdit) {
                    Image(systemName: canEdit ? "pencil.circle.fill" : "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(canEdit ? Color.dsGold : Color.dsTextDim.opacity(0.5))
                        .background(Color.dsSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)                    // 🆕
                
                // Кнопка удаления
                Button(action: onDelete) {
                    Image(systemName: canEdit ? "xmark.circle.fill" : "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(canEdit ? Color.dsRed : Color.dsTextDim.opacity(0.5))
                        .background(Color.dsSurface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)                    // 🆕
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .background(
                isHighlighted ? Color.dsGold.opacity(0.08) : Color.clear
            )
            
            // ═══════════════════════════════════════════
            // 📖 РАЗВЁРНУТОЕ ОПИСАНИЕ (с анимацией)
            // ═══════════════════════════════════════════
            if isExpanded && hasDescription {
                VStack(alignment: .leading, spacing: 8) {
                    // Декоративная линия слева
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle()
                            .fill(Color.dsGold.opacity(0.4))
                            .frame(width: 2)
                        
                        Text(item.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.dsText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Подсказка
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 9))
                        Text("Нажмите чтобы свернуть")
                            .font(.system(size: 10))
                            .tracking(0.5)
                    }
                    .foregroundColor(Color.dsTextDim)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
                .background(Color.dsSurfaceAlt.opacity(0.5))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            // Разделитель снизу
            Rectangle()
                .fill(Color.dsBorder)
                .frame(height: 0.5)
        }
        // Подсветка при разворачивании
        .background(
            isExpanded ? Color.dsGold.opacity(0.03) : Color.clear
        )
    }
    
    // MARK: - Кнопка экипировки/снятия (тап по слоту)
    
    private var slotEquipButton: some View {
        Button {
            // ✅ Тап по слоту = переключить экипировку
            // Вся логика снятия предыдущего предмета — в InventoryTabView
            guard item.slot.isEquippable else { return }
            
            withAnimation(.spring(response: 0.3)) {
                onToggleEquip()
            }
            SoundManager.shared.play(.equip, haptic: .light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: item.slot.icon)
                    .font(.system(size: 12))
                Text(item.slot.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                
                // Индикатор состояния (надет/в инвентаре)
                Image(systemName: item.isEquipped ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 9))
                    .foregroundColor(item.isEquipped ? Color.dsGold : Color.dsTextDim.opacity(0.5))
            }
            .foregroundColor(item.isEquipped ? Color.dsGold : Color.dsTextDim)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                item.isEquipped
                ? Color.dsGold.opacity(0.12)
                : Color.dsSurfaceAlt
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        item.isEquipped ? Color.dsGold.opacity(0.4) : Color.dsBorder,
                        lineWidth: 0.5
                    )
            )
            .cornerRadius(3)
        }
        .buttonStyle(.plain)
        .disabled(!canEdit)                    // 🆕
        .opacity(canEdit ? 1.0 : 0.5)          // 🆕
    }
}
