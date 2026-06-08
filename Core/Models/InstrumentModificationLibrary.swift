
//
//  InstrumentModificationLibrary.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import Foundation

/// Централизованная библиотека всех модификаций инструментов
/// По аналогии с MilestoneLibrary — никаких хардкодов в UI!
enum InstrumentModificationLibrary {
    
    /// Все доступные модификации в игре
    static let all: [InstrumentModification] = [
        // ═══════════════════════════════════════════
        // РЕЗОНАНС (усиление звука и дальности)
        // ═══════════════════════════════════════════
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Эхо гор",
            description: "Звук разносится на 100 метров дальше, отражаясь от далёких вершин.",
            effect: "+2 к проверкам Выступления на открытом пространстве",
            slot: .resonance,
            rarity: .rare
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
            name: "Боевой ритм",
            description: "Каждый удар задаёт темп сражения.",
            effect: "Союзники в радиусе 10 метров получают +1 к инициативе",
            slot: .resonance,
            rarity: .rare
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!,
            name: "Голос древних",
            description: "Инструмент звучит так, будто на нём играют призраки былых мастеров.",
            effect: "Раз в сцену можно вызвать духа барда для помощи в броске",
            slot: .resonance,
            rarity: .epic
        ),
        
        // ═══════════════════════════════════════════
        // ЧАРЫ (магические эффекты)
        // ═══════════════════════════════════════════
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000004")!,
            name: "Шёпот ветра",
            description: "Мелодия слышна только избранным.",
            effect: "Можно играть скрытно, не привлекая внимания",
            slot: .enchantment,
            rarity: .epic
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000005")!,
            name: "Заклинание гармонии",
            description: "Музыка исцеляет раны слушателей.",
            effect: "Раз в сцену можно восстановить 1d6 HP союзнику",
            slot: .enchantment,
            rarity: .epic
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000006")!,
            name: "Песнь страха",
            description: "Тёмные ноты заставляют врагов дрожать.",
            effect: "Один враг в зоне слышимости получает -2 к следующему броску атаки",
            slot: .enchantment,
            rarity: .rare
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000007")!,
            name: "Пробуждение стихии",
            description: "Инструмент пробуждает силу природы.",
            effect: "Раз в день можно сотворить заклинание 2 круга без ячейки",
            slot: .enchantment,
            rarity: .legendary
        ),
        
        // ═══════════════════════════════════════════
        // МАСТЕРСТВО (бонусы к навыку игры)
        // ═══════════════════════════════════════════
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000008")!,
            name: "Рука мастера",
            description: "Инструмент откликается на малейшее прикосновение.",
            effect: "+3 к проверкам Выступления",
            slot: .mastery,
            rarity: .legendary
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000009")!,
            name: "Пальцы виртуоза",
            description: "Движения становятся точнее и быстрее.",
            effect: "+2 к проверкам Выступления, критические успехи случаются чаще",
            slot: .mastery,
            rarity: .epic
        ),
        .init(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000010")!,
            name: "Секреты школы",
            description: "Древние техники игры, переданные из поколения в поколение.",
            effect: "+1 к проверкам Выступления, раз в день можно перебросить провал",
            slot: .mastery,
            rarity: .rare
        ),
    ]
    
    /// Возвращает модификации для конкретного слота
    static func forSlot(_ slot: InstrumentModificationSlot) -> [InstrumentModification] {
        all.filter { $0.slot == slot }
    }
    
    /// Возвращает модификации по редкости
    static func byRarity(_ rarity: InstrumentModification.Rarity) -> [InstrumentModification] {
        all.filter { $0.rarity == rarity }
    }
    
    /// Ищет модификацию по id (для сохранения ссылок между сессиями)
    static func find(by id: UUID) -> InstrumentModification? {
        all.first { $0.id == id }
    }
}
