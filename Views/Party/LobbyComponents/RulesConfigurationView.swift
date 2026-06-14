//
//  RulesConfigurationView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//


import SwiftUI

struct RulesConfigurationView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var partyManager: PartyManager
    @State private var draftRules: GameRules = .default

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("НАСТРОЙКА ПРАВИЛ ПАРТИИ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(theme.textDim)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 12))
                    Text("Короткие: \(draftRules.shortRestsAvailable)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.text)
                    Spacer()
                    Stepper("", value: $draftRules.shortRestsAvailable, in: 0...5)
                        .labelsHidden()
                        .tint(.dsGold)
                }

                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 12))
                    Text("Долгие: \(draftRules.longRestsAvailable)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.text)
                    Spacer()
                    Stepper("", value: $draftRules.longRestsAvailable, in: 0...3)
                        .labelsHidden()
                        .tint(.dsGold)
                }
            }
            .padding(12)
            .background(theme.surfaceAlt)
            .cornerRadius(6)

            RuleToggle(
                icon: "pencil.line",
                title: "Редактирование вне партии",
                description: "Игроки могут менять персонажей без подключения к ДМ",
                isOn: $draftRules.canEditCharacterOutsideParty
            )

            Button {
                PlatformCompatibility.hapticNotification(.success)
                partyManager.applyRulesAndStartHosting(draftRules)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Создать комнату")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.primary)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Button {
                partyManager.leaveRoom()
            } label: {
                Text("Отмена")
                    .font(.system(size: 13))
                    .foregroundColor(theme.danger)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            draftRules = partyManager.gameRules
        }
    }
}
