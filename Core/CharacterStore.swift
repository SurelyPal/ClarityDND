//
//  CharacterStore.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class CharacterStore: ObservableObject {
    private(set) var context: ModelContext
    @Published var characters: [DNDCharacter] = []
    
    init(context: ModelContext) {
        self.context = context
        migrateIfNeeded()
        fetchAll()
    }
    
    // ✅ НОВОЕ: Метод для подключения реального context
        func attachContext(_ newContext: ModelContext) {
            self.context = newContext
            fetchAll()
        }
    
    // MARK: - CRUD
    
    func add(_ character: DNDCharacter) {
        context.insert(character)
        save()
        fetchAll()
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let character = characters[index]
            
            // 1. Если удаляемый персонаж сейчас выбран в PartyManager, очищаем его
            if PartyManager.shared.selectedCharacter?.id == character.id {
                PartyManager.shared.clearSelectedCharacter()
                print("🧹 [CharacterStore] selectedCharacter очищен при удалении: \(character.displayName)")
            }
            
            // 2. Если удаляемый персонаж был привязан к кампании, очищаем UserDefaults
            if character.campaignID != nil {
                UserDefaults.standard.removeObject(forKey: "pendingCampaignBinding")
                PartyManager.shared.pendingCampaignID = nil
            }
            
            // 3. ✅ КРИТИЧНО: Если мы ИГРОК и подключены к ДМу — уведомляем ДМа ПЕРЕД удалением
            // ✅ ПРАВИЛЬНО: используем pattern matching для enum с associated value
            if PartyManager.shared.role == .player,
               case .connected = PartyManager.shared.connectionState {
                PartyManager.shared.syncCharacterDeletion(characterID: character.id)
                print("📤 [CharacterStore] Уведомление ДМа об удалении: \(character.displayName)")
            }
            
            // 4. ✅ Если мы ДМ — помечаем игрока как удалённого (он попадёт во вкладку "УДАЛЁННЫЕ")
            if PartyManager.shared.role == .dungeonMaster {
                PartyManager.shared.markCharacterAsDeleted(characterID: character.id)
                print("🗑️ [CharacterStore] ДМ пометил игрока как удалённого: \(character.displayName)")
            }
            // 🆕 4.5 АВТООТКЛЮЧЕНИЕ: если удаляется персонаж, привязанный к текущей активной кампании
                    // Игрок автоматически отключается от партии
                    if PartyManager.shared.role == .player,
                       case .connected = PartyManager.shared.connectionState,
                       let charCampaignID = character.campaignID,
                       let currentCampaignID = PartyManager.shared.currentCampaignID,
                       charCampaignID == currentCampaignID {
                        
                        print("🔌 [CharacterStore] Персонаж '\(character.displayName)' принадлежит текущей кампании — принудительное отключение")
                        
                        // Сохраняем причину отключения для UI
                        PartyManager.shared.disconnectReason = "Персонаж был удалён"
                        PartyManager.shared.lastError = "Вы отключены: удалён персонаж, привязанный к этой партии"
                        
                        // Полностью разрываем соединение
                        PartyManager.shared.cleanupConnection(reason: "Удаление персонажа текущей кампании")
                        
                        // Сбрасываем состояние партии
                        PartyManager.shared.partyMembers = []
                        PartyManager.shared.connectionState = .disconnected
                    
                        print("✅ [CharacterStore] Игрок отключён от партии")
                    }
            
            // 5. Удаляем из базы данных SwiftData
            context.delete(character)
        }
        save()
        fetchAll()
    }
    
// MARK: - Умная синхронизация

    /// Какие поля персонажа требуют полной синхронизации с ДМ
    enum ChangedField {
        case basic     // HP, level, stress — быстрая синхронизация
        case full      // inventory, stats, skills — полная синхронизация
        case none      // ничего не отправляем
    }

    /// Обновляет персонажа с явным указанием что изменилось
    func update(_ character: DNDCharacter, changed: ChangedField = .basic) {
        save()
        
        // 🔑 АВТО-СИНХРОНИЗАЦИЯ С ДМ
        guard PartyManager.shared.role == .player,
              case .connected = PartyManager.shared.connectionState else {
            return
        }
        
        switch changed {
        case .basic:
            PartyManager.shared.syncBasic(character)
        case .full:
            PartyManager.shared.syncFull(character)
        case .none:
            break
        }
    }
    // MARK: - Публичный refresh для View

    /// Принудительно обновляет массив characters из SwiftData
    func refresh() {
        fetchAll()
    }
    private func fetchAll() {
        // 🆕 ФИЛЬТРУЕМ: загружаем только НЕ удалённых персонажей
        let predicate = #Predicate<DNDCharacter> { character in
            !character.isDeleted
        }
        
        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        characters = (try? context.fetch(descriptor)) ?? []

        #if DEBUG
        print("📦 fetchAll: загружено \(characters.count) персонажей (без удалённых)")
        #endif
    }
    
    private func save() {
        try? context.save()
    }
    
    // MARK: - Одноразовая миграция с UserDefaults
    
    private func migrateIfNeeded() {
        let key = Constants.Storage.charactersKey
        guard let data = UserDefaults.standard.data(forKey: key),
              let oldChars = try? JSONDecoder().decode([DNDCharacter].self, from: data)
        else { return }
        
        for old in oldChars {
            // Создаём новую SwiftData-запись, копируем поля
            let new = DNDCharacter()
            new.id = old.id
            new.name = old.name
            new.race = old.race
            new.characterClass = old.characterClass
            new.level = old.level
            new.stats = old.stats
            new.background = old.background
            new.hitPoints = old.hitPoints
            new.currentHP = old.currentHP
            new.alignment = old.alignment
            new.stress = old.stress
            new.rerollPoints = old.rerollPoints
            new.instrument = old.instrument
            new.inventory = old.inventory
            new.tarotCards = old.tarotCards
            new.avatarData = old.avatarData
            context.insert(new)
        }
        
        save()
        UserDefaults.standard.removeObject(forKey: key)
        print("✅ Миграция UserDefaults → SwiftData завершена: перенесено \(oldChars.count) персонажей")
    }
    // MARK: - 🆕 Работа с кампаниями
    
    /// Проверяет, можно ли добавить персонажа в указанную кампанию.
    /// Возвращает false, если персонаж уже привязан к ДРУГОЙ кампании.
    func canAddCharacterToCampaign(
        _ character: DNDCharacter,
        campaignID: UUID
    ) -> Bool {
        // Если персонаж уже в этой кампании — всё ОК
        if character.campaignID == campaignID {
            return true
        }
        
        // Если персонаж в ДРУГОЙ кампании — нельзя
        if let existingCampaignID = character.campaignID,
           existingCampaignID != campaignID {
            return false
        }
        
        // Если персонаж не в кампании (nil) — можно добавить
        return true
    }
    
    /// Привязывает персонажа к указанной кампании
    func assignCharacter(_ character: DNDCharacter, to campaignID: UUID) {
        character.campaignID = campaignID
        // SwiftData автоматически отслеживает изменения @Model объектов
        print("🔗 Персонаж \(character.name) привязан к кампании")
    }
    
    /// Отвязывает ВСЕХ персонажей от указанной кампании
    func unassignCharacters(from campaignID: UUID) {
        for character in characters where character.campaignID == campaignID {
            character.campaignID = nil
        }
        print("🔓 Персонажи отвязаны от кампании")
    }
    
    /// Возвращает всех персонажей, привязанных к указанной кампании
    func characters(for campaignID: UUID) -> [DNDCharacter] {
        return characters.filter { $0.campaignID == campaignID }
    }
}
