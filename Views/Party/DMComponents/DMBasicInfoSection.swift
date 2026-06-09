//
//  DMBasicInfoSection.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//


//
//  DMBasicInfoSection.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct DMBasicInfoSection: View {
    let member: PartyMember
    
    var body: some View {
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
}