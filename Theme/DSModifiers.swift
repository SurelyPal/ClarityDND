//
//  DSModifiers.swift
//  Clarity
//

import SwiftUI

// MARK: - Модификаторы карточек (теперь используют Environment theme)
struct DSCardStyle: ViewModifier {
    @Environment(\.theme) private var theme // 🆕 Получаем тему из Environment
    
    func body(content: Content) -> some View {
        content
            .background(theme.surface) // 🔧 Используем тему
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(theme.border, lineWidth: 1) // 🔧
            )
    }
}

struct DSInnerCardStyle: ViewModifier {
    @Environment(\.theme) private var theme // 🆕
    
    func body(content: Content) -> some View {
        content
            .background(theme.surfaceAlt) // 🔧
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(theme.border, lineWidth: 0.5) // 🔧
            )
    }
}

// MARK: - Расширения View
extension View {
    func dsCard() -> some View { modifier(DSCardStyle()) }
    func dsInnerCard() -> some View { modifier(DSInnerCardStyle()) }
}
