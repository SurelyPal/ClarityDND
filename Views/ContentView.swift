//
//  ContentView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI
import SwiftData

// MARK: - Главный экран (список персонажей)

struct ContentView: View {
    
    // MARK: - Свойства
    
    /// Контекст SwiftData из окружения (доступен внутри WindowGroup)
    @Environment(\.modelContext) private var modelContext
    /// Хранилище персонажей (создаётся отложенно, когда context доступен)
    @EnvironmentObject var store: CharacterStore
    /// Тема из окружения
    @Environment(\.theme) private var theme //Получаем тему
    /// Показать экран создания персонажа
    @State private var showingCreation = false
    @State private var selectedCharacterForInfo: DNDCharacter? = nil
    
    @Query(
        filter: #Predicate<DNDCharacter> { character in
            !character.isDeleted  //НОВОЕ: Показываем только не удалённых
        },
        sort: \DNDCharacter.name,
        order: .forward
    ) private var characters: [DNDCharacter]
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                mainContent(store: store)
                
                    .toolbar {
#if os(iOS)
                        // Справа: кнопка настроек
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(theme.primary) // 🔧 Используем тему
                                    .font(.system(size: 16, weight: .medium))
                                }
                            }
                        // Слева: кнопка Партии (MultiPeerConnectivity)
                        ToolbarItem(placement: .navigationBarLeading) {
                            NavigationLink(destination: PartyLobbyView()) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 13))
                                    Text("Партия")
                                        .font(.system(size: 12, weight: .medium))
                                        .tracking(0.5)
                                }
                                .foregroundColor(theme.primary) // 🔧 Используем тему
                            }
                        }
                        
                        // Справа: кнопка создания персонажа
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingCreation = true }) {
                                Image(systemName: "plus")
                                    .foregroundColor(theme.primary) // 🔧 Используем тему
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .disabled(store == nil)
                        }
#elseif os(macOS)
                        // macOS: используем primaryAction для всех кнопок
                        ToolbarItemGroup(placement: .primaryAction) {
                            NavigationLink(destination: PartyLobbyView()) {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 13))
                                    Text("Партия")
                                        .font(.system(size: 12, weight: .medium))
                                        .tracking(0.5)
                                }
                                .foregroundColor(theme.primary) // 🔧 Используем тему
                            }
                            
                            NavigationLink(destination: SettingsView()) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(theme.primary) // 🔧 Используем тему
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Button(action: { showingCreation = true }) {
                                Image(systemName: "plus")
                                    .foregroundColor(theme.primary) // 🔧 Используем тему
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .disabled(store == nil)
                        }
