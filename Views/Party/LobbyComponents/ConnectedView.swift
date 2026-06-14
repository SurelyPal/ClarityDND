//
//  ConnectedView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct ConnectedView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var partyManager: PartyManager

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ПАРТИЯ (\(partyManager.partyMembers.count))")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(theme.textDim)
                Spacer()
            }

            VStack(spacing: 4) {
                ForEach(partyManager.partyMembers) { member in
                    PartyMemberRow(member: member)
                        .padding(.vertical, 2)
                }
            }
            .background(theme.surfaceAlt)
            .cornerRadius(6)

            // 🆕 Кнопка перехода на экран мастера (только для ДМ)
            if partyManager.role == .dungeonMaster {
                NavigationLink {
                    DungeonMasterView()
                        .environmentObject(partyManager)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                        Text("Экран мастера")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.primary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Button {
                PlatformCompatibility.hapticNotification(.warning)
                partyManager.leaveRoom()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text("Покинуть партию")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.danger.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
}
