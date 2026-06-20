//
//  RoleSelectionView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct RoleSelectionView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var partyManager: PartyManager

    var body: some View {
        VStack(spacing: 16) {
            // Кнопка для Гейм Мастера — выбрать кампанию
            NavigationLink {
                CampaignSelectionView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 16))
                    Text("ВЫБРАТЬ КАМПАНИЮ")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                }
                .foregroundColor(.dsBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.primary)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)

            // Кнопка для Игрока — тоже ведёт к выбору кампании
            NavigationLink {
                CampaignSelectionView()
            } label: {
                VStack(spacing: 12) {
                    Text("🗡️").font(.system(size: 40))
                    Text("ИГРОК")
                        .font(.system(size: 14, weight: .semibold)).tracking(1.5)
                        .foregroundColor(theme.text)
                    Text("Выбрать персонажа и подключиться к Мастеру")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textDim)
                        .multilineTextAlignment(.center)
                }
                .padding(20).frame(maxWidth: .infinity)
                .background(theme.surfaceAlt)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.border, lineWidth: 1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    RoleSelectionView(partyManager: PartyManager.shared)
}
