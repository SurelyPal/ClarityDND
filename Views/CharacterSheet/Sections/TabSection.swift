//  TabSection.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//
import SwiftUI

struct TabSection: View, Equatable {
    @Environment(\.theme) private var theme
    @Binding var character: DNDCharacter
    @Binding var selectedTab: Int
    let canEdit: Bool
    
    //   Сравнение для оптимизации redraw
    static func == (lhs: TabSection, rhs: TabSection) -> Bool {
        lhs.selectedTab == rhs.selectedTab &&
        lhs.canEdit == rhs.canEdit &&
        // Проверяем только те поля, которые влияют на список табов
        lhs.character.characterClass == rhs.character.characterClass &&
        lhs.character.hasEquippedInstrument == rhs.character.hasEquippedInstrument
    }
    
    /// Все возможные табы с учётом класса и экипировки персонажа
    private var availableTabs: [Tab] {
        var tabs: [Tab] = [.stats, .skills, .inventory]
        
        if character.characterClass.hasTarotAccess {
            tabs.append(.tarot)
        }
        
        if character.characterClass == .bard && character.hasEquippedInstrument {
            tabs.append(.instrumentMods)
        }
        
        return tabs
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Панель табов
            HStack(spacing: 0) {
                ForEach(Array(availableTabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 6) {
                            // 🎯 ИКОНКА СВЕРХУ (отдельно от текста)
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedTab == index ? theme.primary : theme.textDim)
                                .frame(height: 18)
                            
                            // 🎯 ТЕКСТ СНИЗУ с авто-сжатием
                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == index ? .semibold : .regular))
                                .tracking(0.5)
                                .foregroundColor(selectedTab == index ? theme.primary : theme.textDim)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)  // ← Текст сам сожмётся до 70%
                                .padding(.horizontal, 2)
                            
                            // Индикатор активного таба
                            Rectangle()
                                .fill(selectedTab == index ? theme.primary : Color.clear)
                                .frame(height: 2)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == index
                            ? theme.primary.opacity(0.05)
                            : Color.clear
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(theme.surface)
            .overlay(
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5),
                alignment: .bottom
            )
            .padding(.horizontal, 16)
            
            // Содержимое активного таба
            Group {
                if let tab = availableTabs[safe: selectedTab] {
                    switch tab {
                    case .stats:           StatsTabView(character: character)
                    case .skills:         SkillsTabView(character: character)
                    case .inventory:      InventoryTabView(character: $character, canEdit: canEdit)        //  
                    case .tarot:          TarotTabView(character: $character, canEdit: canEdit)            //  
                    case .instrumentMods: InstrumentModsTabView(character: $character, canEdit: canEdit)   //  
                     }
                }
            }
        }
    }
}

// MARK: - Enum для табов

private enum Tab {
    case stats, skills, inventory, tarot, instrumentMods
    
    var title: String {
        switch self {
        case .stats:          return "Атрибуты"
        case .skills:         return "Навыки"
        case .inventory:      return "Инвентарь"
        case .tarot:          return "Таро"
        case .instrumentMods: return "Модификации"
        }
    }
    
    var icon: String {
        switch self {
        case .stats:          return "person.fill"
        case .skills:         return "star.fill"
        case .inventory:      return "bag.fill"
        case .tarot:          return "rectangle.stack.fill"
        case .instrumentMods: return "music.note"
        }
    }
}

// MARK: - Безопасный доступ к массиву по индексу
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
