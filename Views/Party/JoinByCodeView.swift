//
//  JoinByCodeView.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI
import SwiftData

// MARK: - Экран подключения по коду

struct JoinByCodeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    // Загружаем все кампании для поиска по коду
    @Query private var allCampaigns: [Campaign]
    
    @State private var viewModel = JoinByCodeViewModel()
    private let campaignManager = CampaignManager.shared
    
    // Состояния UI
    @State private var joinCode = ""
    @State private var errorMessage: String?
    @State private var isSearching = false
    @State private var showingSuccessAlert = false
    @State private var joinedCampaign: Campaign?
    @State private var showingCharacterSelection = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Заголовок
                    headerSection
                    
                    // Поле ввода кода
                    codeInputSection
                    
                    // Сообщение об ошибке
                    if let error = errorMessage {
                        errorView(error)
                    }
                    
                    Spacer()
                    
                    // Кнопка подключения
                    connectButton
                    
                    // Подсказка
                    helpText
                }
                .padding()
            }
            .navigationTitle("🔗 Подключение по коду")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                campaignManager.setup(context: modelContext)
            }
            .alert("Успешное подключение!", isPresented: $showingSuccessAlert) {
                Button("Продолжить") {
                    // Здесь можно добавить навигацию к выбору персонажа
                    dismiss()
                }
            } message: {
                if let campaign = joinedCampaign {
                    Text("Вы присоединились к кампании '\(campaign.name)'")
                }
            }
            .sheet(isPresented: $showingCharacterSelection) {
                if let campaign = joinedCampaign {
                    PartyCharacterSelectionView(campaign: campaign)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.dsGold)
            
            Text("Присоединиться к кампании")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.dsText)
            
            Text("Введите 6-значный код, который дал вам Гейм Мастер")
                .font(.system(size: 14))
                .foregroundColor(.dsTextDim)
                .multilineTextAlignment(.center)
        }
    }
    
    private var codeInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Код приглашения")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.dsText)
            
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.dsGold)
                
                TextField("123456", text: $joinCode)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .font(.system(size: 24, weight: .medium, design: .monospaced))
                    .foregroundColor(.dsText)
                    .multilineTextAlignment(.center)
                    .onChange(of: joinCode) { oldValue, newValue in
                        // Ограничиваем ввод 6 символами и только цифрами
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered.count <= 6 {
                            joinCode = filtered
                        } else {
                            joinCode = String(filtered.prefix(6))
                        }
                        // Очищаем ошибку при изменении ввода
                        errorMessage = nil
                    }
                
                if !joinCode.isEmpty {
                    Button {
                        joinCode = ""
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.dsTextDim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(theme.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        errorMessage != nil ? Color.red : theme.border,
                        lineWidth: errorMessage != nil ? 2 : 1
                    )
            )
            
            // Счётчик символов
            HStack {
                Spacer()
                Text("\(joinCode.count)/6")
                    .font(.system(size: 12))
                    .foregroundColor(joinCode.count == 6 ? .green : .dsTextDim)
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(error)
                .font(.system(size: 13))
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var connectButton: some View {
        Button {
            attemptToJoin()
        } label: {
            HStack {
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .tint(.black)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                }
                
                Text(isSearching ? "Подключение..." : "Подключиться")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                joinCode.count == 6 && !isSearching
                ? Color.dsGold
                : Color.dsGold.opacity(0.3)
            )
            .foregroundColor(.black)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(joinCode.count != 6 || isSearching)
    }
    
    private var helpText: some View {
        VStack(spacing: 8) {
            Text("💡 Подсказка")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.dsGold)
            
            Text("Попросите Гейм Мастера скопировать код из раздела 'Поделиться кодом' в настройках кампании")
                .font(.system(size: 11))
                .foregroundColor(.dsTextDim)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(theme.surface.opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Методы действий
    
    private func attemptToJoin() {
        guard joinCode.count == 6 else {
            errorMessage = "Код должен содержать ровно 6 цифр"
            PlatformCompatibility.hapticNotification(.error)
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Небольшая задержка для UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.findCampaign(byCode: joinCode, in: allCampaigns) { result in
                isSearching = false
                
                switch result {
                case .success(let campaign):
                    joinCampaign(campaign)
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    PlatformCompatibility.hapticNotification(.error)
                }
            }
        }
    }
    
    private func joinCampaign(_ campaign: Campaign) {
        guard let currentPlayer = campaignManager.currentPlayer else {
            errorMessage = "Ошибка: не удалось определить текущего игрока"
            return
        }
        
        // Проверяем, не присоединился ли уже
        if campaign.joinedPlayers.contains(where: { $0.id == currentPlayer.id }) {
            errorMessage = "Вы уже присоединены к этой кампании"
            PlatformCompatibility.hapticNotification(.warning)
            return
        }
        
        // Добавляем игрока в кампанию
        campaign.joinedPlayers.append(currentPlayer)
        
        do {
            try modelContext.save()
            joinedCampaign = campaign
            
            // 🆕 ИЗМЕНЕНО: Вместо алерта успеха — переходим к выбору персонажа
            showingCharacterSelection = true
            
            PlatformCompatibility.hapticNotification(.success)
        } catch {
            errorMessage = "Не удалось сохранить подключение: \(error.localizedDescription)"
            PlatformCompatibility.hapticNotification(.error)
        }
    }
}

// MARK: - ViewModel для JoinByCodeView

@Observable
class JoinByCodeViewModel {
    
    enum JoinError: LocalizedError {
        case campaignNotFound
        case campaignInactive
        
        var errorDescription: String? {
            switch self {
            case .campaignNotFound:
                return "Кампания с таким кодом не найдена. Проверьте код и попробуйте снова."
            case .campaignInactive:
                return "Эта кампания больше не активна. Обратитесь к Гейм Мастеру."
            }
        }
    }
    
    /// Ищет кампанию по коду приглашения
    func findCampaign(
        byCode code: String,
        in campaigns: [Campaign],
        completion: @escaping (Result<Campaign, JoinError>) -> Void
    ) {
        // Ищем кампанию с matching joinCode
        guard let campaign = campaigns.first(where: { $0.joinCode == code }) else {
            completion(.failure(.campaignNotFound))
            return
        }
        
        // Проверяем, активна ли кампания
        if !campaign.isActive {
            completion(.failure(.campaignInactive))
            return
        }
        
        completion(.success(campaign))
    }
}

// MARK: - Preview

#Preview {
    JoinByCodeView()
        .modelContainer(for: [Campaign.self, Player.self], inMemory: true)
}
