//
//  SkillsTabView.swift
//  Clarity
//

import SwiftUI

struct SkillsTabView: View {
    let character: DNDCharacter
    
    // Список навыков с указанием базовой характеристики
    private static let skillDefinitions: [(name: String, stat: KeyPath<AbilityScores, Int>, abbr: String)] = [
        ("Акробатика",        \.dexterity,      "ЛОВ"),
        ("Анализ",            \.intelligence,   "ИНТ"),
        ("Атлетика",          \.strength,       "СИЛ"),
        ("Восприятие",        \.wisdom,         "МДР"),
        ("Выживание",         \.wisdom,         "МДР"),
        ("Запугивание",       \.charisma,       "ХАР"),
        ("История",           \.intelligence,   "ИНТ"),
        ("Магия",             \.intelligence,   "ИНТ"),
        ("Медицина",          \.wisdom,         "МДР"),
        ("Обман",             \.charisma,       "ХАР"),
        ("Природа",           \.intelligence,   "ИНТ"),
        ("Религия",           \.intelligence,   "ИНТ"),
        ("Скрытность",        \.dexterity,      "ЛОВ"),
        ("Убеждение",         \.charisma,       "ХАР"),
        ("Уход за животными", \.wisdom,         "МДР"),
    ]

    // ✅ Единый источник истины (вместо старого хардкода)
    private func isProficient(_ skillName: String) -> Bool {
        ClassProficiencies.isProficient(skillName, for: character.characterClass)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.skillDefinitions.enumerated()), id: \.offset) { index, skill in
                let proficient = isProficient(skill.name)
                let mod = character.stats.modifier(for: skill.stat)
                let totalMod = mod + (proficient ? character.proficiencyBonus : 0)
                
                SkillRow(
                    name: skill.name,
                    statAbbr: skill.abbr,
                    modifier: totalMod,
                    isProficient: proficient,
                    isLast: index == Self.skillDefinitions.count - 1
                )
            }
        }
        .dsCard()
        .padding(.horizontal, 16)
    }
}

private struct SkillRow: View {
    let name: String
    let statAbbr: String
    let modifier: Int
    let isProficient: Bool
    let isLast: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isProficient ? "diamond.fill" : "diamond")
                .font(.system(size: 7))
                .foregroundColor(isProficient ? Color.dsGold : Color.dsTextDim)
                .frame(width: 16)
            
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(Color.dsText)
            
            Spacer()
            
            Text(statAbbr)
                .font(.system(size: 11))
                .foregroundColor(Color.dsTextDim)
                .frame(width: 30, alignment: .trailing)
            
            Text(Constants.Stat.formattedModifier(modifier))
                .font(.system(size: 14, weight: .medium))
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
                    .padding(.leading, 32)
            }
        }
    }
}

