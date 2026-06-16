//
//  InstrumentModSlotView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct InstrumentModSlotView: View {
    @Environment(\.theme) private var theme
    let instrument: InstrumentType
    
    let slot: InstrumentModificationSlot
    let modification: InstrumentModification?
    let canEdit: Bool
    let onTap: () -> Void
    let onRemove: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Иконка слота с тематическим оформлением
                ZStack {
                    // Фоновый круг с цветом инструмента
                    Circle()
                        .fill(instrumentBackgroundColor)
                        .frame(width: 60, height: 60)
                    
                    // Внешнее кольцо
                    Circle()
                        .stroke(instrumentAccentColor, lineWidth: modification != nil ? 1.5 : 0.5)
                        .frame(width: 60, height: 60)
                    
                    // Содержимое
                    if let mod = modification {
                        VStack(spacing: 2) {
                            Image(systemName: slot.icon)
                                .font(.system(size: 16))
                                .foregroundColor(mod.rarity.color)
                            
                            Text(mod.name)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(mod.rarity.color)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                        }
                    } else {
                        Image(systemName: slot.icon)
                            .font(.system(size: 20))
                            .foregroundColor(theme.textDim.opacity(0.5))
                    }
                    
                    // Кнопка удаления (если есть модификация)
                    if modification != nil, let removeAction = onRemove, canEdit {  //   + canEdit
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: removeAction) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(theme.danger)
                                        .background(theme.background)
                                        .clipShape(Circle())
                                }
                                .offset(x: 6, y: -6)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Название слота
                Text(slot.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.text)
                
                // Описание слота (скрываем, если не влезает)
                Text(slot.description)
                    .font(.system(size: 8))
                    .foregroundColor(theme.textDim)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(theme.border, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canEdit)                    //  
        .opacity(canEdit ? 1.0 : 0.7)          //   чуть приглушаем
    
    }
    
    private var instrumentAccentColor: Color {
        switch instrument {
        case .lute: return theme.primary
        case .flute: return theme.tertiary
        case .drum: return theme.danger
        }
    }
    
    private var instrumentBackgroundColor: Color {
        switch instrument {
        case .lute: return theme.primary.opacity(0.08)
        case .flute: return theme.tertiary.opacity(0.08)
        case .drum: return theme.danger.opacity(0.08)
        }
    }
}
