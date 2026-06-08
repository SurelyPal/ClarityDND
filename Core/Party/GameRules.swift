//
//  GameRules.swift
//  Clarity
//
//  Набор правил игры, которые ДМ устанавливает перед созданием партии
//

import Foundation

nonisolated struct GameRules: Codable, Equatable, Sendable {
    /// Можно ли игрокам изменять своих героев когда они НЕ подключены к партии
    /// Если false — редактирование блокируется, пока игрок не в партии
    var canEditCharacterOutsideParty: Bool = true
    
    
    // 🔮 В будущем здесь появятся новые правила:
    // var allowLevelUpDuringCombat: Bool = true
    // var maxPartySize: Int = 6
    // var allowPvP: Bool = false
    // var diceRollVisibility: DiceVisibility = .all
    
    // 🛏️ Отдыхи за сессию
        var maxShortRests: Int = 2
        var maxLongRests: Int = 1
        
        // 🆕 Доступные отдыхи (уменьшаются при использовании)
        var shortRestsAvailable: Int = 2
        var longRestsAvailable: Int = 1
        
        static let `default` = GameRules()
        
        static let strict = GameRules(
            canEditCharacterOutsideParty: false
        )
        
        // 🆕 Проверка доступности отдыхов
        var canShortRest: Bool { shortRestsAvailable > 0 }
        var canLongRest: Bool { longRestsAvailable > 0 }
        
        // 🆕 Сброс счётчиков (для новой сессии)
        mutating func resetRests() {
            shortRestsAvailable = maxShortRests
            longRestsAvailable = maxLongRests
    }
}

