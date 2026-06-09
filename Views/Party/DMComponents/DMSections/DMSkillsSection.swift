//
//  DMSkillsSection.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//


//
//  DMSkillsSection.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct DMSkillsSection: View {
    let member: PartyMember
    
    var body: some View {
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
}