#endif
                    }
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .sheet(isPresented: $showingCreation) {
                       
                            CharacterCreationView()
                                .environmentObject(store)
                        
                    }
            }
            .background(theme.background)
            .preferredColorScheme(.dark)
        }
    }
    // MARK: - Основной контент (когда store готов)
    
    @ViewBuilder
    private func mainContent(store: CharacterStore) -> some View {
        VStack(spacing: 0) {
            
            // Заголовок
            VStack(spacing: 4) {
                Text("✦ КНИГА СУДЕБ ✦")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(4)
                    .foregroundColor(theme.primaryDim) // 🔧 Используем тему
                
                Text("Герои")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(theme.primary) // 🔧 Используем тему
            }
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            DSdivider()
                .padding(.horizontal, 20)
            
            if characters.isEmpty {
                emptyState
            } else {
                characterList(store: store)
            }
        }
        .background(theme.background)  // ✅ НОВОЕ: фон для всего mainContent
        .environmentObject(store)
        .onAppear {
            //   Автопереподключение при запуске приложения
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                PartyManager.shared.tryAutoReconnect(characters: store.characters)
            }
        }
    }
 
    // MARK: - Пустое состояние
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(theme.primaryDim) // 🔧 Используем тему
            
            Text("Книга пуста")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(theme.text) // 🔧 Используем тему
            
            Text("Создайте своего первого героя")
                .font(.system(size: 13))
                .foregroundColor(theme.textDim) // 🔧 Используем тему
            
            Button(action: { showingCreation = true }) {
                Text("✦ Призвать героя ✦")
                    .font(.system(size: 16, weight: .medium))
                    .tracking(1)
                    .foregroundColor(theme.background) // 🔧 Используем тему
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.primary) // 🔧 Используем тему
                    .cornerRadius(3)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Список персонажей
    
    private func characterList(store: CharacterStore) -> some View {
        List {
            ForEach(characters, id: \.id) { (character: DNDCharacter) in
                NavigationLink(destination: CharacterSheetView(character: character)
                    .environmentObject(store)) {
                        CharacterRowView(character: character)
                    }
                    .listRowBackground(theme.surface) // 🔧 Используем тему
                    .listRowSeparatorTint(theme.border) // 🔧 Используем тему
                    .contextMenu {
                        // ✅ НОВОЕ: Кнопка информации о персонаже
                        Button(action: {
                            selectedCharacterForInfo = character
                            PlatformCompatibility.hapticImpact(.light)
                        }) {
                            Label("Информация о персонаже", systemImage: "info.circle")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            if let index = characters.firstIndex(where: { $0.id == character.id }) {
                                store.delete(at: IndexSet(integer: index))
                                SoundManager.shared.play(.unequip, haptic: .medium)
                            }
                        } label: {
                            Label("Удалить персонажа", systemImage: "trash")
                        }
                    }
            }
            .onDelete { offsets in
                store.delete(at: offsets)
            }
        }
        // ✅ НОВОЕ: Показываем sheet, когда selectedCharacterForInfo не nil
        .sheet(item: $selectedCharacterForInfo) { (character: DNDCharacter) in
            CharacterInfoView(character: character)
        }
        
        // ✅ ЭТИ МОДИФИКАТОРЫ ДОЛЖНЫ БЫТЬ ПОСЛЕ LIST, А НЕ ВНУТРИ!
        .listStyle(.plain)
            .scrollContentBackground(.hidden) //Скрываем стандартный фон ячеек
            .background(theme.background) // Используем тему
            .animation(nil, value: characters)
        //   PULL-TO-REFRESH: потяни вниз для переподключения к партии
        .refreshable {
            SoundManager.shared.play(.equip, haptic: .light)
            let success = await PartyManager.shared.reconnect()
            
            if success {
                print("✅ Успешное переподключение из ContentView")
            }
            
            // ✅ Обновляем store.characters вручную (для синхронизации с партией)
            store.refresh()
        }
    }
    // MARK: - Компонент строки персонажа
    
    struct CharacterRowView: View {
        
        let character: DNDCharacter
        @Environment(\.theme) private var theme //   Получаем тему
        
        var body: some View {
            HStack(spacing: 12) {
                
                AvatarView(
                    avatarData: character.avatarData,
                    race: character.race,
                    size: 44
                )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(character.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.text) // 🔧 Используем тему
                    
                    Text("\(character.race.rawValue) · \(character.characterClass.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textDim) // 🔧 Используем тему
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Веха \(character.level)")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                        .foregroundColor(theme.primary) // 🔧 Используем тему
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(theme.danger) // 🔧 Используем тему
                        
                        Text("\(character.currentHP)/\(character.hitPoints)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(hpColor)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        
        private var hpColor: Color {
            let fraction = Double(character.currentHP) / Double(max(character.hitPoints, 1))
            
            if fraction > 0.5 {
                return theme.primary // 🔧 Используем тему
            }
            if fraction > 0.25 {
                return .orange
            }
            return theme.danger// 🔧 Используем тему
        }
    }
}
    // MARK: - Preview
    
    #Preview {
        ContentView()
            .modelContainer(for: DNDCharacter.self)
            .preferredColorScheme(.dark)
    }

