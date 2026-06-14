//
//  Theme.swift
//  Clarity
//
//  Created by KEBAB on 14.06.2026.
//

import SwiftUI

// MARK: - Протокол темы
/// Описывает все визуальные параметры темы (цвета, текстуры)
/// Для добавления новой темы — создай структуру, соответствующую этому протоколу
protocol Theme {
    var id: String { get }
    var name: String { get }
    
    // MARK: - Основные цвета
    var background: Color { get }
    var surface: Color { get }
    var surfaceAlt: Color { get }
    
    // MARK: - Акцентные цвета
    var primary: Color { get }        // Gold (основной акцент)
    var primaryDim: Color { get }     // GoldDim (приглушённый)
    var secondary: Color { get }      // Estus Green
    var tertiary: Color { get }       // Soul Teal
    
    // MARK: - Семантические цвета
    var danger: Color { get }
    var dangerDim: Color { get }
    var info: Color { get }
    
    // MARK: - Границы
    var border: Color { get }
    var borderBright: Color { get }
    
    // MARK: - Текст
    var text: Color { get }
    var textDim: Color { get }
    var anotherText: Color { get }
    
    // MARK: - Текстуры (будущее расширение)
    /// Опциональная текстура для фона (пока nil для всех тем)
    var backgroundTexture: Image? { get }
}

// MARK: - Расширение для дефолтных значений
extension Theme {
    var backgroundTexture: Image? { nil } // 🆕 По умолчанию текстур нет
}

// MARK: - Dark Souls Theme (дефолтная)
struct DarkSoulsTheme: Theme {
    let id = "classic"
    let name = "Classic"
    
    // MARK: - Основные цвета
    let background = Color(red: 0.05, green: 0.07, blue: 0.12)
    let surface = Color(red: 0.08, green: 0.11, blue: 0.18)
    let surfaceAlt = Color(red: 0.11, green: 0.15, blue: 0.24)
    
    // MARK: - Акцентные цвета
    let primary = Color(red: 0.85, green: 0.68, blue: 0.23)
    let primaryDim = Color(red: 0.55, green: 0.43, blue: 0.15)
    let secondary = Color(red: 0.56, green: 0.66, blue: 0.36) // Estus Green
    let tertiary = Color(red: 0.42, green: 0.56, blue: 0.56)  // Soul Teal
    
    // MARK: - Семантические цвета
    let danger = Color(red: 0.60, green: 0.20, blue: 0.35)
    let dangerDim = Color(red: 0.75, green: 0.18, blue: 0.18).opacity(0.25)
    let info = Color(red: 0.20, green: 0.35, blue: 0.65)
    
    
    // MARK: - Границы
    let border = Color(red: 0.85, green: 0.68, blue: 0.28).opacity(0.25)
    let borderBright = Color(red: 0.85, green: 0.68, blue: 0.28).opacity(0.6)
    
    // MARK: - Текст
    let text = Color(red: 0.88, green: 0.82, blue: 0.68)
    let textDim = Color(red: 0.55, green: 0.50, blue: 0.40)
    let anotherText = Color(red: 0.89, green: 0.82, blue: 0.68)
}

// MARK: - Пример второй темы (для демонстрации)
struct HighContrastTheme: Theme {
    let id = "high-contrast"
    let name = "High Contrast"
    
    let background = Color.black
    let surface = Color(white: 0.1)
    let surfaceAlt = Color(white: 0.15)
    
    let primary = Color.yellow
    let primaryDim = Color.orange
    let secondary = Color.green
    let tertiary = Color.cyan
    
    let danger = Color.red
    let dangerDim = Color.red.opacity(0.3)
    let info = Color.blue
    
    let border = Color.white.opacity(0.3)
    let borderBright = Color.white.opacity(0.7)
    
    let text = Color.white
    let textDim = Color.gray
    let anotherText = Color.white
}

// MARK: - Тема: Тайная Библиотека (Arcane Library)
struct ArcaneLibraryTheme: Theme {
    let id = "arcane-library"
    let name = "Тайная Библиотека"
    
    // MARK: - Основные цвета (Глубокий индиго)
    let background = Color(red: 0.06, green: 0.08, blue: 0.14)      // #0F1424
    let surface = Color(red: 0.10, green: 0.13, blue: 0.22)         // #1A2138
    let surfaceAlt = Color(red: 0.14, green: 0.18, blue: 0.30)      // #242E4D
    
    // MARK: - Акцентные цвета (Магический циан и мистические оттенки)
    let primary = Color(red: 0.30, green: 0.75, blue: 0.75)         // #4DBFBF (Arcane Cyan)
    let primaryDim = Color(red: 0.15, green: 0.45, blue: 0.50)      // #267380 (Muted Cyan)
    let secondary = Color(red: 0.30, green: 0.65, blue: 0.40)       // #4DA666 (Druidic Green)
    let tertiary = Color(red: 0.60, green: 0.55, blue: 0.80)        // #998CCC (Soft Lavender)
    
    // MARK: - Семантические цвета (Благородный красный и магический синий)
    let danger = Color(red: 0.80, green: 0.20, blue: 0.35)          // #CC3359 (Crimson)
    let dangerDim = Color(red: 0.80, green: 0.20, blue: 0.35).opacity(0.25)
    let info = Color(red: 0.25, green: 0.45, blue: 0.85)            // #4073D9
    
    // MARK: - Границы
    let border = Color(red: 0.30, green: 0.75, blue: 0.75).opacity(0.25)
    let borderBright = Color(red: 0.30, green: 0.75, blue: 0.75).opacity(0.6)
    
    // MARK: - Текст (Тёплый пергамент и приглушённый)
    let text = Color(red: 0.92, green: 0.94, blue: 0.96)            // #EBF0F5
    let textDim = Color(red: 0.55, green: 0.60, blue: 0.70)         // #8C99B3
    let anotherText = Color(red: 0.89, green: 0.91, blue: 0.93)     // #E3E8EE
}
