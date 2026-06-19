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

    var body: some Scene {
        WindowGroup {
            RootView()
                .injectTheme()
        }
        let container: ModelContainer = {
            let schema = Schema([
                DNDCharacter.self,
                FieldDefinition.self,  // Фаза 1
                FieldValue.self,       // Фаза 1
                GameTemplate.self      // Фаза 1
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()
    }
}

