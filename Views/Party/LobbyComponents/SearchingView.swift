//
//  SearchingView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct SearchingView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var partyManager: PartyManager
        
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(theme.primary.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.3)
                    .opacity(0.3)

                Circle()
                    .stroke(theme.primary.opacity(0.4), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundColor(theme.primary)
            }
            .padding(.vertical, 20)

            VStack(spacing: 8) {
                Text("ПОИСК ПАРТИИ")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(theme.primary)

                Text("Ожидание сигнала от Мастера...")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
                    .multilineTextAlignment(.center)
            }

            if let character = partyManager.selectedCharacter {
                HStack(spacing: 12) {
                    AvatarView(avatarData: character.avatarData, race: character.race, size: 36)
                    VStack(alignment: .leading) {
                        Text("Подключается:")
                            .font(.system(size: 9))
                            .foregroundColor(theme.textDim)
                        Text(character.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.text)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.surfaceAlt)
                .cornerRadius(6)
            }

            Button {
                partyManager.leaveRoom()
                partyManager.clearSelectedCharacter()
            } label: {
                Text("Отмена поиска")
                    .font(.system(size: 13))
                    .foregroundColor(theme.danger)
            }
            .buttonStyle(.plain)
        }
    }
}
