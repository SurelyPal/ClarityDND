//
//  CampaignManager.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//

import Foundation
import Combine
import SwiftData

// MARK: - Менеджер Кампаний (SwiftData версия)
/// Синглтон для управления кампаниями через SwiftData
@MainActor
final class CampaignManager: ObservableObject {
    // MARK: - Синглтон
    
    static let shared = CampaignManager()
    
    // MARK: - Published свойства
    
    /// Список всех кампаний (из SwiftData)
    @Published var campaigns: [Campaign] = []
    
    /// Текущая активная кампания (которую сейчас хостим)
    @Published var activeCampaign: Campaign?
    
    /// Локальный игрок (владелец устройства)
    @Published var currentPlayer: Player?
    
    /// Архивированные персонажи
    @Published var archivedCharacters: [ArchivedCharacter] = []
    
    /// Ошибки при работе с данными
    @Published var lastError: String?
    
    // MARK: - Вычисляемые свойства
    
    /// Кампании, где текущий игрок является ГМ-ом
    var myCampaigns: [Campaign] {
        guard let playerID = currentPlayer?.id else { return [] }
        return campaigns.filter { $0.owner?.id == playerID }
    }
    
    /// Кампании, где текущий игрок является участником (не ГМ)
    var joinedCampaigns: [Campaign] {
        guard let playerID = currentPlayer?.id else { return [] }
        return campaigns.filter { campaign in
            campaign.owner?.id != playerID &&
            campaign.joinedPlayers.contains { $0.id == playerID }
        }
    }
    
    // MARK: - Инициализация
    
    private init() {
        print("🚀 CampaignManager: Инициализация (SwiftData версия)")
        setupLocalPlayer()
        print("✅ CampaignManager: Инициализация завершена")
    }
    
    // MARK: - Настройка локального игрока
    
    /// Создаёт или загружает локального игрока
    private func setupLocalPlayer() {
        // TODO: Загрузить из SwiftData или создать нового
        let player = Player(playerName: "Локальный игрок")
        currentPlayer = player
        print("✅ Локальный игрок создан: \(player.playerName)")
    }
    
    // MARK: - CRUD операции
    
    /// Создаёт новую кампанию и сохраняет её в SwiftData
    func createCampaign(
        name: String,
        template: GameTemplate? = nil,
        context: ModelContext  // 🆕 ДОБАВЛЕН параметр context
    ) -> Campaign {
        // 1. Создаём объект в памяти
        let newCampaign = Campaign.new(
            name: name,
            type: .local,
            owner: currentPlayer
        )
        
        // 2. Привязываем шаблон (если есть)
        if let template = template {
            newCampaign.gameTemplate = template
        }
        
        // 🆕 3. КРИТИЧЕСКИ ВАЖНО: вставляем в SwiftData
        context.insert(newCampaign)
        
        // 🆕 4. Принудительно сохраняем
        do {
            try context.save()
            print("💾 Кампания '\(name)' сохранена в SwiftData")
        } catch {
            print("❌ Ошибка сохранения кампании: \(error)")
            lastError = "Не удалось сохранить кампанию: \(error.localizedDescription)"
        }
        
        print("✨ Создана новая кампания: \(name)")
        return newCampaign
    }
    
    /// Удаляет кампанию и архивирует персонажей
    func deleteCampaign(_ campaign: Campaign, context: ModelContext) {
        print("🗑️ Удаляем кампанию: \(campaign.name)")
        
        // 1. Архивируем всех персонажей из этой кампании
        archiveCharactersFromCampaign(campaign, context: context)
        
        // 2. Удаляем кампанию из SwiftData
        context.delete(campaign)
        
        // 3. Если это была активная кампания — сбрасываем
        if activeCampaign?.id == campaign.id {
            activeCampaign = nil
        }
        
        print("✅ Кампания удалена и персонажи архивированы")
    }
    
    /// Архивирует всех персонажей из кампании
    private func archiveCharactersFromCampaign(_ campaign: Campaign, context: ModelContext) {
        print("📦 Архивируем персонажей из кампании: \(campaign.name)")
        
        // Получаем всех персонажей с campaignID этой кампании
        let characterID = campaign.id
        let fetchDescriptor = FetchDescriptor<DNDCharacter>(
            predicate: #Predicate { $0.campaignID == characterID }
        )
        
        do {
            let characters = try context.fetch(fetchDescriptor)
            
            for character in characters {
                let archived = ArchivedCharacter.archive(from: character, campaign: campaign)
                context.insert(archived)
                
                // Добавляем в архив текущего игрока
                currentPlayer?.archivedCharacters.append(archived)
                
                print("✅ Архивирован персонаж: \(character.name)")
            }
            
            print("✅ Архивировано персонажей: \(characters.count)")
        } catch {
            print("❌ Ошибка архивации персонажей: \(error)")
            lastError = "Не удалось архивировать персонажей: \(error.localizedDescription)"
        }
    }
    
