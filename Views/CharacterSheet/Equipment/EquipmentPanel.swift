//
//  EquipmentPanel.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//
import SwiftUI

struct EquipmentPanel: View {
    @Binding var character: DNDCharacter
    @Binding var selectedSlot: EquipmentSlot?
    
    // Слоты расположены как на силуэте персонажа
    private let topRow: [EquipmentSlot] = [.head, .amulet]
    private let middleRow: [EquipmentSlot] = [.mainHand, .chest, .offHand]
    private let lowerRow: [EquipmentSlot] = [.hands, .ring1, .ring2]
    private let bottomRow: [EquipmentSlot] = [.legs, .feet]
    
    var body: some View {
        VStack(spacing: 12) {
            DSSectionHeader(title: "Снаряжение")
            
            VStack(spacing: 12) {
                // Верхний ряд: голова и амулет
                HStack(spacing: 12) {
                    ForEach(topRow, id: \.self) { slot in
                        EquipmentSlotView(
                            slot: slot,
                            item: item(in: slot),
                            isSelected: selectedSlot == slot,
                            onUnequip: { unequip(slot) },
                            onSelect: { toggleSlotSelection(slot) }
                        )
                    }
                }
                
                // Средний ряд: руки и нагрудник
                HStack(spacing: 12) {
                    ForEach(middleRow, id: \.self) { slot in
                        EquipmentSlotView(
                            slot: slot,
                            item: item(in: slot),
                            isSelected: selectedSlot == slot,
                            onUnequip: { unequip(slot) },
                            onSelect: { toggleSlotSelection(slot) }
                        )
                    }
                }
                
                // Нижний ряд: перчатки и кольца
                HStack(spacing: 12) {
                    ForEach(lowerRow, id: \.self) { slot in
                        EquipmentSlotView(
                            slot: slot,
                            item: item(in: slot),
                            isSelected: selectedSlot == slot,
                            onUnequip: { unequip(slot) },
                            onSelect: { toggleSlotSelection(slot) }
                        )
                    }
                }
                
                // Самый нижний ряд: штаны и обувь
                HStack(spacing: 12) {
                    ForEach(bottomRow, id: \.self) { slot in
                        EquipmentSlotView(
                            slot: slot,
                            item: item(in: slot),
                            isSelected: selectedSlot == slot,
                            onUnequip: { unequip(slot) },
                            onSelect: { toggleSlotSelection(slot) }
                        )
                    }
                }
            }
            .padding(16)
            .dsCard()
            .padding(.horizontal, 16)
        }
    }
    
    private func item(in slot: EquipmentSlot) -> InventoryItem? {
        character.inventory.first { $0.slot == slot && $0.isEquipped }
    }
    
    private func unequip(_ slot: EquipmentSlot) {
        if let existingItem = item(in: slot),
           let index = character.inventory.firstIndex(where: { $0.id == existingItem.id }) {
            character.inventory[index].isEquipped = false
        }
    }
    
    private func toggleSlotSelection(_ slot: EquipmentSlot) {
        withAnimation {
            selectedSlot = (selectedSlot == slot) ? nil : slot
        }
    }
}

// MARK: - Один слот экипировки

struct EquipmentSlotView: View {
    let slot: EquipmentSlot
    let item: InventoryItem?
    let isSelected: Bool
    let onUnequip: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                ZStack {
                    // Фон слота
                    RoundedRectangle(cornerRadius: 3)
                        .fill(item != nil ? Color.dsGold.opacity(0.08) : Color.dsSurfaceAlt)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(
                                    isSelected ? Color.dsGold : (item != nil ? Color.dsGold : Color.dsBorder),
                                    lineWidth: isSelected ? 2 : (item != nil ? 1 : 0.5)
                                )
                        )
                    
                    // Иконка или название предмета
                    if let item = item {
                        VStack(spacing: 2) {
                            Image(systemName: slot.icon)
                                .font(.system(size: 14))
                                .foregroundColor(Color.dsGold)
                            Text(item.name)
                                .font(.system(size: 8))
                                .foregroundColor(Color.dsText)
                                .lineLimit(1)
                                .padding(.horizontal, 2)
                        }
                    } else {
                        Image(systemName: slot.icon)
                            .font(.system(size: 16))
                            .foregroundColor(Color.dsTextDim.opacity(0.5))
                    }
                }
                
                Text(slot.rawValue)
                    .font(.system(size: 8))
                    .tracking(0.5)
                    .foregroundColor(isSelected ? Color.dsGold : Color.dsTextDim)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if item != nil {
                        withAnimation(.spring(response: 0.3)) {
                            onUnequip()
                        }
                    }
                }
        )
    }
}
