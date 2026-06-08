
//  PartyLobbyView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI

struct PartyLobbyView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: CharacterStore
    @StateObject private var partyManager = PartyManager.shared
    @State private var selectedCharacter: DNDCharacter?
    @State private var rules = GameRules.default
    @State private var showErrorAlert = false          // 🆕
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        
                        switch partyManager.connectionState {
                        case .disconnected:
                            roleSelection
                            
                        case .configuringRules:
                            rulesConfiguration
                            
                        case .selectingCharacter:
                            playerFlow
                            
                        case .hosting(let code):
                            hostingView(code: code)
                            
                        case .searching:
                            searchingView
                            
                        case .connecting(let peerName):
                            connectingView(peerName: peerName)
                            
                        case .connected(let peersCount):
                            if partyManager.role == .dungeonMaster {
                                hostingView(code: partyManager.roomCode)
                            } else {
                                connectedView(peersCount: peersCount)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Партия")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        // 🆕 ЕДИНЫЙ alert для всех ошибок и отключений
        .alert(
            errorMessage.contains("отключил") || errorMessage.contains("потеряно")
                ? "Отключение от партии"
                : "Ошибка подключения",
            isPresented: $showErrorAlert
        ) {
            Button("OK") {
                partyManager.clearError()
                partyManager.clearDisconnectReason()
            }
        } message: {
            Text(errorMessage)
        }
        // 🆕 Отслеживаем появление ошибок
        .onChange(of: partyManager.lastError) { _, newError in
            if let error = newError {
                errorMessage = error
                showErrorAlert = true
            }
        }
        .onChange(of: partyManager.disconnectReason) { _, newReason in
            if let reason = newReason, partyManager.lastError == nil {
                errorMessage = reason
                showErrorAlert = true
            }
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("🎲").font(.system(size: 48))
            Text("СОБРАТЬ ПАРТИЮ")
                .font(.system(size: 10)).tracking(3)
                .foregroundColor(Color.dsTextDim)
            Text("Играть вместе")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color.dsGold)
            DSdivider().padding(.horizontal, 40)
        }
    }
    
    // MARK: - Выбор роли
    
    private var roleSelection: some View {
        VStack(spacing: 16) {
            Button {
                partyManager.startHosting()
            } label: {
                VStack(spacing: 12) {
                    Text("👑").font(.system(size: 40))
                    Text("МАСТЕР ПАРТИИ")
                        .font(.system(size: 14, weight: .semibold)).tracking(1.5)
                        .foregroundColor(Color.dsGold)
                    Text("Создать комнату и видеть всех игроков в реальном времени")
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsTextDim)
                        .multilineTextAlignment(.center)
                }
                .padding(20).frame(maxWidth: .infinity)
                .background(Color.dsSurface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsGold, lineWidth: 1.5))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            Button {
                partyManager.beginPlayerFlow()
            } label: {
                VStack(spacing: 12) {
                    Text("🗡️").font(.system(size: 40))
                    Text("ИГРОК")
                        .font(.system(size: 14, weight: .semibold)).tracking(1.5)
                        .foregroundColor(Color.dsText)
                    Text("Выбрать персонажа и подключиться к Мастеру")
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsTextDim)
                        .multilineTextAlignment(.center)
                }
                .padding(20).frame(maxWidth: .infinity)
                .background(Color.dsSurfaceAlt)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsBorder, lineWidth: 1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    
    // MARK: - Игрок: выбор персонажа + поиск
    
    private var playerFlow: some View {
        VStack(spacing: 20) {
            if store.characters.isEmpty {
                emptyCharacterList
            } else {
                characterSelection
            }
            
            Button {
                partyManager.leaveRoom()
                partyManager.clearSelectedCharacter()
            } label: {
                Text("Отмена")
                    .font(.system(size: 13))
                    .foregroundColor(Color.dsRed)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.dsGold))
                .scaleEffect(1.5)
            
            Text("Поиск комнат...")
                .font(.system(size: 14))
                .foregroundColor(Color.dsText)
            
            if let char = selectedCharacter {
                HStack(spacing: 10) {
                    AvatarView(avatarData: char.avatarData, race: char.race, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Отправка:")
                            .font(.system(size: 10))
                            .foregroundColor(Color.dsTextDim)
                        Text(char.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.dsGold)
                    }
                }
                .padding(12)
                .background(Color.dsSurface)
                .cornerRadius(6)
            }
            
            Button {
                partyManager.leaveRoom()
                partyManager.clearSelectedCharacter()
            } label: {
                Text("Отмена")
                    .font(.system(size: 13))
                    .foregroundColor(Color.dsRed)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var emptyCharacterList: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color.dsTextDim.opacity(0.5))
            Text("У вас нет персонажей")
                .font(.system(size: 14))
                .foregroundColor(Color.dsText)
            Text("Создайте героя в Книге Судеб, чтобы присоединиться к партии")
                .font(.system(size: 11))
                .foregroundColor(Color.dsTextDim)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }
    
    private var characterSelection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ВЫБЕРИТЕ ГЕРОЯ")
                    .font(.system(size: 10)).tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
            }
            
            ForEach(store.characters) { char in
                Button {
                    selectedCharacter = char
                    partyManager.setSelectedCharacter(char)
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(avatarData: char.avatarData, race: char.race, size: 48)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(char.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.dsText)
                            Text("\(char.race.rawValue) · \(char.characterClass.rawValue) · Веха \(char.level)")
                                .font(.system(size: 10))
                                .foregroundColor(Color.dsTextDim)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 3) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color.dsRed)
                                Text("\(char.currentHP)/\(char.hitPoints)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(char.hpColor)
                            }
                            
                            if selectedCharacter?.id == char.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.dsGold)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(Color.dsTextDim.opacity(0.5))
                            }
                        }
                    }
                    .padding(12)
                    .background(selectedCharacter?.id == char.id ? Color.dsGold.opacity(0.1) : Color.dsSurfaceAlt)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(selectedCharacter?.id == char.id ? Color.dsGold : Color.dsBorder, lineWidth: selectedCharacter?.id == char.id ? 1.5 : 0.5)
                    )
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Кнопка "Найти партию"
            if selectedCharacter != nil {
                Button {
                    guard let char = selectedCharacter else { return }
                    partyManager.startSearching(with: char)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("Найти партию")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dsGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            } else {
                Text("Выберите героя, чтобы подключиться")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - ДМ
    
    private func hostingView(code: String) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("КОД КОМНАТЫ")
                    .font(.system(size: 10)).tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Text(code)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .tracking(8)
                    .foregroundColor(Color.dsGold)
                Text("Ожидание героев...")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsTextDim)
            }
            .padding(24).frame(maxWidth: .infinity)
            .background(Color.dsSurface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsGold, lineWidth: 1))
            .cornerRadius(8)
            
            if partyManager.partyMembers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hourglass").font(.system(size: 32))
                        .foregroundColor(Color.dsTextDim)
                    Text("Пока никого нет").font(.system(size: 13))
                        .foregroundColor(Color.dsTextDim)
                }.padding(30)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("ГЕРОИ (\(partyManager.partyMembers.count))")
                            .font(.system(size: 10)).tracking(2)
                            .foregroundColor(Color.dsTextDim)
                        Spacer()
                    }
                    ForEach(partyManager.partyMembers) { member in
                        PartyMemberRow(member: member)
                    }
                }
                .padding(16)
                .background(Color.dsSurface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsBorder, lineWidth: 0.5))
                .cornerRadius(8)
            }
            
            VStack(spacing: 10) {
                if !partyManager.partyMembers.isEmpty {
                    NavigationLink(destination: DungeonMasterView()) {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Экран Мастера")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.dsBackground)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.dsGold).cornerRadius(6)
                    }.buttonStyle(.plain)
                }
                
                Button { partyManager.stopHosting() } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Завершить хостинг")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color.dsRed)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Color.dsRed.opacity(0.1)).cornerRadius(6)
                }.buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Connecting / Connected (игрок)
    
    private func connectingView(peerName: String) -> some View {
        VStack(spacing: 20) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.dsGold)).scaleEffect(1.5)
            Text("Подключение к \(peerName)...").font(.system(size: 14)).foregroundColor(Color.dsText)
            if let char = selectedCharacter {
                VStack(spacing: 8) {
                    AvatarView(avatarData: char.avatarData, race: char.race, size: 60)
                    Text("Отправка: \(char.displayName)")
                        .font(.system(size: 12)).foregroundColor(Color.dsTextDim)
                }.padding(.top, 10)
            }
        }
    }
    
    private func connectedView(peersCount: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60)).foregroundColor(Color.dsGold)
            Text("ПОДКЛЮЧЕНО").font(.system(size: 10)).tracking(3)
                .foregroundColor(Color.dsGold)
            if let char = selectedCharacter {
                VStack(spacing: 8) {
                    AvatarView(avatarData: char.avatarData, race: char.race, size: 80)
                    Text(char.displayName).font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.dsGold)
                    Text("Ваш герой в партии")
                        .font(.system(size: 11)).foregroundColor(Color.dsTextDim)
                }
                .padding(20).background(Color.dsSurface).cornerRadius(8)
            }
            Button { partyManager.leaveRoom() } label: {
                Text("Отключиться").font(.system(size: 13)).foregroundColor(Color.dsRed)
            }.buttonStyle(.plain)
        }
    }
    // MARK: - ⚙️ Настройка правил игры

    private var rulesConfiguration: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("⚙️").font(.system(size: 48))
                Text("ПРАВИЛА ПАРТИИ")
                    .font(.system(size: 10)).tracking(3)
                    .foregroundColor(Color.dsTextDim)
                Text("Установи условия игры")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color.dsGold)
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 12) {
                // Правило 1: Редактирование вне партии
                RuleToggle(
                    icon: "pencil.circle.fill",
                    title: "Изменение героев",
                    description: "Разрешить игрокам менять персонажей, когда они не подключены к партии",
                    isOn: $rules.canEditCharacterOutsideParty
                )
                
                // 🔮 Здесь будут другие правила:
                // RuleToggle(...)
                // RuleToggle(...)
            }
            .padding(16)
            .background(Color.dsSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.dsBorder, lineWidth: 0.5)
            )
            .cornerRadius(8)
            
            // Кнопки действий
            VStack(spacing: 10) {
                Button {
                    partyManager.applyRulesAndStartHosting(rules)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Создать партию")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dsGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    partyManager.stopHosting()
                } label: {
                    Text("Отмена")
                        .font(.system(size: 13))
                        .foregroundColor(Color.dsRed)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// ═══════════════════════════════════════════
// 🔑 PartyMemberRow — ОТДЕЛЬНАЯ структура
// ═══════════════════════════════════════════
struct PartyMemberRow: View {
    let member: PartyMember
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarData: member.avatarData, race: member.race, size: 44)
                
                Circle()
                    .fill(member.isConnected ? Color.green : Color.dsRed)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(Color.dsSurface, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(member.isConnected ? Color.dsText : Color.dsTextDim)
                    
                    if !member.isConnected {
                        Text("ОФЛАЙН")
                            .font(.system(size: 7, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(Color.dsRed)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.dsRed.opacity(0.15))
                            .cornerRadius(2)
                    }
                }
                
                Text("\(member.race.rawValue) · \(member.characterClass)")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("Веха \(member.level)")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color.dsGold)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.dsRed)
                    Text("\(member.currentHP)/\(member.maxHP)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(hpColor)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(member.isConnected ? 1.0 : 0.6)
    }
    
    private var hpColor: Color {
        let fraction = member.hpFraction
        if fraction > 0.5 { return Color.dsGold }
        if fraction > 0.25 { return .orange }
        return Color.dsRed
    }
}
// ═══════════════════════════════════════════
// 🎚️ RuleToggle — компонент для правила
// ═══════════════════════════════════════════
struct RuleToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color.dsGold)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.dsText)
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsTextDim)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.dsGold)
        }
        .padding(.vertical, 6)
    }
}
