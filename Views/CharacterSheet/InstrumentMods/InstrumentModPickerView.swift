//
//  InstrumentModPickerView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct InstrumentModPickerView: View {
    @Environment(\.theme) private var theme
    let instrument: InstrumentType
    let selectedSlot: InstrumentModificationSlot?
    let onSelect: (InstrumentModification) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text(instrument.icon)
                            .font(.system(size: 48))
                        
                        Text("МОДИФИКАЦИИ")
                            .font(.system(size: 10))
                            .tracking(3)
                            .foregroundColor(theme.textDim)
                        
                        Text(instrument.rawValue)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(theme.primary)
                        
                        DSdivider()
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Фильтр по слоту (если выбран)
                    if let slot = selectedSlot {
                        HStack {
                            Image(systemName: slot.icon)
                                .foregroundColor(theme.primary)
                            Text("Слот: \(slot.rawValue)")
                                .font(.system(size: 12))
                                .foregroundColor(theme.text)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.surface)
                        .cornerRadius(6)
                    }
                    
                    // Список модификаций
                    LazyVStack(spacing: 12) {
                        ForEach(filteredModifications) { modification in
                            InstrumentModCard(
                                modification: modification,
                                onSelect: {
                                    onSelect(modification)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Кнопка создать свою
                    Button {
                        // TODO: открыть редактор модификации
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Создать свою модификацию")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(theme.primary, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var filteredModifications: [InstrumentModification] {
        if let slot = selectedSlot {
            return InstrumentModificationLibrary.forSlot(slot)
        }
        return InstrumentModificationLibrary.all
    }
}

// MARK: - Карточка модификации

struct InstrumentModCard: View {
    @Environment(\.theme) private var theme
    let modification: InstrumentModification
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Заголовок с редкостью
                HStack {
                    Image(systemName: modification.slot.icon)
                        .foregroundColor(modification.rarity.color)
                    
                    Text(modification.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(modification.rarity.color)
                    
                    Spacer()
                    
                    Text(modification.rarity.rawValue)
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundColor(modification.rarity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(modification.rarity.color.opacity(0.15))
                        .cornerRadius(4)
                }
                
                // Описание
                Text(modification.description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.leading)
                
                // Эффект
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(theme.primary)
                        .padding(.top, 2)
                    
                    Text(modification.effect)
                        .font(.system(size: 11))
                        .foregroundColor(theme.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.primary.opacity(0.08))
                .cornerRadius(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(modification.rarity.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
