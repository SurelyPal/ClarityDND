//
//  Campaign.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//


import Foundation

// MARK: - Модель Кампании (Party Session)

/// Представляет одну игровую партию/кампанию ДМа
struct Campaign: Identifiable, Codable, Equatable, Sendable {
    
    // MARK: - Свойства
    
    /// Уникальный идентификатор кампании
    let id: UUID
    
    /// Название кампании (например, "Проклятие Страда", "Затерянные шахты")
    var name: String
    
    /// Дата создания кампании
    let createdAt: Date
    
    /// Дата последнего сохранения/игры
    var lastPlayedAt: Date
    
    /// Код комнаты Multipeer (4 символа)
    var roomCode: String
    
    /// Правила игры (счётчики отдыхов и т.д.)
    var gameRules: GameRules
    
    /// Список участников партии
    var members: [PartyMember]
    
    /// Активен ли сейчас хостинг этой кампании
    var isActive: Bool
    
    /// Заметки ДМа о кампании
    var dmNotes: String
    
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
        dmNotes: String = ""
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
    }
    
    // MARK: - Вычисляемые свойства
    
    /// Количество игроков в партии
    var playerCount: Int {
        return members.count
    }
    
    /// Количество онлайн-игроков
    var onlinePlayerCount: Int {
        return members.filter { $0.isConnected }.count
    }
    
    /// Форматированная дата последней игры
    var formattedLastPlayed: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastPlayedAt)
    }
    
    /// Краткое описание для UI
    var summary: String {
        let online = onlinePlayerCount
        let total = playerCount
        return "\(total) игр. (\(online) онлайн)"
    }
}

// MARK: - Вспомогательные методы

extension Campaign {
    
    /// Создаёт пустую кампанию с заданным именем
    static func new(name: String) -> Campaign {
        return Campaign(
            name: name,
            roomCode: Self.generateRoomCode()
        )
    }
    
    /// Генерирует случайный 4-символьный код комнаты
    static func generateRoomCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<4).map { _ in letters.randomElement()! })
    }
}