//
//  InventoryTabView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct InventoryTabView: View {
    @Environment(\.theme) private var theme
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    
    @State private var editingItem: InventoryItem? = nil
    @State private var showingAddItem = false
    @State private var selectedSlot: EquipmentSlot? = nil
    @State private var itemToTransfer: InventoryItem?
    @State private var isShowingGoldTransfer = false // 🆕 Для листа передачи золота
    
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
                            .foregroundColor(canEdit ? theme.primary : theme.textDim)
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
                        inventoryStat(
                            icon: "dollarsign.circle.fill",
                            label: "Золотые",
                            value: "\(character.money)",
                            showTransferButton: canEdit,
                            onTransferTap: { isShowingGoldTransfer = true } // 🆕
                        )
                    }
                    .padding(.horizontal, 8)
                    
                    // Фильтр по слоту (если выбран)
                    if let slot = selectedSlot {
                        HStack {
                            Text("Фильтр: \(slot.rawValue)")
                                .font(.system(size: 12))
                                .foregroundColor(theme.primary)
                            
                            Spacer()
                            
                            Button {
                                withAnimation { selectedSlot = nil }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Сбросить")
                                }
                                .font(.system(size: 11))
                                .foregroundColor(theme.textDim)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(theme.primary.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.primary.opacity(0.3), lineWidth: 0.5)
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
                                    canEdit: canEdit,
                                    onEdit: { editingItem = item },
                                    onDelete: {
                                        character.inventory.removeAll { $0.id == item.id }
                                        store.update(character, changed: .full)
                                    },
                                    onToggleEquip: { toggleEquip(item) },
                                    onUpdate: { store.update(character) },
                                    onTransfer: { itemToTransfer in // 🆕
                                        self.itemToTransfer = item
                                    }
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
                    store.update(character, changed: .full)
                }
            }
        }
        // 🆕 Лист передачи предмета (открывается, когда itemToTransfer не nil)
        .sheet(item: $itemToTransfer) { item in
            TransferItemSheet(item: item) { selectedMember in
                executeItemTransfer(item: item, to: selectedMember)
            }
        }
        // 🆕 Лист передачи золота
            .sheet(isPresented: $isShowingGoldTransfer) {
                TransferGoldSheet(currentGold: character.money) { selectedMember, amount in
                    executeGoldTransfer(amount: amount, to: selectedMember)
                }
            }
    }
    
// MARK: - Статистика инвентаря
    
    private func inventoryStat(
        icon: String,
        label: String,
        value: String,
        showTransferButton: Bool = false, // 🆕 Параметр для кнопки передачи
        onTransferTap: (() -> Void)? = nil // 🆕 Замыкание для кнопки передачи
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(theme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                                .font(.system(size: 10))
                                .foregroundColor(theme.textDim)
                                .fixedSize(horizontal: false, vertical: true) // ✅ Разрешаем перенос текста
                                .lineLimit(2) // ✅ Максимум 2 строки
                            
                            Text(value)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.text)
                                .fixedSize(horizontal: false, vertical: true) // ✅ Разрешаем перенос текста
                                .lineLimit(2) // ✅ Максимум 2 строки
            }

            Spacer()
            
            // 🆕 Кнопка передачи золота (появляется слева от +/-)
            if showTransferButton, let onTransfer = onTransferTap {
                Button(action: onTransfer) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.primary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            
            // ✅ Кнопки +/- только для золота
            // 🔧 Исправлено: label == "Золотые" (ранее было "Золото" — не срабатывало)
           
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(theme.surfaceAlt)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border, lineWidth: 0.5)
        )
    }
    
