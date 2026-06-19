//
//  ArchivedCharacter.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import Foundation
import SwiftData

/// Архивированный персонаж из удалённой кампании
/// Позволяет восстановить персонажа, если шаблон кампании ещё доступен
@Model
final class ArchivedCharacter {
    
    // MARK: - Уникальный идентификатор
    @Attribute(.unique) var id: UUID
    
    // MARK: - Данные персонажа (снимок)
    var characterName: String
    var characterRace: Race
    var characterClass: CharacterClass
    var characterLevel: Int
    var archivedAt: Date
    
    // MARK: - Ссылка на оригинальную кампанию
    var originalTemplateID: UUID? // ID шаблона кампании
    var originalCampaignName: String // Название удалённой кампании
    
    // MARK: - Бинарные данные (аватар)
    @Attribute(.externalStorage) var avatarData: Data?

    // 🆕 ДОБАВЛЕНО: Полный снапшот персонажа (для точного восстановления)
    @Attribute(.externalStorage) var characterSnapshotData: Data?
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        characterName: String,
        characterRace: Race,
        characterClass: CharacterClass,
        characterLevel: Int,
        archivedAt: Date = Date(),
        originalTemplateID: UUID? = nil,
        originalCampaignName: String,
        avatarData: Data? = nil,
        characterSnapshotData: Data? = nil  // 🆕 ДОБАВЛЕНО
    ) {
        self.id = id
        self.characterName = characterName
        self.characterRace = characterRace
        self.characterClass = characterClass
        self.characterLevel = characterLevel
        self.archivedAt = archivedAt
        self.originalTemplateID = originalTemplateID
        self.originalCampaignName = originalCampaignName
        self.avatarData = avatarData
        self.characterSnapshotData = characterSnapshotData  // 🆕 ДОБАВЛЕНО
    }
    // MARK: - Вычисляемые свойства
    
    /// Можно ли восстановить этого персонажа?
    /// (Проверяется наличие шаблона на устройстве)
    var canRestore: Bool {
        // TODO: Реализовать проверку наличия GameTemplate с originalTemplateID
        return originalTemplateID != nil
    }
}

// MARK: - Фабричный метод для создания из персонажа
extension ArchivedCharacter {
    /// Создаёт архивированного персонажа из существующего DNDCharacter
    /// - Parameters:
    ///   - character: Персонаж для архивации
    ///   - campaign: Кампания, из которой архивируем
    /// - Returns: Новый ArchivedCharacter
    static func archive(
        from character: DNDCharacter,
        campaign: Campaign
    ) -> ArchivedCharacter {
        // Сериализуем персонажа в JSON для точного восстановления
        var snapshotData: Data? = nil
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            snapshotData = try encoder.encode(character)
        } catch {
            print("⚠️ Не удалось сериализовать персонажа для архива: \(error)")
        }
        
        return ArchivedCharacter(
            characterName: character.name,
            characterRace: character.race,
            characterClass: character.characterClass,
            characterLevel: character.level,
            originalTemplateID: campaign.gameTemplate?.id,
            originalCampaignName: campaign.name,
            avatarData: character.avatarData,
            characterSnapshotData: snapshotData
        )
    }
    
    /// Пытается восстановить персонажа из снапшота
    /// - Returns: Восстановленный DNDCharacter или nil, если не удалось
    func restoreCharacter() -> DNDCharacter? {
        guard let data = characterSnapshotData else {
            print("⚠️ Нет снапшота для восстановления")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DNDCharacter.self, from: data)
        } catch {
            print("❌ Не удалось восстановить персонажа: \(error)")
            return nil
        }
    }
}
