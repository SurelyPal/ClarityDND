//
//  Campaign.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//

import Foundation

// MARK: - Модель Кампании (Партии/Сессии)

/// Структура, представляющая одну игровую кампанию ДМа.
/// Сохраняется как JSON файл в Documents/Campaigns/
struct Campaign: Identifiable, Codable, Equatable, Sendable {
    
    // MARK: - Свойства
    
    /// Уникальный идентификатор кампании
    let id: UUID
    
    /// Название кампании (например, "Проклятие Страда")
    var name: String
    
    /// Дата создания кампании
    let createdAt: Date
    
    /// Дата последней игры/сохранения
    var lastPlayedAt: Date
    
    /// Код комнаты Multipeer (6 цифр)
    var roomCode: String
    
    /// Правила игры (счётчики отдыхов и т.д.)
    var gameRules: GameRules
    
    /// Список участников партии (PartyMember)
    var members: [PartyMember]
    
    /// Активна ли сейчас эта кампания (хостится ли)
    var isActive: Bool
    
    /// Заметки ДМа о кампании (для будущих версий)
    var dmNotes: String
    
    /// Хранилище предметов ДМа (предзагруженные предметы для выдачи игрокам)
    var dmItemStorage: [InventoryItem] = [] // Шаблоны предметов для выдачи
    // MARK: - Инициализация
    
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastPlayedAt: Date = Date(),
        roomCode: String = "",
        gameRules: GameRules = GameRules(),
        members: [PartyMember] = [],
        isActive: Bool = false,
        dmNotes: String = "",
        dmItemStorage: [InventoryItem] = [] // 🆕
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.roomCode = roomCode
        self.gameRules = gameRules
        self.members = members
        self.isActive = isActive
        self.dmNotes = dmNotes
        self.dmItemStorage = dmItemStorage // 🆕
    }
    
    // MARK: - Вычисляемые свойства
    
    /// Общее количество игроков в партии
    var playerCount: Int {
        return members.count
    }
    
    /// Количество онлайн-игроков (подключённых сейчас)
    var onlinePlayerCount: Int {
        return members.filter { $0.isConnected }.count
    }
    
    /// Отформатированная дата последней игры (для отображения в UI)
    var formattedLastPlayed: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastPlayedAt)
    }
    
    /// Краткое описание для UI ("3 игр. (2 онлайн)")
    var summary: String {
        let online = onlinePlayerCount
        let total = playerCount
        return "\(total) игр. (\(online) онлайн)"
    }
}

// MARK: - Вспомогательные статические методы

extension Campaign {
    
    /// Создаёт новую пустую кампанию с заданным именем и случайным кодом
    static func new(name: String) -> Campaign {
        return Campaign(
            name: name,
            roomCode: Self.generateRoomCode()
        )
    }
    
    /// Генерирует случайный 6-значный код комнаты
    static func generateRoomCode() -> String {
        return String((100000..<999999).randomElement()!)
    }
}
