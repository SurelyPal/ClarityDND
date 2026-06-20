import SwiftUI
import SwiftData

// MARK: - Детальный экран кампании для ГМа

struct CampaignDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let campaign: Campaign
    
    @State private var viewModel: CampaignDetailViewModel
    @State private var showCopySuccess = false
    
    private let partyManager = PartyManager.shared
    private let campaignManager = CampaignManager.shared
    
    init(campaign: Campaign) {
        self.campaign = campaign
        _viewModel = State(initialValue: CampaignDetailViewModel(campaign: campaign))
    }
    
    // MARK: - Вычисляемые свойства
    
    private var isOwner: Bool {
        viewModel.isCurrentUserOwner(currentPlayer: campaignManager.currentPlayer)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                infoCard
                charactersSection
                settingsSection
                actionButtons
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(campaign.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            campaignManager.setup(context: modelContext)
            viewModel.setup()
        }
        .alert("Код скопирован", isPresented: $showCopySuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Код приглашения скопирован в буфер обмена. Отправьте его друзьям!")
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(campaign.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.dsGold)
            
            HStack(spacing: 12) {
                // Код комнаты
                if let joinCode = campaign.joinCode, !joinCode.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "number.circle.fill")
                            .foregroundColor(.dsGold)
                        Text("Код: \(joinCode)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                    }
                }
                
                if let template = campaign.gameTemplate {
                    HStack(spacing: 6) {
                        Image(systemName: "book.fill")
                            .foregroundColor(.dsTextDim)
                        Text("Шаблон: \(template.name)")
                            .font(.system(size: 14))
                    }
                }
            }
            .foregroundColor(.dsTextDim)
        }
    }
    
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.dsGold)
                Text("Персонажей в кампании")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Text("\(campaign.members.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.dsGold)
            }
            
            Divider()
                .background(theme.border)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.dsTextDim)
                Text("Последняя игра")
                    .font(.system(size: 14))
                Spacer()
                Text(campaign.lastPlayedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.dsTextDim)
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
    
    private var charactersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👥 Персонажи")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.dsText)
                
                Spacer()
                
                Text("\(campaign.members.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.dsGold)
            }
            
            if campaign.members.isEmpty {
                emptyCharactersView
            } else {
                ForEach(campaign.members) { member in
                    CharacterRowView(member: member)
                }
            }
        }
    }
    
    private var emptyCharactersView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 30))
                .foregroundColor(.dsTextDim.opacity(0.5))
            
            Text("Персонажей пока нет")
                .font(.system(size: 14))
                .foregroundColor(.dsTextDim)
            
            Text("Создайте персонажей после начала сессии")
                .font(.system(size: 12))
                .foregroundColor(.dsTextDim.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.surface.opacity(0.5))
        .cornerRadius(8)
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚙️ Настройки")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.dsText)
            
            VStack(spacing: 8) {
                if let template = campaign.gameTemplate {
                    SettingRow(
                        icon: "book.fill",
                        title: "Шаблон",
                        subtitle: template.name
                    )
                }
                
                // ИСПРАВЛЕНО: GameRules не Optional, используем конкретные поля
                SettingRow(
                    icon: "doc.text.fill",
                    title: "Правила (Отдыхи)",
                    subtitle: "Короткий: \(campaign.gameRules.maxShortRests) | Длинный: \(campaign.gameRules.maxLongRests)"
                )
                
                SettingRow(
                    icon: "note.text",
                    title: "Заметки ГМа",
                    subtitle: campaign.dmNotes ?? "Пусто"
                )
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                startSession()
            } label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Начать сессию")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.dsGold)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            if isOwner, let joinCode = campaign.joinCode, !joinCode.isEmpty {
                Button {
                    copyJoinCode(joinCode)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Поделиться кодом")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.surface)
                    .foregroundColor(.dsGold)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.dsGold, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Методы действий
    
    private func startSession() {
        PlatformCompatibility.hapticImpact(.heavy)
        partyManager.startHosting(campaign: campaign)
        dismiss()
    }
    
    private func copyJoinCode(_ code: String) {
        #if os(iOS)
        UIPasteboard.general.string = code
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        
        PlatformCompatibility.hapticNotification(.success)
        showCopySuccess = true
    }
}

// MARK: - ViewModel

@Observable
class CampaignDetailViewModel {
    let campaign: Campaign
    
    init(campaign: Campaign) {
        self.campaign = campaign
    }
    
    func setup() {}
    
    func isCurrentUserOwner(currentPlayer: Player?) -> Bool {
        guard let currentPlayer = currentPlayer,
              let owner = campaign.owner else {
            return false
        }
        return currentPlayer.id == owner.id
    }
}

// MARK: - Компонент строки персонажа

struct CharacterRowView: View {
    @Environment(\.theme) private var theme
    let member: PartyMember
    
    private var defaultAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 20))
            .foregroundColor(.dsGold)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.surface.opacity(0.3))
                    .frame(width: 44, height: 44)
                
                if let avatarData = member.avatarData {
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
            
            VStack(alignment: .leading, spacing: 4) {
                // ИСПРАВЛЕНО: В PartyMember поле называется 'name', а не 'characterName'
                Text(member.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.dsText)
                
                // ИСПРАВЛЕНО: В PartyMember нет поля 'owner', убираем эту строку
                // или можно показать расу: Text(member.race.rawValue).font(.caption)
                if let raceString = String(describing: member.race) as String? {
                     Text(raceString)
                        .font(.system(size: 11))
                        .foregroundColor(.dsTextDim)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // ИСПРАВЛЕНО: В PartyMember поле называется 'level', а не 'characterLevel'
                Text("Ур. \(member.level)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.dsGold)
                
                Text(member.characterClass)
                    .font(.system(size: 10))
                    .foregroundColor(.dsTextDim)
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
}

// MARK: - Компонент строки настройки

struct SettingRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.dsGold)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dsText)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.dsTextDim)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.dsTextDim)
        }
        .padding()
        .background(theme.surface.opacity(0.5))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationStack {
        CampaignDetailView(campaign: Campaign(
            name: "Тестовая кампания",
            joinCode: "123456"
        ))
    }
    .modelContainer(for: [Campaign.self, Player.self], inMemory: true)
}
