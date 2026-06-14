//
//  InstrumentModsTabView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct InstrumentModsTabView: View {
    @Environment(\.theme) private var theme
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    
    @State private var selectedSlot: InstrumentModificationSlot?
    @State private var showingModPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок с информацией об инструменте
            if let instrumentType = character.equippedInstrumentType {
                instrumentHeader(instrumentType)
                
                // Сетка из трёх слотов
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 12
                ) {
                    ForEach(InstrumentModificationSlot.allCases, id: \.self) { slot in
                        let modification = getModification(for: slot)
                        
                        InstrumentModSlotView(
                            instrument: instrumentType,
                            slot: slot,
                            modification: modification,
                            canEdit: canEdit,                    // 🆕
                            onTap: {
                                selectedSlot = slot
                                showingModPicker = true
                            },
                            onRemove: modification != nil ? {
                                removeModification(from: slot)
                            } : nil
                        )
                    }
                }
                .padding(.horizontal, 16)
                // Подсказка
                Text("Нажмите на слот, чтобы установить модификацию")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
                    .padding(.top, 8)
                
                // Кнопка добавления новой модификации
                Button {
                    showingModPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: canEdit ? "plus.circle.fill" : "lock.fill")
                        Text("Добавить модификацию")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(canEdit ? theme.background : theme.textDim)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(canEdit ? theme.primary : theme.surfaceAlt)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)
                .padding(.top, 8)
                
            } else {
                // Инструмент не экипирован
                emptyState
            }
        }
        .sheet(isPresented: $showingModPicker) {
            InstrumentModPickerView(
                instrument: character.equippedInstrumentType ?? .lute,
                selectedSlot: selectedSlot,
                onSelect: { modification in
                    if let slot = selectedSlot {
                        setModification(modification, to: slot)
                    }
                    showingModPicker = false
                }
            )
        }
    }
    
    // MARK: - Заголовок инструмента

    private func instrumentHeader(_ instrument: InstrumentType) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(instrument.icon)
                    .font(.system(size: 36))
                
                Text(instrument.rawValue.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .tracking(2)
                    .foregroundColor(theme.primary)
                    .multilineTextAlignment(.center)
                
                Text("Модификации")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
            }
            .frame(maxWidth: .infinity)
            
            DSdivider()
                .padding(.horizontal, 16)
        }
    }
    // MARK: - Пустое состояние
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(theme.textDim.opacity(0.3))
            
            Text("Инструмент не экипирован")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.text)
            
            Text("Возьмите инструмент в руки, чтобы использовать модификации")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    
    // MARK: - Работа с модификациями
    
    private func getModification(for slot: InstrumentModificationSlot) -> InstrumentModification? {
        guard let instrumentType = character.equippedInstrumentType else { return nil }
        return character.instrumentModifications[instrumentType]?[slot]
    }
    
    private func setModification(_ modification: InstrumentModification, to slot: InstrumentModificationSlot) {
        guard let instrumentType = character.equippedInstrumentType else { return }
        
        // ✅ Используем новый API модели вместо прямой мутации словаря
        character.setModification(modification, for: instrumentType, slot: slot)
        store.update(character)
    }
    
    private func removeModification(from slot: InstrumentModificationSlot) {
        guard let instrumentType = character.equippedInstrumentType else { return }
        
        // ✅ Используем новый API модели
        character.removeModification(for: instrumentType, slot: slot)
        store.update(character)
    }
}
