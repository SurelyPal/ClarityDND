//
//  KnowledgeBaseView.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import SwiftUI

/// Экран базы знаний (вкладка "База знаний")
/// Здесь будут правила D&D, справочники монстров, заклинаний и т.д.
struct KnowledgeBaseView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var theme: Theme {
        themeManager.currentTheme
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Иконка
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 80))
                        .foregroundColor(theme.primary.opacity(0.6))
                    
                    // Заголовок
                    Text("База знаний")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(theme.text)
                    
                    // Описание
                    Text("Здесь скоро появятся:\n• Правила D&D 5e\n• Справочник монстров\n• Заклинания\n• Предметы и артефакты")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(theme.text)
                        .padding(.horizontal, 32)
                    
                    // Бейдж "Скоро"
                    Text("В разработке")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(theme.primary.opacity(0.2))
                        )
                        .foregroundColor(theme.primary)
                        .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle("База знаний")
        }
    }
}
