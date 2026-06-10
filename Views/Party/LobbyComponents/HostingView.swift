//
//  HostingView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct HostingView: View {
    @ObservedObject var partyManager: PartyManager
    let roomCode: String

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("КОМНАТА СОЗДАНА")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)

                HStack(spacing: 6) {
                    ForEach(Array(roomCode.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(Color.dsGold)
                            .frame(width: 42, height: 56)
                            .background(Color.dsSurfaceAlt)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.dsGold.opacity(0.4), lineWidth: 1)
                            )
                    }
                }

                Text("Покажите этот код игрокам")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("ИГРОКИ (\(partyManager.partyMembers.count))")
                        .font(.system(size: 10))
                        .tracking(2)
                        .foregroundColor(Color.dsTextDim)
                    Spacer()
                }

                if partyManager.partyMembers.isEmpty {
                    HStack {
                        ProgressView()
                            .tint(.dsGold)
                        Text("Ожидание подключения...")
                            .font(.system(size: 11))
                            .foregroundColor(Color.dsTextDim)
                    }
                    .padding(.vertical, 16)
                } else {
                    VStack(spacing: 4) {
                        ForEach(partyManager.partyMembers) { member in
                            PartyMemberRow(member: member)
                                .padding(.vertical, 2)
                        }
                    }
                    .background(Color.dsSurfaceAlt)
                    .cornerRadius(6)
                }
            }

            // 🆕 Кнопка перехода на экран мастера
            NavigationLink {
                DungeonMasterView()
                    .environmentObject(partyManager)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                    Text("Экран мастера")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.dsBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dsGold)
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
                .foregroundColor(Color.dsRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dsSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.dsRed.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
}
