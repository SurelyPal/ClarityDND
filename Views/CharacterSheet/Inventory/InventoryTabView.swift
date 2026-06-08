//
//  InventoryTabView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct InventoryTabView: View {
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    
    @State private var editingItem: InventoryItem? = nil
    @State private var showingAddItem = false
    @State private var selectedSlot: EquipmentSlot? = nil
    
    // Все видимые слоты экипировки
    private let equipSlots: [EquipmentSlot] = [
        .head, .amulet,
        .mainHand, .chest, .offHand,
        .hands, .ring1, .ring2,
        .legs, .feet
    ]
    
    // Предметы, которые можно экипировать (не расходники)
    private var equippableItems: [InventoryItem] {
        character.inventory.filter { $0.slot.isEquippable }
    }
    
    // Фильтрованные предметы по выбранному слоту
    private var filteredItems: [InventoryItem] {
        guard let slot = selectedSlot else { return character.inventory }
        return character.inventory.filter { $0.slot == slot }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ═══════════════════════════════════════════
                // 👤 СИЛУЭТ ПЕРСОНАЖА С ЭКИПИРОВКОЙ
                // ═══════════════════════════════════════════
                EquipmentPanel(
                    character: $character,
                    selectedSlot: $selectedSlot
                )
                
                // ═══════════════════════════════════════════
                // 📦 ИНВЕНТАРЬ
                // ═══════════════════════════════════════════
                VStack(spacing: 12) {
                    // Заголовок с кнопкой добавления
                    HStack {
                        DSSectionHeader(title: "Инвентарь")
                            .padding(.horizontal, 0)
                        
                        Spacer()
                        
                        Button { showingAddItem = true } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                if !canEdit {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                }
                            }
                            .foregroundColor(canEdit ? Color.dsGold : Color.dsTextDim)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canEdit)                  // 🆕
                    }
                    .padding(.horizontal, 16)
                    
                    // Статистика инвентаря
                    HStack(spacing: 16) {
                        inventoryStat(
                            icon: "bag.fill",
                            label: "Предметов",
                            value: "\(character.inventory.count)"
                        )
                        inventoryStat(
                            icon: "checkmark.circle.fill",
                            label: "Экипировано",
                            value: "\(equippableItems.filter { $0.isEquipped }.count)"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Фильтр по слоту (если выбран)
                    if let slot = selectedSlot {
                        HStack {
                            Text("Фильтр: \(slot.rawValue)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.dsGold)
                            
                            Spacer()
                            
                            Button {
                                withAnimation { selectedSlot = nil }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Сбросить")
                                }
                                .font(.system(size: 11))
                                .foregroundColor(Color.dsTextDim)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.dsGold.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.dsGold.opacity(0.3), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Список предметов
                    if filteredItems.isEmpty {
                        emptyInventoryView
                    } else {
                        VStack(spacing: 0) {
                            ForEach($character.inventory) { $item in
                                InventoryItemRow(
                                    item: $item,
                                    isHighlighted: selectedSlot == item.slot,
                                    canEdit: canEdit,                    // 🆕
                                    onEdit: { editingItem = item },
                                    onDelete: {
                                        character.inventory.removeAll { $0.id == item.id }
                                        store.update(character, changed: .full)
                                    },
                                    onToggleEquip: { toggleEquip(item) },
                                    onUpdate: { store.update(character) }
                                )
                            }
                        }
                        .dsCard()
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        // Лист добавления нового предмета
        .sheet(isPresented: $showingAddItem) {
            ItemEditorView(item: InventoryItem()) { newItem in
                character.inventory.append(newItem)
                store.update(character, changed: .full)
            }
        }
        // Лист редактирования существующего предмета
        .sheet(item: $editingItem) { item in
            ItemEditorView(item: item) { updatedItem in
                let itemToSave = updatedItem
                if let index = character.inventory.firstIndex(where: { $0.id == item.id }) {
                    character.inventory[index] = itemToSave
                    store.update(character, changed: .full)  // ✅ Полная синхронизация
                }
            }
        }
    }
    
    // MARK: - Статистика инвентаря
    
    private func inventoryStat(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.dsGold)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsTextDim)
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.dsText)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.dsSurfaceAlt)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.dsBorder, lineWidth: 0.5)
        )
    }
    
    // MARK: - Пустой инвентарь
    
    private var emptyInventoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(Color.dsTextDim.opacity(0.5))
            
            Text(selectedSlot != nil ? "Нет предметов для этого слота" : "Инвентарь пуст")
                .font(.system(size: 13))
                .foregroundColor(Color.dsTextDim)
            
            if selectedSlot == nil {
                Button {
                    showingAddItem = true
                } label: {
                    HStack(spacing: 6) {
                        if !canEdit { Image(systemName: "lock.fill").font(.system(size: 9)) }
                        Text(canEdit ? "✦  Добавить первый предмет  ✦" : "🔒 Заблокировано")
                    }
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundColor(canEdit ? Color.dsBackground : Color.dsTextDim)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(canEdit ? Color.dsGold : Color.dsSurfaceAlt)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .dsCard()
        .padding(.horizontal, 16)
    }
    
    // MARK: - Надеть/Снять предмет
    
    private func toggleEquip(_ item: InventoryItem) {
        guard let index = character.inventory.firstIndex(where: { $0.id == item.id }) else { return }
        
        if item.isEquipped {
            // ✅ Снимаем предмет — но НЕ меняем slot!
            character.inventory[index].isEquipped = false
            // ❌ УБРАЛИ: character.inventory[index].slot = .none
        } else {
            // Надеваем предмет — сначала снимаем тот, что в этом слоте
            let targetSlot = item.slot
            
            if let existingIndex = character.inventory.firstIndex(where: {
                $0.slot == targetSlot && $0.isEquipped && $0.id != item.id
            }) {
                character.inventory[existingIndex].isEquipped = false
                // ✅ Тоже НЕ меняем slot у снимаемого предмета
            }
            character.inventory[index].isEquipped = true
        }
        
        store.update(character, changed: .full)
    }
}
