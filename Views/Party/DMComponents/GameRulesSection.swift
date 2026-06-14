//
//  GameRulesSection.swift
//  Clarity
//
//  Created by KEBAB on 14.06.2026.
//


//
// GameRulesSection.swift
// Clarity
//
// Created for Game Rules tab in DungeonMasterView
//

import SwiftUI

// MARK: - Секция правил игры для экрана мастера

struct GameRulesSection: View {
    @ObservedObject var partyManager: PartyManager
    @State private var showingRulesEditor = false
    @State private var draftRules: GameRules = .default
    
    var body: some View {
        VStack(spacing: 12) {
            // Заголовок секции
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Color.dsGold)
                    .font(.system(size: 14))
                
                Text("ПРАВИЛА ИГРЫ")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Color.dsGold)
                
                Spacer()
                
                Button {
                    draftRules = partyManager.gameRules
                    showingRulesEditor = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                        Text("Изменить")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color.dsGold)
                }
                .buttonStyle(.plain)
            }
            
            // Отображение текущих правил
            VStack(spacing: 8) {
                // Короткие отдыхи
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundColor(Color.dsGold)
                        .font(.system(size: 12))
                    
                    Text("Короткие отдыхи")
                        .font(.system(size: 12))
                        .foregroundColor(Color.dsText)
                    
                    Spacer()
                    
                    Text("\(partyManager.gameRules.shortRestsAvailable) / \(partyManager.gameRules.maxShortRests)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.dsGold)
                }
                
                DSdivider()
                    .padding(.horizontal, 4)
                
                // Долгие отдыхи
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(Color.dsGold)
                        .font(.system(size: 12))
                    
                    Text("Долгие отдыхи")
                        .font(.system(size: 12))
                        .foregroundColor(Color.dsText)
                    
                    Spacer()
                    
                    Text("\(partyManager.gameRules.longRestsAvailable) / \(partyManager.gameRules.maxLongRests)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.dsGold)
                }
                
                DSdivider()
                    .padding(.horizontal, 4)
                
                // Редактирование вне партии
                HStack(spacing: 8) {
                    Image(systemName: "pencil.line")
                        .foregroundColor(Color.dsGold)
                        .font(.system(size: 12))
                    
                    Text("Редактирование вне партии")
                        .font(.system(size: 12))
                        .foregroundColor(Color.dsText)
                    
                    Spacer()
                    
                    Image(systemName: partyManager.gameRules.canEditCharacterOutsideParty ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(partyManager.gameRules.canEditCharacterOutsideParty ? .green : Color.dsRed)
                }
            }
            .padding(12)
            .background(Color.dsSurface)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.dsBorder, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingRulesEditor) {
            GameRulesEditorView(
                partyManager: partyManager,
                draftRules: $draftRules
            )
        }
    }
}

// MARK: - Редактор правил игры (модальное окно)

struct GameRulesEditorView: View {
    @ObservedObject var partyManager: PartyManager
    @Binding var draftRules: GameRules
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Секция отдыхов
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ЛИМИТЫ ОТДЫХОВ")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(Color.dsTextDim)
                            
                            VStack(spacing: 12) {
                                // Максимум коротких отдыхов
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Макс. коротких")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.dsText)
                                        Text("За одну сессию")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.dsTextDim)
                                    }
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        value: $draftRules.maxShortRests,
                                        in: 0...5
                                    ) {
                                        Text("\(draftRules.maxShortRests)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.dsGold)
                                    }
                                    .labelsHidden()
                                    
                                    Text("\(draftRules.maxShortRests)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.dsGold)
                                        .frame(width: 30)
                                }
                                
                                DSdivider()
                                
                                // Максимум долгих отдыхов
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Макс. долгих")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.dsText)
                                        Text("За одну сессию")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.dsTextDim)
                                    }
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        value: $draftRules.maxLongRests,
                                        in: 0...3
                                    ) {
                                        Text("\(draftRules.maxLongRests)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.dsGold)
                                    }
                                    .labelsHidden()
                                    
                                    Text("\(draftRules.maxLongRests)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.dsGold)
                                        .frame(width: 30)
                                }
                            }
                            .padding(12)
                            .background(Color.dsSurface)
                            .cornerRadius(6)
                        }
                        
                        // Секция доступных отдыхов
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ДОСТУПНО СЕЙЧАС")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(Color.dsTextDim)
                            
                            VStack(spacing: 12) {
                                // Доступно коротких
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Коротких осталось")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.dsText)
                                        Text("Можно использовать")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.dsTextDim)
                                    }
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        value: $draftRules.shortRestsAvailable,
                                        in: 0...draftRules.maxShortRests
                                    ) {
                                        Text("\(draftRules.shortRestsAvailable)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.dsGold)
                                    }
                                    .labelsHidden()
                                    
                                    Text("\(draftRules.shortRestsAvailable)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.dsGold)
                                        .frame(width: 30)
                                }
                                
                                DSdivider()
                                
                                // Доступно долгих
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Долгих осталось")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.dsText)
                                        Text("Можно использовать")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.dsTextDim)
                                    }
                                    
                                    Spacer()
                                    
                                    Stepper(
                                        value: $draftRules.longRestsAvailable,
                                        in: 0...draftRules.maxLongRests
                                    ) {
                                        Text("\(draftRules.longRestsAvailable)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.dsGold)
                                    }
                                    .labelsHidden()
                                    
                                    Text("\(draftRules.longRestsAvailable)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color.dsGold)
                                        .frame(width: 30)
                                }
                            }
                            .padding(12)
                            .background(Color.dsSurface)
                            .cornerRadius(6)
                        }
                        
                        // Переключатель редактирования
                        RuleToggle(
                            icon: "pencil.line",
                            title: "Редактирование вне партии",
                            description: "Игроки могут менять персонажей без подключения к ДМ",
                            isOn: $draftRules.canEditCharacterOutsideParty
                        )
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Настройка правил")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(Color.dsGold)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveRules()
                        dismiss()
                    }
                    .foregroundColor(Color.dsGold)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveRules() {
        PlatformCompatibility.hapticNotification(.success)
        
        // Обновляем правила в PartyManager
        partyManager.gameRules = draftRules
        
        // 🔥 КРИТИЧНО: Сохраняем изменения в активную кампанию
        if let campaignID = partyManager.currentCampaignID,
           let index = CampaignManager.shared.campaigns.firstIndex(where: { $0.id == campaignID }) {
            var updatedCampaign = CampaignManager.shared.campaigns[index]
            updatedCampaign.gameRules = draftRules
            updatedCampaign.lastPlayedAt = Date()
            
            // Сохраняем в файл через CampaignManager
            CampaignManager.shared.saveCampaign(updatedCampaign)
            
            print("✅ Правила игры сохранены в кампанию: \(updatedCampaign.name)")
        }
    }
}