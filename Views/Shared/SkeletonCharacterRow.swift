//
//  SkeletonCharacterRow.swift
//  Clarity
//
//  Created by KEBAB on 08.06.2026.
//

import SwiftUI

/// Skeleton для карточки персонажа в списке выбора
struct SkeletonCharacterRow: View {
    @Environment(\.theme) private var theme
    var body: some View {
        HStack(spacing: 12) {
            // Аватар
            SkeletonCircle(size: 48)
            
            // Информация о персонаже
            VStack(alignment: .leading, spacing: 6) {
                // Имя
                SkeletonLoader(width: 120, height: 14)
                
                // Раса · Класс · Уровень
                SkeletonLoader(width: 180, height: 10)
            }
            
            Spacer()
            
            // HP
            VStack(alignment: .trailing, spacing: 6) {
                // HP значение
                HStack(spacing: 4) {
                    SkeletonLoader(width: 8, height: 9, cornerRadius: 2)
                    SkeletonLoader(width: 40, height: 11)
                }
                
                // Круг выбора
                SkeletonCircle(size: 20)
            }
        }
        .padding(12)
        .background(theme.surfaceAlt.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.border.opacity(0.3), lineWidth: 0.5)
        )
        .cornerRadius(6)
    }
}

#Preview {
    @Environment(\.theme) var theme
    VStack(spacing: 12) {
        SkeletonCharacterRow()
        SkeletonCharacterRow()
        SkeletonCharacterRow()
    }
    .padding()
    .background(theme.background)
    .preferredColorScheme(.dark)
}
