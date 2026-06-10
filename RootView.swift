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
 
    // MARK: - Body
    var body: some View {
        ZStack {
            // Фон в стиле Dark Souls
            Color.dsBackground
                .ignoresSafeArea()
            
            if let store = store {
                // ✅ Как только store создан — показываем ContentView
                // и передаём store + PartyManager в Environment для ВСЕХ дочерних экранов
                ContentView()
                    .environmentObject(store)
                    .environmentObject(PartyManager.shared)
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
            // ✅ Глобальный индикатор статуса партии поверх ВСЕХ экранов
            if store != nil {
                PartyStatusIndicator()
                    .padding(.trailing, 16)
                    .padding(.top, 8)
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
        do {
            // Попытка 1: используем существующий modelContext
            let newStore = CharacterStore(context: modelContext)
            store = newStore
            recoveryState = .healthy
            print("✅ CharacterStore создан успешно")
            
        } catch {
            print("⚠️ SwiftData: не удалось загрузить БД (\(error))")
            
            // 🆕 ШАГ 1: Создаём backup ПЕРЕД удалением
            let backupURL = DatabaseRecovery.createBackup()
            
            // 🆕 ШАГ 2: Удаляем повреждённую БД
            DatabaseRecovery.deleteCorruptDatabase()
            
            // 🆕 ШАГ 3: Создаём новую БД
            do {
                let container = try ModelContainer(
                    for: DNDCharacter.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
                )
                let newStore = CharacterStore(context: container.mainContext)
                store = newStore
                
                recoveryState = backupURL != nil
                    ? .recoveredFromBackup(backupURL: backupURL!)
                    : .failed("Backup не создан")
                
                print("✅ БД восстановлена")
                
            } catch {
                // Последний шанс: in-memory БД
                print("❌ Критическая ошибка: \(error). Используем in-memory БД.")
                
                do {
                    let container = try ModelContainer(
                        for: DNDCharacter.self,
                        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                    )
                    let newStore = CharacterStore(context: container.mainContext)
                    store = newStore
                    recoveryState = .inMemoryFallback
                    
                } catch {
                    recoveryState = .failed("Не удалось создать даже in-memory БД: \(error.localizedDescription)")
                }
            }
        }
        
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
