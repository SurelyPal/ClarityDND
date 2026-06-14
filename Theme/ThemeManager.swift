//
// ThemeManager.swift
// Clarity
//

import SwiftUI
import Combine

// MARK: - Theme Manager
/// Синглтон для управления текущей темой приложения
/// Сохраняет выбор пользователя в UserDefaults
@MainActor
final class ThemeManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Published
    @Published var currentTheme: any Theme {
        didSet {
            saveThemeSelection()
        }
    }
    
    // MARK: - Available Themes
    let availableThemes: [any Theme] = [
        DarkSoulsTheme(),
        HighContrastTheme()
        // 🆕 Добавляй новые темы сюда
    ]
    
    // MARK: - Private
    private let themeKey = "selected_theme_id"
    
    // MARK: - Init
    private init() {
        // Загружаем сохранённую тему или используем дефолтную
        let savedThemeID = UserDefaults.standard.string(forKey: themeKey)
        let savedTheme = availableThemes.first { $0.id == savedThemeID }
        self.currentTheme = savedTheme ?? DarkSoulsTheme()
    }
    
    // MARK: - Public Methods
    func selectTheme(_ theme: any Theme) {
        currentTheme = theme
    }
    
    // MARK: - Private Methods
    private func saveThemeSelection() {
        UserDefaults.standard.set(currentTheme.id, forKey: themeKey)
    }
}

// MARK: - Environment Key для темы
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: any Theme = DarkSoulsTheme()
}

extension EnvironmentValues {
    var theme: any Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension для инъекции темы
extension View {
    /// Инъекция текущей темы из ThemeManager
    func injectTheme() -> some View {
        self.environment(\.theme, ThemeManager.shared.currentTheme)
    }
}