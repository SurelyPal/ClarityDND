//
//  DungeonMasterDetailView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI

/// Детальный экран игрока для ДМ и других игроков
struct DungeonMasterDetailView: View {
    let memberID: UUID
    
    @EnvironmentObject var partyManager: PartyManager
    
    // 🆕 Вычисляемое свойство — всегда актуальные данные
    private var member: PartyMember? {
        partyManager.partyMembers.first { $0.id == memberID }
    }
    
    var body: some View {
        // 🆕 Проверяем что игрок ещё существует
        if let member = member {
            ScrollView {
                VStack(spacing: 20) {
                    header(member)
                    basicInfo(member)
                    statsSection(member)
                    skillsSection(member)
                    inventorySection(member)
                }
                .padding(.bottom, 40)
            }
        } else {
            // Игрок отключился или вышел — показываем placeholder
            VStack(spacing: 16) {
                Image(systemName: "person.slash.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color.dsTextDim)
                
                Text("Игрок недоступен")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsText)
                
                Text("Этот игрок вышел из партии")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.dsBackground)
        }
    }
    
    // MARK: - Header
    
    private func header(_ member: PartyMember) -> some View {
        VStack(spacing: 12) {
            AvatarView(avatarData: member.avatarData, race: member.race, size: 100)
            
            Text(member.name)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(Color.dsGold)
            
            Text("\(member.race.rawValue) · \(member.characterClass)")
                .font(.system(size: 13))
                .foregroundColor(Color.dsTextDim)
            
            // HP бар
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.dsSurfaceAlt)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(member.hpColor)
                            .frame(width: geo.size.width * member.hpFraction, height: 8)
                            .animation(.spring(), value: member.currentHP)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsRed)
                    Text("\(member.currentHP) / \(member.maxHP)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(member.hpColor)
                }
            }
            .padding(.horizontal, 20)
            
            DSdivider()
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Basic Info
    
    private func basicInfo(_ member: PartyMember) -> some View {
        VStack(spacing: 0) {
            InfoRow(icon: "star.fill", label: "Веха", value: "\(member.level)", isLast: false)
            
            InfoRow(icon: "bolt.fill", label: "Стресс", value: "\(member.stress)", isLast: false)
            
            if let reroll = member.rerollPoints {
                InfoRow(icon: "arrow.clockwise", label: "Очки переброса", value: "\(reroll)", isLast: false)
            }
            
            if let bg = member.background, !bg.isEmpty {
                InfoRow(icon: "book.fill", label: "Предыстория", value: bg, isLast: false)
            }
            
            if let align = member.alignment {
                InfoRow(icon: "scalemass.fill", label: "Мировоззрение", value: align.rawValue, isLast: true)
            }
        }
        .dsCard()
        .padding(.horizontal, 16)
    }
    
    // MARK: - Stats
    
    private func statsSection(_ member: PartyMember) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("ХАРАКТЕРИСТИКИ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if let stats = member.stats {
                VStack(spacing: 0) {
                    StatRow(name: "Сила", value: stats.strength, isLast: false)
                    StatRow(name: "Ловкость", value: stats.dexterity, isLast: false)
                    StatRow(name: "Телосложение", value: stats.constitution, isLast: false)
                    StatRow(name: "Интеллект", value: stats.intelligence, isLast: false)
                    StatRow(name: "Мудрость", value: stats.wisdom, isLast: false)
                    StatRow(name: "Харизма", value: stats.charisma, isLast: true)
                }
                .dsCard()
                .padding(.horizontal, 16)
            } else {
                Text("Данные ещё не получены")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsTextDim)
                    .padding()
            }
        }
    }
    
    // MARK: - Skills
    
    private func skillsSection(_ member: PartyMember) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("НАВЫКИ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if let proficiencies = member.skillProficiencies, !proficiencies.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(proficiencies.enumerated()), id: \.offset) { index, skill in
                        HStack {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 7))
                                .foregroundColor(Color.dsGold)
                                .frame(width: 16)
                            
                            Text(skill)
                                .font(.system(size: 13))
                                .foregroundColor(Color.dsText)
                            
                            Spacer()
                            
                            Text("Мастерство")
                                .font(.system(size: 10))
                                .foregroundColor(Color.dsGold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if index < proficiencies.count - 1 {
                                Rectangle()
                                    .fill(Color.dsBorder)
                                    .frame(height: 0.5)
                                    .padding(.leading, 32)
                            }
                        }
                    }
                }
                .dsCard()
                .padding(.horizontal, 16)
            } else {
                Text("Нет proficient навыков")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsTextDim)
                    .padding()
            }
        }
    }
    
    // MARK: - Inventory
    
    private func inventorySection(_ member: PartyMember) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("ИНВЕНТАРЬ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
                if let inv = member.inventory {
                    Text("\(inv.count) предм.")
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsTextDim)
                }
            }
            .padding(.horizontal, 16)
            
            if let inventory = member.inventory, !inventory.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(inventory.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Image(systemName: iconForItem(item))
                                .font(.system(size: 14))
                                .foregroundColor(Color.dsGoldDim)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.dsText)
                                
                                if !item.description.isEmpty {
                                    Text(item.description)
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.dsTextDim)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            if item.isEquipped {
                                Text("Экип.")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color.dsGold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.dsGold.opacity(0.15))
                                    .cornerRadius(3)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if index < inventory.count - 1 {
                                Rectangle()
                                    .fill(Color.dsBorder)
                                    .frame(height: 0.5)
                            }
                        }
                    }
                }
                .dsCard()
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.system(size: 32))
                        .foregroundColor(Color.dsTextDim.opacity(0.4))
                    Text("Инвентарь пуст")
                        .font(.system(size: 12))
                        .foregroundColor(Color.dsTextDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .dsCard()
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Helpers
private func iconForItem(_ item: InventoryItem) -> String {
    let slotName = String(describing: item.slot).lowercased()
    switch slotName {
    case "none":                          return "square.dashed"
    case let s where s.contains("weapon") || s.contains("sword"): return "sword"
    case let s where s.contains("armor"): return "shield.fill"
    case let s where s.contains("shield"): return "shield.lefthalf.filled"
    case let s where s.contains("head") || s.contains("helm"): return "crown.fill"
    case let s where s.contains("hand") || s.contains("glove"): return "hand.fill"
    case let s where s.contains("feet") || s.contains("boot"): return "figure.walk"
    case let s where s.contains("ring"): return "circle.fill"
    case let s where s.contains("amulet") || s.contains("neck"): return "star.circle.fill"
    case let s where s.contains("consumable") || s.contains("potion"): return "pills.fill"
    case let s where s.contains("scroll"): return "scroll.fill"
    case let s where s.contains("wand") || s.contains("staff"): return "wand.and.stars"
    default:                              return "bag.fill"
    }
}

// MARK: - Вспомогательные компоненты
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let isLast: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.dsGoldDim)
                .font(.system(size: 12))
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.dsText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.dsGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.dsBorder)
                    .frame(height: 0.5)
            }
        }
    }
}

struct StatRow: View {
    let name: String
    let value: Int
    let isLast: Bool
    
    var modifier: Int {
        Constants.Stat.modifier(for: value)
    }
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(Color.dsText)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.dsText)
                .frame(width: 30, alignment: .trailing)
            
            Text(Constants.Stat.formattedModifier(modifier))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.dsGold)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.dsBorder)
                    .frame(height: 0.5)
            }
        }
    }
}
