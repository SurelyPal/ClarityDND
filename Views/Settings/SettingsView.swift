//
//  SettingsView.swift
//  Clarity
//
//  Created by KEBAB on 14.06.2026.
//


//
// SettingsView.swift
// Clarity
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Environment
    @Environment(\.theme) private var theme //Получаем тему
    
    // MARK: - Body
    var body: some View {
        ZStack {
            theme.background // 🔧 Используем тему
                .ignoresSafeArea()
            
            List {
                
                // MARK: - Секция: Внешний вид
                Section {
                    NavigationLink(destination: ThemeSettingsView()) {
                        SettingsRow(
                            icon: "paintbrush.fill",
                            iconColor: theme.primary, // Используем тему
                            title: "Темы",
                            subtitle: "Оформление и цвета"
                        )
                    }
                    .listRowBackground(theme.surface) // 🔧 Используем тему
                } header: {
                    Text("Внешний вид")
                        .foregroundColor(theme.primaryDim) // 🔧 Используем тему
                }
                
                // MARK: - Секция: О приложении
                Section {
                    SettingsRow(
                        icon: "info.circle.fill",
                        iconColor: theme.info, // 🔧 Используем тему
                        title: "О приложении",
                        subtitle: "Версия 1.0"
                    )
                    .listRowBackground(theme.surface) // 🔧 Используем тему
                    
                    SettingsRow(
                        icon: "book.fill",
                        iconColor: theme.secondary, // 🔧 Используем тему
                        title: "Руководство",
                        subtitle: "Как играть"
                    )
                    .listRowBackground(theme.surface) // 🔧 Используем тему
                } header: {
                    Text("Информация")
                        .foregroundColor(theme.primaryDim) // 🔧 Используем тему
                }
                
            }
            #if os(macOS) //   Кроссплатформенность
            .listStyle(.bordered)
            #else
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden) // ✅ Скрываем стандартный фон
            .background(theme.background) // 🔧 Используем тему
            }
        .navigationTitle("Настройки")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Строка настроек
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    @Environment(\.theme) private var theme //   Получаем тему
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor) // 🔧 Используем переданный цвет
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.text) // 🔧 Используем тему
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim) // 🔧 Используем тему
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textDim) // 🔧 Используем тему
        }
        .padding(.vertical, 4)
    }
}
