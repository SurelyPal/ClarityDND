//
//  CharacterHeaderSection.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//
import SwiftUI

struct CharacterHeaderSection: View, Equatable {
    @Binding var character: DNDCharacter
    let canEdit: Bool
    let onLevelUp: () -> Void
    
    // 🆕 Сравнение для оптимизации redraw
    static func == (lhs: CharacterHeaderSection, rhs: CharacterHeaderSection) -> Bool {
        lhs.character.name == rhs.character.name &&
        lhs.character.race == rhs.character.race &&
        lhs.character.characterClass == rhs.character.characterClass &&
        lhs.character.level == rhs.character.level &&
        lhs.character.instrument == rhs.character.instrument &&
        lhs.character.alignment == rhs.character.alignment &&
        lhs.character.avatarData == rhs.character.avatarData &&
        lhs.canEdit == rhs.canEdit
    }
    
    var body: some View {
        VStack(spacing: 14) {
            AvatarView(avatarData: character.avatarData, race: character.race, size: 90)
            
            Text(character.displayName.uppercased())
                .font(.system(size: 22, weight: .light))
                .tracking(3)
                .foregroundColor(Color.dsGold)
            
            HStack(spacing: 8) {
                DSBadge(text: character.race.rawValue, color: .dsBlue)
                DSBadge(text: character.characterClass.rawValue, color: .dsGoldDim)
                DSBadge(text: "ВЕХА \(character.level)", color: .dsRed)
                
                if let instrumentName = character.instrument,
                   let type = InstrumentType.from(name: instrumentName) {
                    HStack(spacing: 4) {
                        Image(systemName: type.sfSymbol)
                            .font(.system(size: 9))
                        Text(instrumentName)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(type.accentColor.opacity(0.12))
                    .foregroundColor(type.accentColor)
                    .cornerRadius(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(type.accentColor.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
            
            Text(character.alignment.rawValue.uppercased())
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(Color.dsTextDim)
            
            DSdivider().padding(.horizontal, 30)
            
            if !character.isMaxLevel {
                Button(action: { withAnimation(.spring(response: 0.4)) { onLevelUp() } }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.system(size: 12))
                        Text("Повысить веху")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1)
                        
                        // 🆕 Замок если заблокировано
                        if !canEdit {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                        }
                    }
                    .foregroundColor(canEdit ? Color.dsBackground : Color.dsTextDim)
                     .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(canEdit ? Color.dsGold : Color.dsSurfaceAlt)
                    .cornerRadius(3)
                }
                 .buttonStyle(.plain)
                .disabled(!canEdit)                    // 🆕 Блокируем
                .padding(.top, 8)
            }
        }
        .padding(.top, 16)
    }
}

