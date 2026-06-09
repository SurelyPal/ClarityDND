//
//  PartyManager+Persistence.swift
//  Clarity
//
//  
//

import Foundation

// MARK: - 💾 Сохранение состояния между сессиями

extension PartyManager {
    // MARK: - Keys

    private static let partyStateKey = "clarity_party_state"
    private static let gameRulesKey = "clarity_game_rules"
    private static let selectedCharacterKey = "clarity_selected_character"

    // MARK: - Party State

    func savePartyState() {
        do {
            let data = try JSONEncoder().encode(partyMembers)
            UserDefaults.standard.set(data, forKey: Self.partyStateKey)
            log("💾 Состояние партии сохранено: \(partyMembers.count) игроков")
        } catch {
            log("❌ Ошибка сохранения состояния партии: \(error)")
        }
    }

    func loadPartyState() {
        guard let data = UserDefaults.standard.data(forKey: Self.partyStateKey),
              let members = try? JSONDecoder().decode([PartyMember].self, from: data)
        else {
            log("📭 Нет сохранённого состояния партии")
            return
        }

        self.partyMembers = members.map { member in
            var m = member
            m.isConnected = false
            return m
        }

        log("📂 Загружено состояние партии: \(partyMembers.count) игроков (все офлайн)")
    }

    // MARK: - Game Rules

    func saveGameRules(_ rules: GameRules) {
        if let data = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(data, forKey: Self.gameRulesKey)
            log("💾 Правила сохранены локально")
        }
    }

    func loadGameRules() {
        guard let data = UserDefaults.standard.data(forKey: Self.gameRulesKey),
              let rules = try? JSONDecoder().decode(GameRules.self, from: data) else {
            return
        }
        self.gameRules = rules
        log("📂 Загружены правила: canEditOutsideParty=\(rules.canEditCharacterOutsideParty)")
    }

    // MARK: - Selected Character (для автопереподключения)

    func saveSelectedCharacterID(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: Self.selectedCharacterKey)
            log("💾 Сохранён ID выбранного персонажа: \(id)")
        } else {
            UserDefaults.standard.removeObject(forKey: Self.selectedCharacterKey)
            log("🗑️ Удалён ID выбранного персонажа")
        }
    }

    func loadSelectedCharacterID() -> UUID? {
        guard let idString = UserDefaults.standard.string(forKey: Self.selectedCharacterKey),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        log("📂 Загружен ID выбранного персонажа: \(id)")
        return id
    }
}
