//
//  MainTabView.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import SwiftUI

/// Главный контейнер с вкладками (TabView)
/// Переключение между основными разделами приложения
struct MainTabView: View {
    @EnvironmentObject var store: CharacterStore
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedTab: Tab = .characters
    
    enum Tab: String {
        case characters = "Персонажи"
        case knowledge = "База знаний"
        case templates = "Шаблоны"
        case settings = "Настройки"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Вкладка 1: Персонажи (используем существующий ContentView)
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .tabItem {
                    Label(Tab.characters.rawValue, systemImage: "person.3.fill")
                }
                .tag(Tab.characters)
            
            // Вкладка 2: База знаний (заглушка)
            KnowledgeBaseView()
                .environmentObject(themeManager)
                .tabItem {
                    Label(Tab.knowledge.rawValue, systemImage: "books.vertical.fill")
                }
                .tag(Tab.knowledge)
            
            // Вкладка 3: Шаблоны игр
            TemplateManagementView()
                .tabItem {
                    Label(Tab.templates.rawValue, systemImage: "doc.text.fill")
                }
                .tag(Tab.templates)
            
            // Вкладка 4: Настройки
            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(themeManager.currentTheme.primary)
    }
}