    /// Восстанавливает персонажа из архива
    func restoreCharacter(_ archived: ArchivedCharacter, to campaign: Campaign, context: ModelContext) -> DNDCharacter? {
        print("🔄 Восстанавливаем персонажа: \(archived.characterName)")
        
        // Проверяем, можно ли восстановить
        guard archived.canRestore else {
            print("❌ Невозможно восстановить: шаблон недоступен")
            lastError = "Шаблон кампании недоступен для восстановления"
            return nil
        }
        
        // Восстанавливаем из снапшота
        guard let restoredCharacter = archived.restoreCharacter() else {
            print("❌ Не удалось восстановить персонажа из снапшота")
            lastError = "Не удалось восстановить данные персонажа"
            return nil
        }
        
        // Привязываем к новой кампании
        restoredCharacter.campaignID = campaign.id
        restoredCharacter.campaignName = campaign.name
        
        // Вставляем в SwiftData
        context.insert(restoredCharacter)
        
        // Удаляем из архива
        context.delete(archived)
        currentPlayer?.archivedCharacters.removeAll { $0.id == archived.id }
        
        print("✅ Персонаж восстановлен: \(restoredCharacter.name)")
        return restoredCharacter
    }
    
    /// Переименовывает кампанию
    func renameCampaign(_ campaign: Campaign, to newName: String, context: ModelContext) {
        campaign.name = newName
        
        do {
            try context.save()
            print("💾 Кампания переименована и сохранена: \(newName)")
        } catch {
            print("❌ Ошибка сохранения: \(error)")
        }
    }
    
    // MARK: - Управление активной кампанией
    
    /// Устанавливает кампанию как активную (начинаем хостинг)
    func setActiveCampaign(_ campaign: Campaign, context: ModelContext) {
        campaign.isActive = true
        campaign.lastPlayedAt = Date()
        
        activeCampaign = campaign
        
        // 🆕 Сохраняем изменения
        do {
            try context.save()
            print("💾 Статус активной кампании сохранён")
        } catch {
            print("❌ Ошибка сохранения: \(error)")
        }
        
        print("🎯 Активная кампания: \(campaign.name)")
    }
    
    /// Сбрасывает статус активной кампании
    func clearActiveCampaign() {
        if let campaign = activeCampaign {
            campaign.isActive = false
        }
        activeCampaign = nil
        print("🧹 Активная кампания сброшена")
    }
    
    /// Обновляет данные активной кампании
    func updateActiveCampaign(
        members: [PartyMember]? = nil,
        gameRules: GameRules? = nil,
        joinCode: String? = nil
    ) {
        guard let campaign = activeCampaign else { return }
        
        if let members = members {
            campaign.members = members
        }
        
        if let gameRules = gameRules {
            campaign.gameRules = gameRules
        }
        
        if let joinCode = joinCode {
            campaign.joinCode = joinCode
        }
        
        campaign.lastPlayedAt = Date()
        
        print("🔄 Активная кампания обновлена")
    }
    
    // MARK: - Поиск и проверка
    
    /// Находит кампанию по ID персонажа
    func findCampaign(forCharacterID characterID: UUID) -> Campaign? {
        return campaigns.first { campaign in
            campaign.members.contains { $0.id == characterID }
        }
    }
    
    /// Проверяет, закреплён ли персонаж за другой кампанией
    func isCharacterAssignedToOtherCampaign(
        characterID: UUID,
        excludingCampaignID: UUID?
    ) -> Campaign? {
        return campaigns.first { campaign in
            campaign.id != excludingCampaignID &&
            campaign.members.contains { $0.id == characterID }
        }
    }
    
    /// Находит кампанию по joinCode
    func findCampaign(byJoinCode code: String) -> Campaign? {
        return campaigns.first { $0.joinCode == code }
    }
    
    // MARK: - Мультиплеер
    
    /// Переключает кампанию в режим мультиплеера
    func enableMultiplayer(for campaign: Campaign) {
        campaign.campaignType = .multiplayer
        campaign.joinCode = Campaign.generateJoinCode()
        
        print("🌐 Мультиплеер включён для кампании: \(campaign.name)")
        print("🔗 Код подключения: \(campaign.joinCode ?? "нет")")
    }
    
    /// Отключает мультиплеер для кампании
    func disableMultiplayer(for campaign: Campaign) {
        campaign.campaignType = .local
        campaign.joinCode = nil
        
        print("🔒 Мультиплеер отключён для кампании: \(campaign.name)")
    }
}

// MARK: - 🌉 Обратная совместимость (мосты для старого кода)
extension CampaignManager {
    
    /// Старый метод сохранения кампании (теперь не нужен — SwiftData сохраняет автоматически)
    func saveCampaign(_ campaign: Campaign) {
        print("💾 saveCampaign() вызван (заглушка) — SwiftData сохранит автоматически")
    }
    
    /// Старый метод загрузки всех кампаний (теперь не нужен)
    func loadAllCampaigns() {
        print("📚 loadAllCampaigns() вызван (заглушка) — SwiftData уже загрузил данные")
    }
    
    /// Заглушка для загрузки одной кампании
    func loadCampaign(from url: URL) -> Campaign? {
        print("⚠️ loadCampaign(from:) больше не используется")
        return nil
    }
}
