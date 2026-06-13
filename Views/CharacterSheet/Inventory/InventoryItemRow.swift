// InventoryItemRow.swift
// Clarity
//
// Created by KEBAB on 04.06.2026.
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
    let onTransfer: ((InventoryItem) -> Void)? // 🆕 Передача предмета

    // 🆕 Для меню действий
    @State private var showingActionMenu = false
    @State private var showingTransferSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка предмета
            Image(systemName: IconHelper.iconForItem(item))
                .font(.system(size: 20))
                .foregroundColor(item.isEquipped ? Color.dsGold : Color.dsTextDim)
                .frame(width: 32)
            
            // Информация о предмете
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name.isEmpty ? "Без названия" : item.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.dsText)
                    
                    if item.isEquipped {
                        Text("ЭКИПИРОВАНО")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(Color.dsGold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dsGold.opacity(0.15))
                            .cornerRadius(3)
                    }
                }
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsTextDim)
                        .lineLimit(2)
                }
                
                if !item.stats.isEmpty {
                    Text(item.stats)
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsGold.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Кнопка слота (экипировка)
            if item.slot.isEquippable {
                slotEquipButton
            }
            
            // 🆕 Кнопка меню действий
            if canEdit {
                Menu {
                    Button(action: onEdit) {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button(action: { onTransfer?(item) })  {
                        Label("Передать игроку", systemImage: "arrow.right.circle")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Выбросить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.dsTextDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            isHighlighted ? Color.dsGold.opacity(0.08) : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(Color.dsBorder)
                .frame(height: 0.5),
            alignment: .bottom
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
        .disabled(!canEdit) // 🆕
        .opacity(canEdit ? 1.0 : 0.5) // 🆕
    }
}


// Лист для передачи предмета (Только UI, логика в InventoryTabView)
struct TransferItemSheet: View {
    let item: InventoryItem
    @EnvironmentObject var partyManager: PartyManager
    @Environment(\.dismiss) var dismiss
    
    let onTransfer: (PartyMember) -> Void // 🆕 Замыкание для передачи логики наверх
    
    @State private var selectedPlayerID: UUID?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("✦ ПЕРЕДАТЬ ПРЕДМЕТ ✦")
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundColor(Color.dsGold)
            
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.dsText)
            
            DSdivider().padding(.horizontal, 40)
            
            Text("Выберите игрока:")
                .font(.system(size: 12))
                .foregroundColor(Color.dsTextDim)
            
            ScrollView {
                VStack(spacing: 8) {
                    // 🆕 Исключаем текущего персонажа из списка получателей
                    let currentCharacterID = partyManager.selectedCharacter?.id
                    
                    ForEach(partyManager.partyMembers.filter { member in
                        member.isConnected && member.id != currentCharacterID // 🔧 Фильтр "не я"
                    }) { member in
                        Button {
                            selectedPlayerID = member.id
                            onTransfer(member) // 🆕 Вызываем замыкание вместо сломанного PartyManager.transferItem
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.dsGold)
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.dsText)
                                    Text("\(member.characterClass) • Уровень \(member.level)")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.dsTextDim)
                                }
                                Spacer()
                                if selectedPlayerID == member.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.dsGold)
                                }
                            }
                            .padding(12)
                            .background(Color.dsSurface)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedPlayerID == member.id ? Color.dsGold : Color.dsBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Button { dismiss() } label: {
                Text("ОТМЕНА")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dsSurfaceAlt)
                    .foregroundColor(Color.dsText)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(Color.dsBackground)
        .presentationDetents([.medium])
    }
}
