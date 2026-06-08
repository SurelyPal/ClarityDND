
//  TarotCard.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import Foundation

struct TarotCard: Identifiable, Codable, Sendable {
    var id: UUID = UUID()
    var name: String = ""
    var arcana: String = ""
    var effect: String = ""
    var isRevealed: Bool = false
    var usesLeft: Int = 1
    
    /// Можно ли использовать карту
    var canUse: Bool {
        usesLeft > 0
    }
    
    /// Перевёрнутая ли карта
    var isFaceDown: Bool {
        !isRevealed
    }
    
    /// Использовать карту (уменьшает счётчик)
    mutating func use() {
        guard usesLeft > 0 else { return }
        usesLeft -= 1
    }
}

// MARK: - Стартовая колода
extension TarotCard {
    static let starterDeck: [TarotCard] = [
        .init(name: "Шут",
              arcana: "Старший аркан",
              effect: "Перебросить любой провальный бросок. Результат принимается каким бы он ни был.",
              isRevealed: true),
        .init(name: "Маг",
              arcana: "Старший аркан",
              effect: "+4 к следующему броску заклинания. Действует до конца сцены.",
              isRevealed: true),
        .init(name: "Верховная Жрица",
              arcana: "Старший аркан",
              effect: "Задать Мастеру один вопрос — он обязан ответить правдиво.",
              isRevealed: true),
        .init(name: "Смерть",
              arcana: "Старший аркан",
              effect: "Один враг в зоне видимости теряет половину оставшихся HP. Нельзя применять к боссам.",
              isRevealed: false),
        .init(name: "Башня",
              arcana: "Старший аркан",
              effect: "Вызвать хаотичное событие на выбор Мастера. Взамен получить 3 очка переброса.",
              isRevealed: true),
        .init(name: "Звезда",
              arcana: "Старший аркан",
              effect: "Восстановить 2d6 HP себе или союзнику. Можно использовать вне боя.",
              isRevealed: true),
        .init(name: "Мир",
              arcana: "Старший аркан",
              effect: "Завершить текущую сцену без потерь. Все враги отступают или замирают на 1 раунд.",
              isRevealed: true),
    ]
}
