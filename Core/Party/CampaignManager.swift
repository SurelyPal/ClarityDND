// CampaignManager.swift
// Clarity
//
// Created by KEBAB on 10.06.2026.
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
        print("🚀 CampaignManager: Инициализация началась")
        print("📂 Путь к Documents: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "НЕ НАЙДЕН")")

        createCampaignsFolderIfNeeded()
        loadAllCampaigns()

        print("✅ CampaignManager: Инициализация завершена. Загружено \(campaigns.count) кампаний")
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

    /// Создаёт папку Campaigns, если её ещё нет
    private func createCampaignsFolderIfNeeded() {
        let fileManager = FileManager.default
        let directory = campaignsDirectory

        print("📁 Проверяем папку: \(directory.path)")

        if !fileManager.fileExists(atPath: directory.path) {
            print("📁 Папка не существует — создаём...")
            do {
                try fileManager.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                print("✅ 📁 Создана папка: \(directory.path)")
            } catch {
                print("❌ Ошибка создания папки: \(error)")
                print("❌ Описание: \(error.localizedDescription)")
                lastError = "Не удалось создать папку кампаний: \(error.localizedDescription)"
            }
        } else {
            print("✅ 📁 Папка уже существует")
        }

        // Проверяем права на запись
        if fileManager.isWritableFile(atPath: directory.path) {
            print("✅ Папка доступна для записи")
        } else {
            print("❌ Папка НЕ доступна для записи!")
        }
    }

    /// Возвращает путь к файлу конкретной кампании
    private func fileURL(for campaign: Campaign) -> URL {
        return campaignsDirectory
            .appendingPathComponent(campaign.id.uuidString)
            .appendingPathExtension(fileExtension)
    }

    // MARK: - CRUD операции

    /// Загружает все кампании из папки Campaigns
    func loadAllCampaigns() {
        print("📚 ═══════════════════════════════════════")
        print("📚 НАЧАЛО ЗАГРУЗКИ КАМПАНИЙ")
        print("📚 Путь: \(campaignsDirectory.path)")
        print("📚 ═══════════════════════════════════════")

        let fileManager = FileManager.default

        // Проверяем существование папки
        guard fileManager.fileExists(atPath: campaignsDirectory.path) else {
            print("❌ Папка Campaigns НЕ СУЩЕСТВУЕТ!")
            self.campaigns = []
            return
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: campaignsDirectory,
                includingPropertiesForKeys: nil
            )

            let jsonFiles = files.filter { $0.pathExtension == fileExtension }
            print("📚 Найдено JSON файлов: \(jsonFiles.count)")

            if jsonFiles.isEmpty {
                print("⚠️ Папка пустая — нет кампаний для загрузки")
                self.campaigns = []
                return
            }

            var loadedCampaigns: [Campaign] = []
            var failedFiles: [String] = []

            for fileURL in jsonFiles {
                print("📄 ─────────────────────────────────")
                print("📄 Читаем: \(fileURL.lastPathComponent)")

                if let campaign = loadCampaign(from: fileURL) {
                    loadedCampaigns.append(campaign)
                    print("✅ УСПЕХ: \(campaign.name) (\(campaign.members.count) игроков)")
                } else {
                    failedFiles.append(fileURL.lastPathComponent)
                    print("❌ ПРОВАЛ: не удалось загрузить")
                }
            }

            // Сортируем: свежие сверху
            self.campaigns = loadedCampaigns.sorted {
                $0.lastPlayedAt > $1.lastPlayedAt
            }

            print("📚 ═══════════════════════════════════════")
            print("📚 ИТОГО: загружено \(loadedCampaigns.count) из \(jsonFiles.count)")
            if !failedFiles.isEmpty {
                print("⚠️ Ошибки в файлах: \(failedFiles.joined(separator: ", "))")
            }
            print("📚 ═══════════════════════════════════════")

        } catch {
            print("❌ Критическая ошибка загрузки: \(error)")
            lastError = "Не удалось загрузить список кампаний: \(error.localizedDescription)"
        }
    }

    /// Загружает одну кампанию из JSON файла с детальным разбором ошибок
    private func loadCampaign(from url: URL) -> Campaign? {
        do {
            let data = try Data(contentsOf: url)
            print("📄 Размер файла: \(data.count) байт")

            // Показываем первые 200 байт для отладки
            if let preview = String(data: data.prefix(200), encoding: .utf8) {
                print("📄 Превью: \(preview)...")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let campaign = try decoder.decode(Campaign.self, from: data)
            return campaign

        } catch let decodingError as DecodingError {
            print("❌ ОШИБКА ДЕКОДИРОВАНИЯ:")
            switch decodingError {
            case .typeMismatch(let type, let context):
                print("    Type mismatch: \(type)")
                print("    Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("    Description: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("    Value not found: \(type)")
                print("    Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("    Description: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("    Key not found: \(key.stringValue)")
                print("    Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("    Description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("    Data corrupted: \(context.debugDescription)")
                print("    Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            @unknown default:
                print("    Unknown decoding error")
            }
            return nil

        } catch {
            print("❌ Другая ошибка: \(error)")
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

    /// Сохраняет (или обновляет) кампанию в её JSON файл
    func saveCampaign(_ campaign: Campaign) {
        let fileURL = fileURL(for: campaign)

        print("💾 Сохраняем кампанию: \(campaign.name)")
        print("💾 Путь к файлу: \(fileURL.path)")

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(campaign)
            print("💾 Размер данных: \(data.count) байт")

            try data.write(to: fileURL, options: .atomic)

            // Проверяем, что файл действительно создан
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: fileURL.path) {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? Int ?? 0
                print("✅ 💾 Файл создан: \(fileURL.lastPathComponent) (\(fileSize) байт)")
            } else {
                print("❌ Файл НЕ создан после записи!")
            }

            // Обновляем в списке, если она там уже есть
            if let index = campaigns.firstIndex(where: { $0.id == campaign.id }) {
                campaigns[index] = campaign
                print("🔄 Обновлена в списке (позиция \(index))")
            } else {
                print("ℹ️ Кампания ещё не в списке")
            }

            // Если это активная кампания — обновляем ссылку
            if activeCampaign?.id == campaign.id {
                activeCampaign = campaign
            }

        } catch {
            print("❌ Ошибка сохранения кампании: \(error)")
            print("❌ Описание: \(error.localizedDescription)")
            lastError = "Не удалось сохранить кампанию: \(error.localizedDescription)"
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
