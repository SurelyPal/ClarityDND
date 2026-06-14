//
//  DSColors.swift
//  Clarity
//

import SwiftUI

// MARK: - Цветовая палитра
// MARK: - Цветовая палитра (теперь использует ThemeManager)
extension Color {
    // 🔧 Динамические цвета из текущей темы
    static var dsBackground: Color { ThemeManager.shared.currentTheme.background }
    static var dsSurface: Color { ThemeManager.shared.currentTheme.surface }
    static var dsSurfaceAlt: Color { ThemeManager.shared.currentTheme.surfaceAlt }
    
    static var dsGold: Color { ThemeManager.shared.currentTheme.primary }
    static var dsGoldDim: Color { ThemeManager.shared.currentTheme.primaryDim }
    static var dsEstus: Color { ThemeManager.shared.currentTheme.secondary }
    static var dsSoul: Color { ThemeManager.shared.currentTheme.tertiary }
    
    static var dsRed: Color { ThemeManager.shared.currentTheme.danger }
    static var dsRedDim: Color { ThemeManager.shared.currentTheme.dangerDim }
    static var dsBlue: Color { ThemeManager.shared.currentTheme.info }
    
    static var dsBorder: Color { ThemeManager.shared.currentTheme.border }
    static var dsBorderBright: Color { ThemeManager.shared.currentTheme.borderBright }
    
    static var dsText: Color { ThemeManager.shared.currentTheme.text }
    static var dsTextDim: Color { ThemeManager.shared.currentTheme.textDim }
}
