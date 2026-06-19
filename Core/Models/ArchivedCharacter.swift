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
        avatarData: Data? = nil
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
    }
    
    // MARK: - Вычисляемые свойства
    
    /// Можно ли восстановить этого персонажа?
    /// (Проверяется наличие шаблона на устройстве)
    var canRestore: Bool {
        // TODO: Реализовать проверку наличия GameTemplate с originalTemplateID
        return originalTemplateID != nil
    }
}
