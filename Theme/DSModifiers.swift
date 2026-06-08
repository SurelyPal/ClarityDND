//
//  DSModifiers.swift
//  Clarity
//

import SwiftUI

// MARK: - Модификаторы карточек
struct DSCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.dsSurface)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.dsBorder, lineWidth: 1)
            )
    }
}

struct DSInnerCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.dsSurfaceAlt)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.dsBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - Расширения View
extension View {
    func dsCard() -> some View { modifier(DSCardStyle()) }
    func dsInnerCard() -> some View { modifier(DSInnerCardStyle()) }
}
