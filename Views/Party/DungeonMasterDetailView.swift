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
                    DMDetailHeader(member: member)
                    DMBasicInfoSection(member: member)
                    DMStatsSection(member: member)
                    DMSkillsSection(member: member)
                    DMInventorySection(member: member)
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
}
