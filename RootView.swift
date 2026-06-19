//
// RootView.swift
// Clarity
//
// Created by KEBAB on 10.06.2026.
//

import SwiftUI
import SwiftData

// MARK: - Корневой экран (объединяет AppRootView + RootView)
/// Создаёт CharacterStore, управляет database recovery, размещает глобальный PartyStatusIndicator
// MARK: - Recovery States (глобальный enum для DatabaseRecoveryView)
enum RecoveryState: Equatable {
    case healthy
    case recoveredFromBackup(backupURL: URL)
    case inMemoryFallback
    case failed(String)
}

struct RootView: View {
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    @State private var store: CharacterStore?
    @State private var recoveryState: RecoveryState = .healthy
    @State private var showRecoverySheet = false
 
    // 🆕 Theme Manager
    @StateObject private var themeManager = ThemeManager.shared
    
    // MARK: - Body
    var body: some View {
        
        ZStack {
            // Фон в стиле Dark Souls
            themeManager.currentTheme.background // 🔧 Динамический цвет
                .ignoresSafeArea()
            
            if let store = store {
                //Как только store создан — показываем MainTabView
                // и передаём store + PartyManager + ThemeManager в Environment
                MainTabView()
                    .environmentObject(store)
                    .environmentObject(PartyManager.shared)
                    .environmentObject(themeManager) //Инъекция темы
                    .injectTheme() //Инъекция через EnvironmentValues
            } else {
                // Экран загрузки (показывается долю секунды при старте)
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.dsGold)
                        .scaleEffect(1.5)
                    
                    Text("Открываем книгу судеб...")
                        .font(.system(size: 14))
                        .foregroundColor(.dsTextDim)
                        .tracking(1)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            //Глобальный индикатор статуса партии поверх ВСЕХ экранов
            if store != nil {
                PartyStatusIndicator()
                    .padding(.trailing, 16)
                    .safeAreaPadding(.top, 47)  
            }
        }
        .onAppear {
            initializeStore()
        }
        .sheet(isPresented: $showRecoverySheet) {
            DatabaseRecoveryView(state: recoveryState)  // ✅ Передаём напрямую
                .interactiveDismissDisabled()
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Initialization
    private func initializeStore() {
        // Пытаемся инициализировать store с database recovery
        
            // Попытка 1: используем существующий modelContext
            let newStore = CharacterStore(context: modelContext)
            store = newStore
            recoveryState = .healthy
            print("✅ CharacterStore создан успешно")
        
    // Показываем recovery sheet если нужно
        if case .healthy = recoveryState {
            // Всё ок, ничего не делаем
        } else {
            showRecoverySheet = true
        }
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .modelContainer(for: DNDCharacter.self)
}
