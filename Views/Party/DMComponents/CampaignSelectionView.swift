import SwiftUI
import SwiftData

// MARK: - Экран выбора кампании для ДМа

struct CampaignSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    // Загружаем все кампании из SwiftData, сортируем по последней игре
    @Query(sort: \Campaign.lastPlayedAt, order: .reverse) private var allCampaigns: [Campaign]
    
    // Менеджеры
    @State private var campaignManager = CampaignManager.shared
    private let partyManager = PartyManager.shared
    @State private var showingCreateCampaignView = false
    @State private var selectedCampaign: Campaign?
    @State private var showingCampaignDetail = false
    // UI Состояния
    @State private var showingNewCampaignAlert = false
    @State private var newCampaignName = ""
    
    @State private var campaignToDelete: Campaign?
    @State private var showingDeleteConfirmation = false
    
    @State private var showingRenameAlert = false
    @State private var campaignToRename: Campaign?
    @State private var renameText = ""
    
    // MARK: - Вычисляемые свойства для секций
    
    private var currentPlayer: Player? {
        campaignManager.currentPlayer
    }
    
    private var myCampaigns: [Campaign] {
        guard let currentPlayer = currentPlayer else { return [] }
        return allCampaigns.filter { $0.owner?.id == currentPlayer.id }
    }
    
    private var joinedCampaigns: [Campaign] {
        return currentPlayer?.joinedCampaigns ?? []
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон в стиле Dark Souls
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Список кампаний или пустое состояние
                    if myCampaigns.isEmpty && joinedCampaigns.isEmpty {
                        emptyStateView
                    } else {
                        campaignsList
                    }
                    
                    Spacer()
                    
                    // Кнопки действий (прижаты к низу)
                    bottomActionButtons
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
            // Загружаем currentPlayer из SwiftData
            .task {
                campaignManager.setup(context: modelContext)
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
            .alert("Перименовать кампанию", isPresented: $showingRenameAlert) {
                TextField("Новое название", text: $renameText)
                
                Button("Отмена", role: .cancel) {}
                
                Button("Сохранить") {
                    if let campaign = campaignToRename {
                        campaignManager.renameCampaign(campaign, to: renameText, context: modelContext)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateCampaignView) {
            CreateCampaignView()
        }
        .navigationDestination(isPresented: $showingCampaignDetail) {
            if let campaign = selectedCampaign {
                CampaignDetailView(campaign: campaign)
                
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        Text("Выберите кампанию")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.dsGold)
            .padding(.top, 20)
            .padding(.bottom, 10)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dice.fill")
                .font(.system(size: 50))
                .foregroundColor(.dsGold.opacity(0.5))
            
            Text("Пока нет кампаний")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.dsText)
            
            Text("Создайте свою первую кампанию или подключитесь по коду.")
                .font(.subheadline)
                .foregroundColor(.dsTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var campaignsList: some View {
        List {
            if !myCampaigns.isEmpty {
                Section {
                    ForEach(myCampaigns) { campaign in
                        CampaignRowView(
                            campaign: campaign,
                            isOwner: true,
                            onStart: { startCampaign(campaign) },
                            onRename: { prepareRename(campaign) },
                            onDelete: { prepareDelete(campaign) }
                        )
                        .listRowBackground(theme.surface)
                    }
                } header: {
                    Text("🎲 Мои кампании (я ГМ)")
                        .foregroundColor(.dsTextDim)
                        .font(.caption)
                }
            }
            
            if !joinedCampaigns.isEmpty {
                Section {
                    ForEach(joinedCampaigns) { campaign in
                        CampaignRowView(
                            campaign: campaign,
                            isOwner: false,
                            onStart: { startCampaign(campaign) },
                            onRename: {},
                            onDelete: {}
                        )
                        .listRowBackground(theme.surface)
                    }
                } header: {
                    Text("🎭 Где я игрок")
                        .foregroundColor(.dsTextDim)
                        .font(.caption)
                }
            }
        }
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
    }
    
    private var bottomActionButtons: some View {
        HStack(spacing: 12) {
            // Кнопка Создать
            Button {
                showingNewCampaignAlert = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.title2)
                    Text("Создать")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.dsGold)
            .foregroundColor(.black)
            
            // Кнопка Войти по коду (Навигация к JoinByCodeView)
            NavigationLink {
                JoinByCodeView()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.title2)
                    Text("Войти")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.dsGold)
            
            // Кнопка Архив (Навигация к ArchivedCharactersView)
            NavigationLink {
                ArchivedCharactersView()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "archivebox")
                        .font(.title2)
                    Text("Архив")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.dsGold)
        }
        .padding()
        .background(theme.surface.opacity(0.8))
    }
    
    // MARK: - Методы действий
    
    /// Создаёт новую кампанию и автоматически начинает её хостинг
    /// Открывает экран создания кампании
    private func createNewCampaign() {
        showingCreateCampaignView = true
    }
    
    /// Начинает хостинг выбранной кампании
    private func startCampaign(_ campaign: Campaign) {
        PlatformCompatibility.hapticImpact(.heavy)
        
        // Вместо немедленного старта — переходим к деталям
        selectedCampaign = campaign
        showingCampaignDetail = true
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
    let isOwner: Bool
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
                    
                    if isOwner {
                        Button {
                            PlatformCompatibility.hapticImpact(.light)
                            showingMenu = true
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.dsGold)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Бейджик для игрока
                        Text("ИГРОК")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
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
                        Text("\(campaign.members.count) игр.")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.dsTextDim)
                    
                    Spacer()
                    
                    // Дата последней игры
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(campaign.lastPlayedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.dsTextDim)
                }
                
                // Код комнаты (если есть)
                if let joinCode = campaign.joinCode, !joinCode.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                        Text("Код: \(joinCode)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.dsGold.opacity(0.7))
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

#Preview {
    CampaignSelectionView()
        .modelContainer(for: [Campaign.self, Player.self, GameTemplate.self], inMemory: true)
}
