//
//  PartyMemberRow.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct PartyMemberRow: View {
    let member: PartyMember

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarData: member.avatarData, race: member.race, size: 44)
                
                Circle()
                    .fill(member.isConnected ? Color.green : Color.dsRed)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(Color.dsSurface, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(member.isCharacterDeleted ? Color.dsTextDim.opacity(0.5) : (member.isConnected ? Color.dsText : Color.dsTextDim.opacity(0.6)))

                    // ✅ НОВАЯ ЛОГИКА: Проверяем isCharacterDeleted ПЕРЕД isConnected
                    if member.isCharacterDeleted {
                        HStack(spacing: 3) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 7))
                            Text("ПЕРСОНАЖ УДАЛЕН")
                                .font(.system(size: 7, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.dsRed.opacity(0.85))
                        .cornerRadius(3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.dsRed.opacity(0.6), lineWidth: 1)
                        )
                    } else if !member.isConnected {
                        Text("ОФЛАЙН")
                            .font(.system(size: 7, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(Color.dsRed)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.dsRed.opacity(0.15))
                            .cornerRadius(2)
                    }
                }

                Text("\(member.race.rawValue) · \(member.characterClass)")
                    .font(.system(size: 11))
                    .foregroundColor(member.isCharacterDeleted ? Color.dsTextDim.opacity(0.4) : Color.dsTextDim.opacity(member.isConnected ? 1.0 : 0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("Веха \(member.level)")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color.dsGold)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.dsRed)
                    Text("\(member.currentHP)/\(member.maxHP)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(hpColor)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(member.isConnected ? 1.0 : 0.7)  // ✅ Было 0.6, стало 0.7 — offline видно, но приглушён
    }
    
    private var hpColor: Color {
        let fraction = member.hpFraction
        if fraction > 0.5 { return Color.dsGold }
        if fraction > 0.25 { return .orange }
        return Color.dsRed
    }
}
