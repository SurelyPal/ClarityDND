//
//  InstrumentModPickerView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct InstrumentModPickerView: View {
    let instrument: InstrumentType
    let selectedSlot: InstrumentModificationSlot?
    let onSelect: (InstrumentModification) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text(instrument.icon)
                            .font(.system(size: 48))
                        
                        Text("МОДИФИКАЦИИ")
                            .font(.system(size: 10))
                            .tracking(3)
                            .foregroundColor(Color.dsTextDim)
                        
                        Text(instrument.rawValue)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Color.dsGold)
                        
                        DSdivider()
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 20)
                    
                    // Фильтр по слоту (если выбран)
                    if let slot = selectedSlot {
                        HStack {
                            Image(systemName: slot.icon)
                                .foregroundColor(Color.dsGold)
                            Text("Слот: \(slot.rawValue)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.dsText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.dsSurface)
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
                        .foregroundColor(Color.dsGold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.dsGold, lineWidth: 1)
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
                    .foregroundColor(Color.dsText)
                    .multilineTextAlignment(.leading)
                
                // Эффект
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsGold)
                        .padding(.top, 2)
                    
                    Text(modification.effect)
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsGold)
                        .multilineTextAlignment(.leading)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dsGold.opacity(0.08))
                .cornerRadius(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.dsSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(modification.rarity.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