// MARK: - Пустой инвентарь
    
    private var emptyInventoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 32))
                .foregroundColor(theme.textDim.opacity(0.5))
            
            Text(selectedSlot != nil ? "Нет предметов для этого слота" : "Инвентарь пуст")
                .font(.system(size: 13))
                .foregroundColor(theme.textDim)
            
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
                        .foregroundColor(canEdit ? theme.background : theme.textDim)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(canEdit ? theme.primary : theme.surfaceAlt)
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
// MARK: - Передача/Удаление

    // 🆕 Выполняет передачу предмета после выбора игрока в TransferItemSheet
    private func executeItemTransfer(item: InventoryItem, to member: PartyMember) {
        guard PartyManager.shared.role == .player,
              let myCharacter = PartyManager.shared.selectedCharacter else {
            return
        }
        
        guard let index = character.inventory.firstIndex(where: { $0.id == item.id }) else { return }
        
        // 🔧 КРИТИЧНО: Выключаем экипировку ПЕРЕД передачей, чтобы не было багов
        character.inventory[index].isEquipped = false
        
        let itemToSend = character.inventory[index]
        character.inventory.remove(at: index)
        store.update(character, changed: .full)
        
        let message = PartyMessage.itemTransfer(
            item: itemToSend,
            fromCharacterID: myCharacter.id,
            fromCharacterName: myCharacter.displayName,
            toCharacterID: member.id
        )
        PartyManager.shared.send(message)
        
        print("📤 Предмет '\(itemToSend.name)' передан игроку \(member.name)")
    }

    // 🆕 Выполняет передачу золота после выбора игрока и суммы
    private func executeGoldTransfer(amount: Int, to member: PartyMember) {
        guard amount > 0, character.money >= amount else { return }
        
        character.money -= amount
        store.update(character, changed: .full)
        
        let message = PartyMessage.goldTransfer(
            amount: amount,
            fromCharacterID: character.id,
            fromCharacterName: character.displayName,
            toCharacterID: member.id
        )
        PartyManager.shared.send(message)
        
        print("💰 Передано \(amount) золота игроку \(member.name)")
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



//MARK: 🆕 Лист для передачи золота
struct TransferGoldSheet: View {
    @Environment(\.theme) private var theme
    let currentGold: Int
    @EnvironmentObject var partyManager: PartyManager
    @Environment(\.dismiss) var dismiss
    
    let onTransfer: (PartyMember, Int) -> Void
    
    @State private var selectedPlayerID: UUID?
    @State private var amountText: String = ""
    
    var amount: Int? { Int(amountText.trimmingCharacters(in: .whitespaces)) }
    var isValid: Bool {
        guard let amt = amount else { return false }
        return amt > 0 && amt <= currentGold && selectedPlayerID != nil
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("✦ ПЕРЕДАТЬ ЗОЛОТО ✦")
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundColor(theme.primary)
            
            Text("Доступно: \(currentGold)")
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
            
            DSdivider().padding(.horizontal, 40)
            
            // ✅ ИСПРАВЛЕНО: убраны все лишние пробелы в модификаторах
                        TextField("Сумма", text: $amountText)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(theme.primary)
                            .padding()
                            .background(theme.surface)
                            .cornerRadius(8)
                            .padding(.horizontal, 40)
            
            Text("Выберите игрока:")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
            
            ScrollView {
                VStack(spacing: 8) {
                    let currentCharacterID = partyManager.selectedCharacter?.id
                    ForEach(partyManager.partyMembers.filter { member in
                        member.isConnected && member.id != currentCharacterID
                    }) { member in
                        Button {
                            selectedPlayerID = member.id
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.primary)
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.text)
                                    Text("\(member.characterClass) • Уровень \(member.level)")
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.textDim)
                                }
                                Spacer()
                                if selectedPlayerID == member.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(theme.primary)
                                }
                            }
                            .padding(12)
                            .background(theme.surface)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedPlayerID == member.id ? theme.primary : theme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Button {
                if isValid, let targetID = selectedPlayerID,
                   let member = partyManager.partyMembers.first(where: { $0.id == targetID }),
                   let amt = amount {
                    onTransfer(member, amt)
                    dismiss()
                }
            } label: {
                Text("ПЕРЕДАТЬ")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isValid ? theme.primary : theme.surfaceAlt)
                    .foregroundColor(isValid ? theme.background : theme.textDim)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .disabled(!isValid)
        }
        .padding(.vertical, 24)
        .background(theme.background)
        .presentationDetents([.medium, .large])
        // 🔧 Кроссплатформенное скрытие клавиатуры
        .onTapGesture {
#if os(iOS)
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
#endif
        }
    }
}
    
