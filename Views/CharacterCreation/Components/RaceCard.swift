//
//  RaceCard.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI

/// Универсальная карточка для выбора расы/класса
struct RaceCard: View {
    @Environment(\.theme) private var theme
    let icon: String
    let name: String
    let desc: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(isSelected ? theme.primary : theme.textDim)
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? theme.primary : theme.text)
            
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(theme.textDim)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isSelected ? theme.primary.opacity(0.08) : theme.surface)
        .cornerRadius(4)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isSelected ? theme.primary : theme.border,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
                if isSelected {
                    CornerOrnaments()
                }
            }
        )
    }
}
