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
    
    init() {
        print("🚀 Приложение запускается...")
        _ = CampaignManager.shared
        print("✅ CampaignManager инициализирован")
    }
    
    var body: some Scene {
        WindowGroup {
            //Запускаем RootView вместо ContentView
            RootView()
            
        }
        .modelContainer(for: DNDCharacter.self)
        
    }
}
