//
//  HostingView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct HostingView: View {
    @Environment(\.theme) private var theme
    // ✅ НОВОЕ (для @Observable)
    @State var partyManager = PartyManager.shared
    let roomCode: String

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("КОМНАТА СОЗДАНА")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(theme.textDim)

                HStack(spacing: 6) {
                    ForEach(Array(roomCode.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(theme.primary)
                            .frame(width: 42, height: 56)
                            .background(theme.surfaceAlt)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(theme.primary.opacity(0.4), lineWidth: 1)
                            )
                    }
                }

                Text("Покажите этот код игрокам")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("ИГРОКИ (\(partyManager.partyMembers.count))")
                        .font(.system(size: 10))
                        .tracking(2)
                        .foregroundColor(theme.textDim)
                    Spacer()
                }

                if partyManager.partyMembers.isEmpty {
                    HStack {
                        ProgressView()
                            .tint(.dsGold)
                        Text("Ожидание подключения...")
                            .font(.system(size: 11))
                            .foregroundColor(theme.textDim)
                    }
                    .padding(.vertical, 16)
                } else {
                    VStack(spacing: 4) {
                        ForEach(partyManager.partyMembers) { member in
                            PartyMemberRow(member: member)
                                .padding(.vertical, 2)
                        }
                    }
                    .background(theme.surfaceAlt)
                    .cornerRadius(6)
                }
            }

            //   Кнопка перехода на экран мастера
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

            Button {
                PlatformCompatibility.hapticNotification(.warning)
                partyManager.endCampaignSession()
            } label: {
                HStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                        Text("Завершить сессию")
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
