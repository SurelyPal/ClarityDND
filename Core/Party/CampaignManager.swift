//
//  CampaignManager.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//


import Foundation
import Combine

// MARK: - Менеджер Кампаний

/// Синглтон для управления файлами кампаний
@MainActor
final class CampaignManager: ObservableObject {
    
    // MARK: - Синглтон
    
    static let shared = CampaignManager()
    
    // MARK: - Published свойства
    
    /// Список всех кампаний ДМа
    @Published var campaigns: [Campaign] = []
    
    /// Текущая активная кампания (которую сейчас хостим)
    @Published var activeCampaign: Campaign?
    
    /// Ошибки при работе с файлами
    @Published var lastError: String?
    
    // MARK: - Константы
    
    private let campaignsFolderName = "Campaigns"
    private let fileExtension = "json"
    
    // MARK: - Инициализация
    
    private init() {
        createCampaignsFolderIfNeeded()
        loadAllCampaigns()
    }
    
    // MARK: - Работа с файловой системой
    
    /// Возвращает путь к папке с кампаниями
    private var campaignsDirectory: URL {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        return documentsDirectory.appendingPathComponent(campaignsFolderName)
    }
    
    /// Создаёт папку Campaigns если её нет
    private func createCampaignsFolderIfNeeded() {
        let fileManager = FileManager.default
        let directory = campaignsDirectory
        
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                print("📁 Создана папка: \(directory.path)")
            } catch {
                print("❌ Ошибка создания папки: \(error)")
                lastError = "Не удалось создать папку кампаний"
            }
        }
    }
    
    /// Возвращает путь к файлу конкретной кампании
    private func fileURL(for campaign: Campaign) -> URL {
        return campaignsDirectory
            .appendingPathComponent(campaign.id.uuidString)
            .appendingPathExtension(fileExtension)
    }
    
    /// Возвращает путь к файлу по ID кампании
    private func fileURL(for campaignID: UUID) -> URL {
        return campaignsDirectory
            .appendingPathComponent(campaignID.uuidString)
            .appendingPathExtension(fileExtension)
    }
    
    // MARK: - CRUD операции
    
    /// Загружает все кампании из файлов
    func loadAllCampaigns() {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(
                at: campaignsDirectory,
                includingPropertiesForKeys: nil
            )
            
            var loadedCampaigns: [Campaign] = []
            
            for fileURL in files where fileURL.pathExtension == fileExtension {
                if let campaign = loadCampaign(from: fileURL) {
                    loadedCampaigns.append(campaign)
                }
            }
            
            // Сортируем по дате последней игры (свежие сверху)
            self.campaigns = loadedCampaigns.sorted {
                $0.lastPlayedAt > $1.lastPlayedAt
            }
            
            print("📚 Загружено \(campaigns.count) кампаний")
            
        } catch {
            print("❌ Ошибка загрузки кампаний: \(error)")
            lastError = "Не удалось загрузить список кампаний"
        }
    }
    
    /// Загружает одну кампанию из файла
    private func loadCampaign(from url: URL) -> Campaign? {
        do {
            let data = try Data(contentsOf: url)
            let campaign = try JSONDecoder().decode(Campaign.self, from: data)
            return campaign
        } catch {
            print("❌ Ошибка загрузки кампании из \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    /// Создаёт новую кампанию с заданным именем
    func createCampaign(name: String) -> Campaign {
        let newCampaign = Campaign.new(name: name)
        
        // Сохраняем в файл
        saveCampaign(newCampaign)
        
        // Добавляем в список
        campaigns.insert(newCampaign, at: 0)
        
        print("✨ Создана новая кампания: \(name)")
        return newCampaign
    }
    
    /// Сохраняет кампанию в файл
    func saveCampaign(_ campaign: Campaign) {
        let fileURL = fileURL(for: campaign)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(campaign)
            try data.write(to: fileURL, options: .atomic)
            
            print("💾 Кампания сохранена: \(campaign.name)")
            
            // Обновляем в списке
            if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
                campaigns[index] = campaign
            }
            
            // Обновляем активную кампанию если это она
            if activeCampaign?.id == campaign.id {
                activeCampaign = campaign
            }
            
        } catch {
            print("❌ Ошибка сохранения кампании: \(error)")
            lastError = "Не удалось сохранить кампанию"
        }
    }
    
    /// Удаляет кампанию (и файл, и из списка)
    func deleteCampaign(_ campaign: Campaign) {
        let fileURL = fileURL(for: campaign)
        let fileManager = FileManager.default
        
        // Удаляем файл
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("🗑️ Файл кампании удалён: \(campaign.name)")
            } catch {
                print("❌ Ошибка удаления файла: \(error)")
            }
        }
        
        // Удаляем из списка
        campaigns.removeAll { $0.id == campaign.id }
        
        // Если это была активная — сбрасываем
        if activeCampaign?.id == campaign.id {
            activeCampaign = nil
        }
    }
    
    /// Переименовывает кампанию
    func renameCampaign(_ campaign: Campaign, to newName: String) {
        var updatedCampaign = campaign
        updatedCampaign.name = newName
        saveCampaign(updatedCampaign)
    }
    
    /// Устанавливает кампанию как активную (начинаем хостинг)
    func setActiveCampaign(_ campaign: Campaign) {
        var updatedCampaign = campaign
        updatedCampaign.isActive = true
        updatedCampaign.lastPlayedAt = Date()
        
        activeCampaign = updatedCampaign
        saveCampaign(updatedCampaign)
        
        print("🎯 Активная кампания: \(campaign.name)")
    }
    
    /// Сбрасывает статус активной кампании
    func clearActiveCampaign() {
        if var campaign = activeCampaign {
            campaign.isActive = false
            saveCampaign(campaign)
        }
        activeCampaign = nil
    }
    
    /// Обновляет данные активной кампании (вызывается при изменениях)
    func updateActiveCampaign(
        members: [PartyMember]? = nil,
        gameRules: GameRules? = nil,
        roomCode: String? = nil
    ) {
        guard var campaign = activeCampaign else { return }
        
        if let members = members {
            campaign.members = members
        }
        
        if let gameRules = gameRules {
            campaign.gameRules = gameRules
        }
        
        if let roomCode = roomCode {
            campaign.roomCode = roomCode
        }
        
        campaign.lastPlayedAt = Date()
        saveCampaign(campaign)
    }
    
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
}