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
    @EnvironmentObject var store: CharacterStore
    @State private var showingCreation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    VStack(spacing: 4) {
                        Text("✦ КНИГА СУДЕБ ✦")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(4)
                            .foregroundColor(Color.dsGoldDim)
                        Text("Герои")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(Color.dsGold)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    DSdivider().padding(.horizontal, 20)
                    
                    if store.characters.isEmpty {
                        emptyState
                    } else {
                        characterList
                    }
                }
            }
            .toolbar {
                // Слева: кнопка Партии (MultipeerConnectivity)
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: PartyLobbyView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 13))
                            Text("Партия")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(0.5)
                        }
                        .foregroundColor(Color.dsGold)
                    }
                }
                
                // Справа: только ОДНА кнопка создания персонажа
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreation = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.dsGold)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCreation) {
                CharacterCreationView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // 🆕 Автопереподключение при запуске приложения
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
                .foregroundColor(Color.dsGoldDim)
            Text("Книга пуста")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color.dsText)
            Text("Создайте своего первого героя")
                .font(.system(size: 13))
                .foregroundColor(Color.dsTextDim)
            Button(action: { showingCreation = true }) {
                Text("✦ Призвать героя ✦")
                    .font(.system(size: 16, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color.dsBackground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.dsGold)
                    .cornerRadius(3)
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
    
    // MARK: - Список персонажей
    
    // MARK: - Список персонажей

    private var characterList: some View {
        List {
            ForEach(store.characters) { character in
                NavigationLink(destination: CharacterSheetView(character: character)) {
                    CharacterRowView(character: character)
                }
                .listRowBackground(Color.dsSurface)
                .listRowSeparatorTint(Color.dsBorder)
            }
            .onDelete(perform: store.delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        // 🆕 PULL-TO-REFRESH: потяни вниз для переподключения к партии
        .refreshable {
            SoundManager.shared.play(.equip, haptic: .light)
            let success = await PartyManager.shared.reconnect()
            
            if success {
                // Успешное переподключение — обновляем список партии
                // (данные уже синхронизированы в PartyManager)
            }
        }
    }
}

// MARK: - Компонент строки персонажа
struct CharacterRowView: View {
    let character: DNDCharacter
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(avatarData: character.avatarData, race: character.race, size: 44)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(character.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.dsText)
                Text("\(character.race.rawValue) · \(character.characterClass.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsTextDim)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("Веха \(character.level)")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color.dsGold)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.dsRed)
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
        if fraction > 0.5 { return Color.dsGold }
        if fraction > 0.25 { return .orange }
        return Color.dsRed
    }
}

