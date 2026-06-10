//
//  SearchingView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct SearchingView: View {
    @ObservedObject var partyManager: PartyManager
        
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.dsGold.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(1.3)
                    .opacity(0.3)

                Circle()
                    .stroke(Color.dsGold.opacity(0.4), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40))
                    .foregroundColor(Color.dsGold)
            }
            .padding(.vertical, 20)

            VStack(spacing: 8) {
                Text("ПОИСК ПАРТИИ")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Color.dsGold)

                Text("Ожидание сигнала от Мастера...")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
                    .multilineTextAlignment(.center)
            }

            if let character = partyManager.selectedCharacter {
                HStack(spacing: 12) {
                    AvatarView(avatarData: character.avatarData, race: character.race, size: 36)
                    VStack(alignment: .leading) {
                        Text("Подключается:")
                            .font(.system(size: 9))
                            .foregroundColor(Color.dsTextDim)
                        Text(character.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.dsText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.dsSurfaceAlt)
                .cornerRadius(6)
            }

            Button {
                partyManager.leaveRoom()
                partyManager.clearSelectedCharacter()
            } label: {
                Text("Отмена поиска")
                    .font(.system(size: 13))
                    .foregroundColor(Color.dsRed)
            }
            .buttonStyle(.plain)
        }
    }
}
