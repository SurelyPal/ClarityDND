//
//  Campaign.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//  
//

import Foundation
import SwiftData

// MARK: - Тип кампании
enum CampaignType: String, Codable {
    case local = "local" // Локальная (без мультиплеера)
    case multiplayer = "multiplayer" // Мультиплеер
}

// MARK: - Модель Кампании (SwiftData)

/// Модель игровой кампании (партии/сессии)
/// Хранится в SwiftData. НЕ хранит участников напрямую — они в PartyManager.
@Model
final class Campaign {
    
    // MARK: - Уникальный идентификатор
    @Attribute(.unique) var id: UUID
    
    // MARK: - Идентификация
    var name: String // Название кампании
    var createdAt: Date // Дата создания
    var lastPlayedAt: Date // Дата последней игры
    
    // MARK: - Мультиплеер
    var campaignType: CampaignType // Тип: локальная или мультиплеер
    var joinCode: String? // 6-значный код для подключения
    var isActive: Bool // Активна ли сейчас
    
    // MARK: - Правила игры
    var gameRules: GameRules // Правила (счётчики отдыхов и т.д.)
    
    // MARK: - Заметки ДМа
    var dmNotes: String // Заметки ДМа
    
    // MARK: - Связи
    var gameTemplate: GameTemplate? // Шаблон игровой системы

    // 🆕 ДОБАВЛЕНО: Владелец кампании (ГМ, который её создал)
    @Relationship(inverse: \Player.createdCampaigns)
    var owner: Player?

    // 🆕 ДОБАВЛЕНО: Игроки, присоединившиеся к кампании
    var joinedPlayers: [Player] = []

    // Приватное хранилище для участников (чтобы работало вычисляемое свойство members)
    @Attribute(.externalStorage) private var _members: [PartyMember] = []
    
    // MARK: - Initializer
   
    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        lastPlayedAt: Date = Date(),
        campaignType: CampaignType = .local,
        joinCode: String? = nil,
        isActive: Bool = false,
        gameRules: GameRules = GameRules(),
        dmNotes: String = " ",
        gameTemplate: GameTemplate? = nil,
        owner: Player? = nil  // 🆕 ДОБАВЛЕНО
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.campaignType = campaignType
        self.joinCode = joinCode
        self.isActive = isActive
        self.gameRules = gameRules
        self.dmNotes = dmNotes
        self.gameTemplate = gameTemplate
        self.owner = owner  // 🆕 ДОБАВЛЕНО
    }
    
    // MARK: - Вычисляемые свойства

    /// Отформатированная дата последней игры (для UI)
    var formattedLastPlayed: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastPlayedAt)
    }

    /// 🆕 ВОЗВРАЩАЕМ: Общее количество участников в кампании
    var participantCount: Int {
        return members.count
    }

    /// 🆕 ВОЗВРАЩАЕМ: Количество онлайн-участников (подключённых сейчас)
    var onlineParticipantCount: Int {
        return members.filter { $0.isConnected }.count
    }

    /// 🆕 ВОЗВРАЩАЕМ: Краткое описание для UI ("3 уч. (2 онлайн)")
    var summary: String {
        let online = onlineParticipantCount
        let total = participantCount
        if total == 0 {
            return "Нет участников"
        }
        return "\(total) уч. (\(online) онлайн)"
    }
}

// MARK: - Вспомогательные статические методы

extension Campaign {

    /// Создаёт новую пустую кампанию с заданным именем
    static func new(name: String, type: CampaignType = .local, owner: Player? = nil) -> Campaign {  // 🆕 ДОБАВЛЕН owner
        let code = (type == .multiplayer) ? generateJoinCode() : nil
        return Campaign(
            name: name,
            campaignType: type,
            joinCode: code,
            owner: owner  // 🆕 ДОБАВЛЕНО
        )
    }
    
    /// Генерирует случайный 6-значный код для подключения
    static func generateJoinCode() -> String {
        return String((100000..<999999).randomElement()!)
    }
}

// MARK: - 🌉 Обратная совместимость (Мосты для старого кода)

extension Campaign {
    /// Старое название поля 'roomCode' теперь называется 'joinCode'
    var roomCode: String? {
        get { return joinCode }
        set { joinCode = newValue }
    }
    
    /// Заглушка для инвентаря ДМа (dmItemStorage)
    var dmItemStorage: [InventoryItem] {
        get { return [] }
        set { /* Игнорируем */ }
    }
    
    /// Старый статический метод генерации кода комнаты
    static func generateRoomCode() -> String {
        return generateJoinCode()
    }
}

// MARK: - 👥 Участники кампании (Обратная совместимость)

extension Campaign {
    /// Список участников кампании (PartyMember).
    /// SwiftData умеет хранить Codable структуры внутри @Model!
    /// Старый код писал `campaign.members`, теперь это обычное поле.
    var members: [PartyMember] {
        get {
            // Читаем из приватного хранилища SwiftData
            return _members
        }
        set {
            _members = newValue
        }
    }
}
