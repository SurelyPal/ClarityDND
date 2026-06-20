//
//  ArchivedCharactersView.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI
import SwiftData

// MARK: - Экран архива персонажей

struct ArchivedCharactersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    
    // Загружаем архивированных персонажей
    @Query(sort: \ArchivedCharacter.characterName) private var archivedCharacters: [ArchivedCharacter]
    
    // Загружаем все шаблоны для проверки доступности
    @Query private var allTemplates: [GameTemplate]
    
    @State private var viewModel = ArchivedCharactersViewModel()
    private let campaignManager = CampaignManager.shared
    
    // Состояния для алертов и модальных окон
    @State private var characterToRestore: ArchivedCharacter?
    @State private var showingRestoreCampaignPicker = false
    @State private var characterToDelete: ArchivedCharacter?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                if archivedCharacters.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(archivedCharacters) { character in
                            ArchivedCharacterRowView(
                                character: character,
                                canRestore: viewModel.canRestore(character, templates: allTemplates),
                                onRestore: { prepareRestore(character) },
                                onDelete: { prepareDelete(character) }
                            )
                            .listRowBackground(theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.sidebar)
                    #endif
                }
            }
            .navigationTitle("📦 Архив персонажей")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                campaignManager.setup(context: modelContext)
            }
            // Модальное окно для выбора кампании при восстановлении
            .sheet(isPresented: $showingRestoreCampaignPicker) {
                if let character = characterToRestore {
                    RestoreCampaignPickerView(character: character)
                }
            }
            // Алерт подтверждения удаления
            .alert("Удалить персонажа?", isPresented: $showingDeleteConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) {
                    if let character = characterToDelete {
                        viewModel.deleteCharacter(character, context: modelContext)
                    }
                }
            } message: {
                if let character = characterToDelete {
                    Text("Персонаж '\(character.characterName)' будет удален из архива безвозвратно.")
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 50))
                .foregroundColor(.dsGold.opacity(0.5))
            
            Text("Архив пуст")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.dsText)
            
            Text("Здесь будут храниться персонажи из завершённых или удалённых кампаний.")
                .font(.subheadline)
                .foregroundColor(.dsTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func prepareRestore(_ character: ArchivedCharacter) {
        characterToRestore = character
        showingRestoreCampaignPicker = true
    }
    
    private func prepareDelete(_ character: ArchivedCharacter) {
        characterToDelete = character
        showingDeleteConfirmation = true
    }
}

// MARK: - ViewModel для архива

@Observable
class ArchivedCharactersViewModel {
    
    /// Проверяет, доступен ли шаблон для восстановления персонажа
    func canRestore(_ character: ArchivedCharacter, templates: [GameTemplate]) -> Bool {
        // Если у персонажа есть ID шаблона, проверяем его наличие в базе
        if let templateID = character.originalTemplateID {
            return templates.contains { $0.id == templateID }
        }
        // Если ID нет, но есть флаг canRestore
        return character.canRestore
    }
    
    /// Восстанавливает персонажа в выбранную кампанию
    func restoreCharacter(_ character: ArchivedCharacter, to campaign: Campaign, context: ModelContext) {
        // Вызываем метод CampaignManager
        CampaignManager.shared.restoreCharacter(character, to: campaign, context: context)
        PlatformCompatibility.hapticNotification(.success)
    }
    
    /// Удаляет персонажа из архива
    func deleteCharacter(_ character: ArchivedCharacter, context: ModelContext) {
        context.delete(character)
        try? context.save()
        PlatformCompatibility.hapticNotification(.success)
    }
}

// MARK: - Строка архивированного персонажа

struct ArchivedCharacterRowView: View {
    @Environment(\.theme) private var theme
    let character: ArchivedCharacter
    let canRestore: Bool
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Верхняя часть: аватар и основная информация
            HStack(spacing: 12) {
                // Аватар
                ZStack {
                    Circle()
                        .fill(theme.surface.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    if let avatarData = character.avatarData {
                        #if os(iOS)
                        if let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            defaultAvatar
                        }
                        #else
                        if let nsImage = NSImage(data: avatarData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            defaultAvatar
                        }
                        #endif
                    } else {
                        defaultAvatar
                    }
                }
                
                // Информация
                VStack(alignment: .leading, spacing: 4) {
                    Text(character.characterName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.dsText)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Уровень (Int)
                        Text("Ур. \(character.characterLevel)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.dsGold)
                        
                        // Раса (enum Race)
                        Text(String(describing: character.characterRace))
                            .font(.system(size: 12))
                            .foregroundColor(.dsTextDim)
                        
                        // Класс (enum CharacterClass)
                        Text(String(describing: character.characterClass))
                            .font(.system(size: 12))
                            .foregroundColor(.dsTextDim)
                    }
                    
                    Text("Из кампании: \(character.originalCampaignName)")
                        .font(.system(size: 11))
                        .foregroundColor(.dsTextDim)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            // Разделитель
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
            
            // Статус шаблона
            HStack {
                if canRestore {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Шаблон доступен")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Шаблон недоступен")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            // Кнопки действий
            HStack(spacing: 12) {
                if canRestore {
                    Button(action: onRestore) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                            Text("Восстановить")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.dsGold)
                        .foregroundColor(.black)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: onDelete) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Удалить")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: canRestore ? .infinity : .infinity)
                    .padding(.vertical, 10)
                    .background(theme.surface.opacity(0.5))
                    .foregroundColor(.red)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(theme.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
    
    private var defaultAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 24))
            .foregroundColor(.dsGold)
    }
}

// MARK: - Экран выбора кампании для восстановления

struct RestoreCampaignPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let character: ArchivedCharacter
    
    @Query(sort: \Campaign.name) private var allCampaigns: [Campaign]
    private let campaignManager = CampaignManager.shared
    
    // Фильтруем только кампании, где текущий пользователь является владельцем
    private var availableCampaigns: [Campaign] {
        guard let currentPlayer = campaignManager.currentPlayer else { return [] }
        return allCampaigns.filter { $0.owner?.id == currentPlayer.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text("Восстановить персонажа")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.dsGold)
                        
                        Text("Выберите кампанию для \(character.characterName)")
                            .font(.system(size: 14))
                            .foregroundColor(.dsTextDim)
                    }
                    .padding()
                    
                    // Список кампаний
                    if availableCampaigns.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(.dsTextDim.opacity(0.5))
                            
                            Text("Нет доступных кампаний")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.dsText)
                            
                            Text("Создайте новую кампанию, чтобы восстановить персонажа")
                                .font(.system(size: 12))
                                .foregroundColor(.dsTextDim)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(availableCampaigns) { campaign in
                                Button {
                                    restoreToCampaign(campaign)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(campaign.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.dsText)
                                            
                                            if let template = campaign.gameTemplate {
                                                Text("Шаблон: \(template.name)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.dsTextDim)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.dsTextDim)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(theme.surface)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        #if os(iOS)
                        .listStyle(.insetGrouped)
                        #else
                        .listStyle(.sidebar)
                        #endif
                    }
                }
            }
            .navigationTitle("Выбор кампании")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.dsGold)
                }
            }
            .task {
                campaignManager.setup(context: modelContext)
            }
        }
    }
    
    private func restoreToCampaign(_ campaign: Campaign) {
        let viewModel = ArchivedCharactersViewModel()
        viewModel.restoreCharacter(character, to: campaign, context: modelContext)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ArchivedCharactersView()
        .modelContainer(for: [ArchivedCharacter.self, GameTemplate.self, Campaign.self, Player.self], inMemory: true)
}
