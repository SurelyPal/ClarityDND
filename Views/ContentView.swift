//
//  ContentView.swift
//  Clarity
//
//  Created by KEBAB on 29.05.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var store: CharacterStore
    
    // Загружаем только не удалённых персонажей
    @Query(
        filter: #Predicate<DNDCharacter> { character in
            !character.isDeleted
        },
        sort: \DNDCharacter.name,
        order: .forward
    ) private var characters: [DNDCharacter]
    
    // 🆕 НОВОЕ: Загружаем все шаблоны для группировки
    @Query(sort: \GameTemplate.name) private var allTemplates: [GameTemplate]
    
    // Состояния
    @State private var showingCharacterCreation = false
    @State private var selectedCharacterForInfo: DNDCharacter?
    
    // 🆕 НОВОЕ: Группировка персонажей по шаблонам
    private var groupedCharacters: [(template: GameTemplate?, characters: [DNDCharacter])] {
        var groups: [UUID?: (template: GameTemplate?, characters: [DNDCharacter])] = [:]
        
        // Группируем персонажей по templateID
        for character in characters {
            let templateID = character.templateID
            
            if groups[templateID] == nil {
                let template = allTemplates.first { $0.id == templateID }
                groups[templateID] = (template: template, characters: [])
            }
            
            groups[templateID]?.characters.append(character)
        }
        
        // Сортируем: сначала с шаблонами (по имени), потом без шаблона
        return groups.values.sorted { group1, group2 in
            if group1.template == nil { return false }
            if group2.template == nil { return true }
            return (group1.template?.name ?? "") < (group2.template?.name ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                mainContent(store: store)
            }
            .navigationTitle("")
            .toolbar {
                // Кнопка "Партия" слева
                ToolbarItem(placement: .navigation) {
                    NavigationLink {
                        RoleSelectionView(partyManager: PartyManager.shared)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.3.fill")
                            Text("Партия")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(theme.primary)
                    }
                }
                
                // Кнопка "Настройки" справа (первая)
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.primary)
                    }
                }
                
                // Кнопка "Новый герой" справа (вторая)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCharacterCreation = true
                        SoundManager.shared.play(.pageTurn, haptic: .light)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Новый герой")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCharacterCreation) {
                CharacterCreationView()
                    .environmentObject(store)
            }
            .sheet(item: $selectedCharacterForInfo) { character in
                CharacterInfoView(character: character)
            }
        }
    }
    
    // MARK: - Основной контент (когда store готов)
    @ViewBuilder
    private func mainContent(store: CharacterStore) -> some View {
        VStack(spacing: 0) {
            // Заголовок программы
            appHeader
            
            if characters.isEmpty {
                emptyState
            } else {
                characterList(store: store)
            }
        }
    }

    // Компонент заголовка приложения
    private var appHeader: some View {
        VStack(spacing: 8) {
            Text("✦ CLARITY ✦")
                .font(.system(size: 11, weight: .medium))
                .tracking(4)
                .foregroundColor(theme.primaryDim)
            
            Text("Книга Судеб")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(theme.primary)
            
            // Декоративная линия
            HStack(spacing: 8) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
                
                Image(systemName: "diamond.fill")
                    .font(.system(size: 8))
                    .foregroundColor(theme.primaryDim)
                
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Пустое состояние
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(theme.primaryDim.opacity(0.5))
            
            Text("Книга пуста")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("Создайте своего первого героя,\nчтобы начать приключение")
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
            
            Button {
                showingCharacterCreation = true
                SoundManager.shared.play(.pageTurn, haptic: .light)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Создать героя")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.primary)
                .foregroundColor(theme.background)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Список персонажей (сгруппированный)
    private func characterList(store: CharacterStore) -> some View {
        List {
            ForEach(groupedCharacters, id: \.template?.id) { group in
                Section {
                    ForEach(group.characters, id: \.id) { character in
                        NavigationLink(destination: CharacterSheetView(character: character)
                            .environmentObject(store)) {
                            CharacterRowView(character: character)
                        }
                        .listRowBackground(theme.surface)
                        .listRowSeparatorTint(theme.border)
                        .contextMenu {
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
                        // Получаем персонажей из текущей группы
                        let charactersToDelete = offsets.map { group.characters[$0] }
                        for character in charactersToDelete {
                            if let index = characters.firstIndex(where: { $0.id == character.id }) {
                                store.delete(at: IndexSet(integer: index))
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: group.template != nil ? "book.fill" : "questionmark.circle")
                            .foregroundColor(theme.primary)
                            .font(.system(size: 14))
                        
                        Text(group.template?.name ?? "Без шаблона")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.text)
                        
                        Spacer()
                        
                        Text("\(group.characters.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textDim)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(theme.surfaceAlt)
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(theme.background)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .animation(nil, value: characters)
    }
}

// MARK: - Компонент строки персонажа
struct CharacterRowView: View {
    let character: DNDCharacter
    @Environment(\.theme) private var theme
    
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
                    .foregroundColor(theme.text)
                
                Text("\(character.race.rawValue) · \(character.characterClass.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textDim)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("Веха \(character.level)")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(theme.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(theme.danger)
                    
                    Text("\(character.currentHP)/\(character.hitPoints)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(hpColor)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private var hpColor: Color {
        let percentage = Double(character.currentHP) / Double(character.hitPoints)
        switch percentage {
        case 0.5...: return .green
        case 0.25..<0.5: return .yellow
        default: return .red
        }
    }
} 

#Preview {
    ContentView()
        .modelContainer(for: [DNDCharacter.self, GameTemplate.self], inMemory: true)
}
