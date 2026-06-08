//
//  RaceCard.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI

/// Универсальная карточка для выбора расы/класса
struct RaceCard: View {
    let icon: String
    let name: String
    let desc: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(isSelected ? Color.dsGold : Color.dsTextDim)
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color.dsGold : Color.dsText)
            
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(Color.dsTextDim)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isSelected ? Color.dsGold.opacity(0.08) : Color.dsSurface)
        .cornerRadius(4)
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isSelected ? Color.dsGold : Color.dsBorder,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
                if isSelected {
                    CornerOrnaments()
                }
            }
        )
    }
}
