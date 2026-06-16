//
//  ThemeSettingsView.swift
//  Clarity
//
//  Created by KEBAB on 14.06.2026.
//

import SwiftUI

struct ThemeSettingsView: View {
    
    // MARK: - Environment
    @Environment(\.theme) private var theme //   Получаем текущую тему
    @EnvironmentObject private var themeManager: ThemeManager //   Менеджер тем
    
    // MARK: - Body
    var body: some View {
        ZStack {
            theme.background // 🔧 Используем тему
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // Заголовок секции
                    headerView
                    
                    // Список тем
                    themeList
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
        }
        .navigationTitle("Темы")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 4) {
            Text("✦ ТЕМЫ ✦")
                .font(.system(size: 11, weight: .medium))
                .tracking(3)
                .foregroundColor(theme.primaryDim) // 🔧 Используем тему
            
            Text("Выберите оформление")
                .font(.system(size: 13))
                .foregroundColor(theme.textDim) // 🔧 Используем тему
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    //Используем enumerated(), чтобы компилятор работал с конкретными индексами (Int),
    // а не пытался вывести типы для абстрактного 'any Theme'
    private var themeList: some View {
        ForEach(Array(themeManager.availableThemes.enumerated()), id: \.element.id) { index, theme in
            themeRow(for: theme)
        }
    }
    
    //   Выносим логику строки в отдельную функцию
    @ViewBuilder
    private func themeRow(for theme: Theme) -> some View {
        let isSelected = theme.id == themeManager.currentTheme.id
        
        ThemeCardView(theme: theme, isSelected: isSelected)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    themeManager.selectTheme(id: theme.id) // 🔧 Исправлен вызов метода
                }
            }
    }}

// MARK: - Карточка темы
struct ThemeCardView: View {
    
    let theme: Theme
    let isSelected: Bool
    
    @Environment(\.theme) private var currentTheme //   Для сравнения
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Заголовок темы
            HStack {
                Text(theme.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.text) // 🔧 Используем тему самой темы
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary) // 🔧 Используем тему
                }
            }
            
            // Превью цветов
            HStack(spacing: 8) {
                ColorPreview(color: theme.background, label: "Фон")
                ColorPreview(color: theme.surface, label: "Поверхность")
                ColorPreview(color: theme.primary, label: "Золото")
                ColorPreview(color: theme.danger, label: "Красный")
                ColorPreview(color: theme.text, label: "Текст")
            }
            
            // Описание
            Text(isSelected ? "✓ Активная тема" : "Нажмите чтобы применить")
                .font(.system(size: 11))
                .foregroundColor(theme.textDim) // 🔧 Используем тему
        }
        .padding(12)
        .background(theme.surface) // 🔧 Используем тему
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? theme.primary : theme.border, lineWidth: isSelected ? 2 : 1) // 🔧 Используем тему
        )
    }
}

// MARK: - Превью цвета
struct ColorPreview: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
