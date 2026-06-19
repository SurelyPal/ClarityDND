//
//  ClarityApp.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI
import SwiftData

@main
struct ClarityApp: App {
    // Создаём контейнер базы данных
    let container: ModelContainer = {
        let schema = Schema([
            DNDCharacter.self,
            FieldDefinition.self,
            FieldValue.self,           // Было FieldFieldValue.self — исправь если нужно
            GameTemplate.self,
            Mechanic.self,             // 🔽 НОВОЕ: добавляем механики
            Action.self                // 🔽 НОВОЕ: добавляем действия
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Не удалось создать ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .injectTheme()
                .onAppear {
                    // 🔽 НОВОЕ: запускаем миграцию при старте
                    runDataMigration()
                }
        }
        .modelContainer(container)  // 🔽 КРИТИЧЕСКИ ВАЖНО: подключаем контейнер
    }
    
    // MARK: - Инициализация данных
    
    /// Запускает миграцию старых данных и создаёт начальный шаблон
    private func runDataMigration() {
        let context = container.mainContext
        let migrator = DataMigrator(context: context)
        
        // Создаём шаблон D&D 5e даже если нет персонажей
        do {
            try migrator.ensureDefaultTemplateExists()
        } catch {
            print("❌ Ошибка создания шаблона: \(error)")
        }
        
        // Мигрируем старые данные если нужно
        if migrator.needsMigration() {
            do {
                try migrator.migrateAllCharacters()
                print("✅ Миграция завершена")
            } catch {
                print("❌ Ошибка миграции: \(error)")
            }
        }
    }
}
