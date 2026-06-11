//
//  CharacterInfoView.swift
//  Clarity
//
//  Created by KEBAB on 11.06.2026.
//


import SwiftUI
import SwiftData

struct CharacterInfoView: View {
    @Bindable var character: DNDCharacter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Заголовок
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(Color.dsGold)
                
                Text(character.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.dsText)
                
                Text("\(character.race.rawValue) • \(character.characterClass.rawValue) • \(character.level) ур.")
                    .font(.subheadline)
                    .foregroundColor(Color.dsTextDim)
            }
            
            DSdivider() // Твой кастомный разделитель, или используй Divider()
            
            // Блок информации о кампании
            VStack(spacing: 12) {
                Text("Информация о партии")
                    .font(.headline)
                    .foregroundColor(Color.dsGold)
                    .tracking(1)
                
                if let campName = character.campaignName, let campID = character.campaignID {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundColor(Color.dsGoldDim)
                            Text(campName)
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        
                        HStack(spacing: 8) {
                            Image(systemName: "number")
                                .foregroundColor(Color.dsTextDim)
                            Text("ID кампании:")
                                .foregroundColor(Color.dsTextDim)
                            Text(campID.uuidString)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(Color.dsGold)
                                .textSelection(.enabled) // ✅ Позволяет выделить и скопировать ID на Mac/iOS
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.dsSurface)
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(Color.dsTextDim)
                        Text("Персонаж не привязан к партии")
                            .font(.subheadline)
                            .foregroundColor(Color.dsTextDim)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding()
            .background(Color.dsSurface)
            .cornerRadius(12)
            
            Spacer()
            
            // Кнопка закрытия
            Button(action: { dismiss() }) {
                Text("Закрыть")
                    .font(.headline)
                    .foregroundColor(Color.dsBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dsGold)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color.dsBackground)
        .presentationDetents([.medium]) // Красивый sheet на iOS
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    // Preview отключён — требует реальный DNDCharacter из SwiftData
    Text("Preview disabled")
}
