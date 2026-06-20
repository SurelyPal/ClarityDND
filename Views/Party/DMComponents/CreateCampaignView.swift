//
//  CreateCampaignView.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI
import SwiftData

struct CreateCampaignView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    // Загружаем все шаблоны
    @Query(sort: \GameTemplate.name) private var allTemplates: [GameTemplate]
    
    // Состояния формы
    @State private var campaignName = ""
    @State private var selectedTemplate: GameTemplate?
    
    private let campaignManager = CampaignManager.shared
    private let partyManager = PartyManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    headerSection
                    
                    // Форма
                    ScrollView {
                        VStack(spacing: 20) {
                            // Название кампании
                            nameSection
                            
                            DSdivider()
                            
                            // Выбор шаблона
                            templateSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    Spacer()
                    
                    // Кнопка создания
                    createButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Новая кампания")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("✦ СОЗДАНИЕ ✦")
                .font(.system(size: 9, weight: .medium))
                .tracking(3)
                .foregroundColor(theme.primaryDim)
            
            Text("Новая Кампания")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.primary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Название кампании")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text("Дайте запоминающееся название вашей игре")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
            }
            
            TextField("Например: Проклятие Страдальца", text: $campaignName)
                .textFieldStyle(.plain)
                .padding(12)
                .background(theme.surface)
                .foregroundColor(theme.text)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
        }
    }
    
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Шаблон игры")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text("Выберите систему правил для этой кампании")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
            }
            
            if allTemplates.isEmpty {
                emptyTemplatesState
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(allTemplates) { template in
                        TemplateSelectionCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        )
                        .onTapGesture {
                            selectedTemplate = template
                            SoundManager.shared.play(.pageTurn, haptic: .light)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyTemplatesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(theme.textDim.opacity(0.5))
            
            Text("Шаблонов пока нет")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("Создайте шаблон в настройках, чтобы начать кампанию")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
            
            NavigationLink {
                TemplateManagementView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                    Text("Перейти к шаблонам")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(theme.primary)
                .foregroundColor(theme.background)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(theme.surface.opacity(0.5))
        .cornerRadius(8)
    }
    
    private var createButton: some View {
        Button {
            createCampaign()
        } label: {
            HStack {
                Text("Создать кампанию")
                Image(systemName: "checkmark")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                canCreate ? theme.primary : theme.primary.opacity(0.3)
            )
            .foregroundColor(theme.background)
            .font(.system(size: 16, weight: .medium))
            .cornerRadius(3)
        }
        .buttonStyle(.plain)
        .disabled(!canCreate)
    }
    
    // MARK: - Logic
    
    private var canCreate: Bool {
        !campaignName.trimmingCharacters(in: .whitespaces).isEmpty && selectedTemplate != nil
    }
    
    private func createCampaign() {
        let trimmedName = campaignName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, let template = selectedTemplate else { return }
        
        // Создаём кампанию через CampaignManager
        let campaign = campaignManager.createCampaign(name: trimmedName, context: modelContext)
        
        // 🆕 ВАЖНО: Привязываем выбранный шаблон к кампании
        campaign.gameTemplate = template
        
        // Сохраняем изменения
        try? modelContext.save()
        
        PlatformCompatibility.hapticNotification(.success)
        SoundManager.shared.play(.levelUp, haptic: .success)
        
        // Запускаем хостинг новой кампании
        partyManager.startHosting(campaign: campaign)
        
        // Закрываем экран
        dismiss()
    }
}

// MARK: - Карточка выбора шаблона

struct TemplateSelectionCard: View {
    @Environment(\.theme) private var theme
    let template: GameTemplate
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? theme.background : theme.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.background)
                }
                
                if template.isBuiltIn {
                    Text("БАЗА")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(theme.primary.opacity(0.3))
                        .foregroundColor(theme.primary)
                        .cornerRadius(3)
                }
            }
            
            Text(template.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? theme.background : theme.text)
                .lineLimit(1)
            
            Text(template.templateDescription.isEmpty ? "Без описания" : template.templateDescription)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? theme.background.opacity(0.8) : theme.textDim)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Статистика шаблона
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 10))
                    Text("\(template.fieldDefinitions.count)")
                        .font(.system(size: 11, weight: .medium))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 10))
                    Text("мех.")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundColor(isSelected ? theme.background.opacity(0.7) : theme.textDim)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? theme.primary : theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? theme.primary : theme.border,
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    CreateCampaignView()
        .modelContainer(for: [GameTemplate.self, Campaign.self, Player.self], inMemory: true)
}
