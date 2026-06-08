//
//  MilestoneReward.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//


//
//  MilestoneLibrary.swift
//  Earstus
//

import Foundation

// MARK: - Модель награды за повышение уровня
struct MilestoneReward: Identifiable {
    let id = UUID()
    let icon: String      // SF Symbol
    let title: String     // Заголовок награды
    let description: String // Описание эффекта
}

// MARK: - Библиотека наград по уровням
enum MilestoneLibrary {
    
    /// Возвращает список наград за достижение определённого уровня
    static func rewards(for level: Int) -> [MilestoneReward] {
        switch level {
        case 2:
            return [
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Ваше тело окрепло в странствиях."),
                .init(icon: "star.fill",
                      title: "Новая классовая способность",
                      description: "Вы открываете новые грани своего пути.")
            ]
        case 3:
            return [
                .init(icon: "shield.lefthalf.filled",
                      title: "Выбор подкласса",
                      description: "Ваш путь обретает уникальное направление."),
                .init(icon: "bolt.fill",
                      title: "+5 к максимальному HP",
                      description: "Опыт делает вас выносливее.")
            ]
        case 4:
            return [
                .init(icon: "arrow.up.circle.fill",
                      title: "Улучшение характеристики",
                      description: "+2 к одной характеристике или +1 к двум."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Ваши раны заживают быстрее.")
            ]
        case 5:
            return [
                .init(icon: "star.circle.fill",
                      title: "Бонус мастерства +3",
                      description: "Ваше мастерство выходит на новый уровень."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Тело закаляется в боях.")
            ]
        case 6:
            return [
                .init(icon: "sparkles",
                      title: "Новая классовая способность",
                      description: "Вы постигаете новые тайны своего пути."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Выносливость растёт с каждым днём.")
            ]
        case 7:
            return [
                .init(icon: "figure.walk",
                      title: "Новая классовая способность",
                      description: "Ваш арсенал приёмов расширяется."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Вы становитесь крепче.")
            ]
        case 8:
            return [
                .init(icon: "arrow.up.circle.fill",
                      title: "Улучшение характеристики",
                      description: "+2 к одной характеристике или +1 к двум."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Сила духа и тела растут.")
            ]
        case 9:
            return [
                .init(icon: "flame.fill",
                      title: "Новая классовая способность",
                      description: "Вы приближаетесь к вершине мастерства."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Ваше тело закалено годами странствий.")
            ]
        case 10:
            return [
                .init(icon: "crown.fill",
                      title: "Вершина пути",
                      description: "Вы достигли максимального уровня. Легенда о вас будет жить в веках."),
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Ваша стойкость невероятна.")
            ]
        default:
            return [
                .init(icon: "heart.fill",
                      title: "+5 к максимальному HP",
                      description: "Становясь сильнее с каждым днём.")
            ]
        }
    }
}