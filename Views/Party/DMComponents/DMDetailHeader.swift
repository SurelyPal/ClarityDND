//
//  DMDetailHeader.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct DMDetailHeader: View {
    @Environment(\.theme) private var theme
    let member: PartyMember
    
    var body: some View {
        VStack(spacing: 12) {
            AvatarView(avatarData: member.avatarData, race: member.race, size: 100)
            
            Text(member.name)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(theme.primary)
            
            Text("\(member.race.rawValue) · \(member.characterClass)")
                .font(.system(size: 13))
                .foregroundColor(theme.textDim)
            
            // HP бар
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.surfaceAlt)
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
                        .foregroundColor(theme.danger)
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
}
