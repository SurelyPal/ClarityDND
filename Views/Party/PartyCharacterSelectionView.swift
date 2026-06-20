//
//  PartyCharacterSelectionView.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI
import SwiftData

struct PartyCharacterSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let campaign: Campaign
    
    @Query(
        filter: #Predicate<DNDCharacter> { character in
            !character.isDeleted
        },
        sort: \DNDCharacter.name
    ) private var characters: [DNDCharacter]
    
    @State private var selectedCharacter: DNDCharacter?
    @State private var showingCompatibilityAlert = false
    @State private var alertMessage = ""
    
    private let partyManager = PartyManager.shared
    
    // Шаблон кампании
    private var campaignTemplate: GameTemplate? {
        campaign.gameTemplate
    }
    
    // Совместимые персонажи
    private var compatibleCharacters: [DNDCharacter] {
        characters.filter { isCompatible($0) }
    }
    
    // Несовместимые персонажи
    private var incompatibleCharacters: [DNDCharacter] {
        characters.filter { !isCompatible($0) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    headerSection
                    
                    if characters.isEmpty {
                        emptyState
                    } else {
                        characterList
                    }
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
                    Text("Выбор персонажа")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            .alert("Несовместимый персонаж", isPresented: $showingCompatibilityAlert) {
                Button("Понятно", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("✦ ПОДКЛЮЧЕНИЕ ✦")
                .font(.system(size: 9, weight: .medium))
                .tracking(3)
                .foregroundColor(theme.primaryDim)
            
            Text("К кампании: \(campaign.name)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.primary)
            
            if let template = campaignTemplate {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12))
                    Text("Шаблон: \(template.name)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(theme.textDim)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                    Text("Без шаблона")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(theme.textDim)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(theme.primaryDim.opacity(0.5))
            
            Text("Нет персонажей")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("Создайте персонажа, чтобы присоединиться к партии")
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.circle.fill")
                    Text("Вернуться назад")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.primary)
                .foregroundColor(theme.background)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var characterList: some View {
        List {
            // Совместимые персонажи
            if !compatibleCharacters.isEmpty {
                Section {
                    ForEach(compatibleCharacters) { character in
                        PartyCharacterRowView(
                            character: character,
                            isCompatible: true,
                            isSelected: selectedCharacter?.id == character.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectCharacter(character)
                        }
                        .listRowBackground(theme.surface)
                    }
                } header: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Совместимые персонажи")
                            .foregroundColor(theme.text)
                        
                        Spacer()
                        
                        Text("\(compatibleCharacters.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textDim)
                    }
                }
            }
            
            // Несовместимые персонажи
            if !incompatibleCharacters.isEmpty {
                Section {
                    ForEach(incompatibleCharacters) { character in
                        PartyCharacterRowView(
                            character: character,
                            isCompatible: false,
                            isSelected: false
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showIncompatibilityReason(for: character)
                        }
                        .listRowBackground(theme.surface)
                    }
                } header: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Несовместимые персонажи")
                            .foregroundColor(theme.text)
                        
                        Spacer()
                        
                        Text("\(incompatibleCharacters.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textDim)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }
    
    // MARK: - Actions
    
    private func isCompatible(_ character: DNDCharacter) -> Bool {
        // Если у кампании нет шаблона — любой персонаж совместим
        guard let campaignTemplateID = campaignTemplate?.id else {
            return true
        }
        
        // Если у персонажа нет шаблона, а у кампании есть — несовместим
        guard let characterTemplateID = character.templateID else {
            return false
        }
        
        // Сравниваем ID шаблонов
        return characterTemplateID == campaignTemplateID
    }
    
    private func selectCharacter(_ character: DNDCharacter) {
        selectedCharacter = character
        PlatformCompatibility.hapticImpact(.medium)
        
        // Присоединяемся к партии
        joinParty(with: character)
    }
    
    private func showIncompatibilityReason(for character: DNDCharacter) {
        PlatformCompatibility.hapticNotification(.error)
        
        if let campaignTemplate = campaignTemplate {
            if character.templateID == nil {
                alertMessage = "Персонаж '\(character.name)' создан без шаблона, а кампания использует шаблон '\(campaignTemplate.name)'. Выберите другого персонажа или создайте нового с нужным шаблоном."
            } else {
                alertMessage = "Персонаж '\(character.name)' создан по другому шаблону. Эта кампания использует шаблон '\(campaignTemplate.name)'. Выберите совместимого персонажа."
            }
        } else {
            alertMessage = "Не удалось определить шаблон кампании. Обратитесь к Гейм Мастеру."
        }
        
        showingCompatibilityAlert = true
    }
    
    private func joinParty(with character: DNDCharacter) {
        // Здесь вызываем PartyManager для присоединения к партии
        // Точный метод зависит от вашей реализации PartyManager
        
        // Пример (замените на ваш реальный метод):
        // partyManager.joinParty(character: character, campaign: campaign)
        
        // Временное решение — просто закрываем экран
        dismiss()
        
        SoundManager.shared.play(.levelUp, haptic: .success)
    }
}

// MARK: - Строка персонажа для выбора в партии

struct PartyCharacterRowView: View {
    @Environment(\.theme) private var theme
    let character: DNDCharacter
    let isCompatible: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Аватар
            ZStack {
                Circle()
                    .fill(isCompatible ? theme.primary.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                if let avatarData = character.avatarData {
                    #if os(iOS)
                    if let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        defaultAvatar
                    }
                    #else
                    if let nsImage = NSImage(data: avatarData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
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
                Text(character.name.isEmpty ? "Без имени" : character.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(character.race.rawValue)
                        .font(.system(size: 12))
                    
                    Text("·")
                    
                    Text(character.characterClass.rawValue)
                        .font(.system(size: 12))
                    
                    Text("·")
                    
                    Text("Ур. \(character.level)")
                        .font(.system(size: 12))
                }
                .foregroundColor(theme.textDim)
            }
            
            Spacer()
            
            // Индикатор совместимости
            VStack(alignment: .trailing, spacing: 4) {
                if isCompatible {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    Text("Несовместим")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(isCompatible ? 1.0 : 0.6)
    }
    
    private var defaultAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 20))
            .foregroundColor(isCompatible ? theme.primary : .red)
    }
}

// MARK: - Preview

#Preview {
    PartyCharacterSelectionView(campaign: Campaign(name: "Тестовая кампания"))
        .modelContainer(for: [DNDCharacter.self, Campaign.self, GameTemplate.self], inMemory: true)
}
