//
//  CampaignSelectionView.swift
//  Clarity
//
//  Created by KEBAB on 10.06.2026.
//

import SwiftData
import SwiftUI

// MARK: - Экран выбора кампании для ДМа

struct CampaignSelectionView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    // ✅ НОВОЕ: получаем кампании напрямую из SwiftData через @Query
    @Query(sort: \Campaign.lastPlayedAt, order: .reverse)
    private var campaigns: [Campaign]
    
    // CampaignManager нужен только для действий (создание, удаление)
    @ObservedObject private var campaignManager = CampaignManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewCampaignAlert = false
    @State private var newCampaignName = ""
    @State private var campaignToDelete: Campaign?
    @State private var showingDeleteConfirmation = false
    @State private var showingRenameAlert = false
    @State private var campaignToRename: Campaign?
    @State private var renameText = ""
    
    private let partyManager = PartyManager.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон в стиле Dark Souls
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // Заголовок
                    headerSection
                    
                    // Список кампаний или пустое состояние
                    if campaigns.isEmpty {
                        emptyStateView
                    } else {
                        campaignsList
                    }
                    
                    Spacer()
                    
                    // Кнопка создания новой кампании (прижата к низу)
                    createButton
                }
            }
            
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
            // Alert для создания новой кампании
            .alert("Новая кампания", isPresented: $showingNewCampaignAlert) {
                TextField("Название кампании", text: $newCampaignName)
                
                Button("Отмена", role: .cancel) {
                    newCampaignName = ""
                }
                
                Button("Создать") {
                    createNewCampaign()
                }
                .disabled(newCampaignName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Введите название новой кампании")
            }
            // Alert для подтверждения удаления
            .alert("Удалить кампанию?", isPresented: $showingDeleteConfirmation) {
                Button("Отмена", role: .cancel) {}
                
                Button("Удалить", role: .destructive) {
                    if let campaign = campaignToDelete {
                        campaignManager.deleteCampaign(campaign, context: modelContext)
                        PlatformCompatibility.hapticNotification(.success)
                    }
                }
            } message: {
                if let campaign = campaignToDelete {
                    Text("Кампания '\(campaign.name)' будет удалена безвозвратно.")
                }
            }
            // Alert для переименования
            .alert("Переименовать кампанию", isPresented: $showingRenameAlert) {
                TextField("Новое название", text: $renameText)
                
                Button("Отмена", role: .cancel) {}
                
                Button("Сохранить") {
                    if let campaign = campaignToRename {
                        campaignManager.renameCampaign(campaign, to: renameText, context: modelContext)
                    }
                }
            }
        }
    }
    
    // MARK: - Секции UI
    
    /// Заголовок с орнаментами в стиле Dark Souls
    private var headerSection: some View {
        VStack(spacing: 12) {
            CornerOrnaments()
                .frame(height: 20)
            
            Text("ВЫБЕРИТЕ КАМПАНИЮ")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.dsGold)
                .tracking(2)
            
            Text("Начните новую сессию или продолжите существующую")
                .font(.system(size: 12))
                .foregroundColor(.dsTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            DSdivider()
                .padding(.horizontal, 40)
                .padding(.top, 4)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    /// Пустое состояние (когда ещё нет ни одной кампании)
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(.dsGold.opacity(0.5))
            
            Text("Нет кампаний")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.dsText)
            
            Text("Создайте свою первую кампанию,\nчтобы начать приключение")
                .font(.system(size: 14))
                .foregroundColor(.dsTextDim)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    /// Список существующих кампаний
    private var campaignsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(campaigns) { campaign in
                    CampaignRowView(
                        campaign: campaign,
                        onStart: { startCampaign(campaign) },
                        onRename: { prepareRename(campaign) },
                        onDelete: { prepareDelete(campaign) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100) // Отступ для кнопки создания внизу
        }
    }
    
    /// Кнопка создания новой кампании
    private var createButton: some View {
        Button {
            PlatformCompatibility.hapticImpact(.medium)
            newCampaignName = ""
            showingNewCampaignAlert = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                
                Text("СОЗДАТЬ НОВУЮ КАМПАНИЮ")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(.dsBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.dsGold, .dsGold.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
            .shadow(color: .dsGold.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            theme.surface
                .shadow(color: .black.opacity(0.5), radius: 10, y: -5)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Методы действий
    
    /// Создаёт новую кампанию и автоматически начинает её хостинг
    private func createNewCampaign() {
        let trimmedName = newCampaignName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        // ✅ ИСПРАВЛЕНО: используем trimmedName и newCampaign
        let newCampaign = campaignManager.createCampaign(
            name: trimmedName,  // ← было campaignName
            context: modelContext
        )
        
        PlatformCompatibility.hapticNotification(.success)
        
        // ✅ ИСПРАВЛЕНО: передаём newCampaign
        startCampaign(newCampaign)  // ← было campaign
        
        newCampaignName = ""
    }
    
    /// Начинает хостинг выбранной кампании
    private func startCampaign(_ campaign: Campaign) {
        PlatformCompatibility.hapticImpact(.heavy)
        
        // Запускаем хостинг через PartyManager
        partyManager.startHosting(campaign: campaign)
        
        // Закрываем экран выбора
        dismiss()
    }
    
    /// Подготавливает переименование кампании
    private func prepareRename(_ campaign: Campaign) {
        campaignToRename = campaign
        renameText = campaign.name
        showingRenameAlert = true
    }
    
    /// Подготавливает удаление кампании
    private func prepareDelete(_ campaign: Campaign) {
        campaignToDelete = campaign
        showingDeleteConfirmation = true
    }
}

// MARK: - Строка кампании (отдельный компонент)

struct CampaignRowView: View {
    @Environment(\.theme) private var theme
    let campaign: Campaign
    let onStart: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @State private var showingMenu = false
    
    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: 10) {
                
                // Верхняя строка: название и кнопка меню
                HStack {
                    Text(campaign.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.dsText)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        PlatformCompatibility.hapticImpact(.light)
                        showingMenu = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.dsGold)
                    }
                    .buttonStyle(.plain)
                }
                
                // Тонкий разделитель
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
                
                // Информационная строка
                HStack {
                    // Количество игроков
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text(campaign.summary)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.dsTextDim)
                    
                    Spacer()
                    
                    // Дата последней игры
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(campaign.formattedLastPlayed)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.dsTextDim)
                }
                
                // Код комнаты (если есть)
                if let code = campaign.roomCode, !code.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                        Text("Код: \(code)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                }
            }
            .padding(14)
            .background(theme.surface)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .confirmationDialog(
            "Действия с кампанией",
            isPresented: $showingMenu,
            titleVisibility: .visible
        ) {
            Button("Продолжить") { onStart() }
            Button("Переименовать") { onRename() }
            Button("Удалить", role: .destructive) { onDelete() }
            Button("Отмена", role: .cancel) {}
        }
    }
}

// MARK: - Preview

#Preview {
    CampaignSelectionView()
        .preferredColorScheme(.dark)
}
