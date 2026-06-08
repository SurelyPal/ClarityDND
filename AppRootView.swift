//
//  AppRootView.swift
//  Clarity
//

import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var store: CharacterStore
    @State private var recoveryState: RecoveryState = .healthy
    @State private var showRecoverySheet = false
    
    // 🆕 Состояния восстановления
    enum RecoveryState: Equatable {
        case healthy
        case recoveredFromBackup(backupURL: URL)
        case inMemoryFallback
        case failed(String)
    }
    
    init() {
        let container: ModelContainer
        var state: RecoveryState = .healthy
        
        do {
            // Попытка 1: загрузить существующую БД
            container = try ModelContainer(
                for: DNDCharacter.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            print("⚠️ SwiftData: не удалось загрузить БД (\(error))")
            
            // 🆕 ШАГ 1: Создаём backup ПЕРЕД удалением
            let backupURL = DatabaseRecovery.createBackup()
            
            // 🆕 ШАГ 2: Удаляем повреждённую БД
            DatabaseRecovery.deleteCorruptDatabase()
            
            // 🆕 ШАГ 3: Создаём новую БД
            do {
                container = try ModelContainer(
                    for: DNDCharacter.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: false)
                )
                state = backupURL != nil
                    ? .recoveredFromBackup(backupURL: backupURL!)
                    : .failed("Backup не создан")
            } catch {
                // Последний шанс: in-memory БД
                print("❌ Критическая ошибка: \(error). Используем in-memory БД.")
                container = try! ModelContainer(
                    for: DNDCharacter.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
                state = .inMemoryFallback
            }
        }
        
        _store = StateObject(
            wrappedValue: CharacterStore(context: container.mainContext)
        )
        _recoveryState = State(initialValue: state)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ContentView()
                .environmentObject(store)
                .environmentObject(PartyManager.shared)
            PartyStatusIndicator()
                .padding(.trailing, 16)
                .padding(.top, 50)
                .zIndex(999)
        }
        .onAppear {
            store.attachContext(context)
            
            // 🆕 Показываем recovery sheet если нужно
            if case .healthy = recoveryState {
                // Всё ок, ничего не делаем
            } else {
                showRecoverySheet = true
            }
        }
        .sheet(isPresented: $showRecoverySheet) {
            DatabaseRecoveryView(state: recoveryState)
                .interactiveDismissDisabled()
        }
    }
}
