//
//  DungeonMasterView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI

struct DungeonMasterView: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var partyManager = PartyManager.shared
    @State private var showDeletedCharacters = false
    @State private var showItemStorage = false // 🆕 Вкладка хранилища предметов
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    
                    //Секция правил игры
                    GameRulesSection(partyManager: partyManager)
                    
                    // 🆕 Переключатель между Партией и Хранилищем
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showItemStorage = false
                            }
                        } label: {
                            Text("ПАРТИЯ")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundColor(showItemStorage ? Color.dsTextDim : Color.dsBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(showItemStorage ? Color.clear : Color.dsGold)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showItemStorage = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bag.fill").font(.system(size: 10))
                                Text("ХРАНИЛИЩЕ")
                                    .font(.system(size: 10, weight: .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(!showItemStorage ? Color.dsTextDim : Color.dsBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(!showItemStorage ? Color.clear : Color.dsGold)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.dsGold.opacity(0.5), lineWidth: 1)
                    )

                    if showItemStorage {
                        // 🆕 Вкладка хранилища предметов ДМа
                        DMItemStorageView()
                    } else if partyManager.partyMembers.isEmpty {
                        emptyState
                    } else {
                        partyGrid

                        // 🆕 Кнопка "Новая сессия" (сброс отдыхов)
                        Button {
                            PlatformCompatibility.hapticImpact(.medium)
                            partyManager.resetSession()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 14))
                                Text("Новая сессия")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        
                        Text("Сбросить все отдыхи для начала новой сессии")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textDim)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 20)
            }
            // 🆕 Pull-to-refresh для обновления данных партии
            .refreshable {
                PlatformCompatibility.hapticImpact(.light)
                await partyManager.requestFullSync()
            }
        }
        .navigationTitle("Мастер Подземелий")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        // 🆕 Overlay голосования за отдых (ДМ тоже голосует)
        .overlay {
            if let voteSession = partyManager.restVotingManager.activeRestVote {
                RestVoteOverlayView(
                    session: voteSession,
                    myVoteSent: partyManager.restVotingManager.myVoteSent,
                    isDungeonMaster: true,
                    onVote: { accepted in
                        if let dmCharacter = partyManager.selectedCharacter {
                            partyManager.sendRestVote(accepted: accepted, from: dmCharacter)
                        } else {
                            partyManager.sendDMVote(accepted: accepted)
                        }
                    },
                    onCancel: {
                        partyManager.cancelRestVote()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(9999)
            }
        }
        // 🆕 Overlay эффекта отдыха
        .overlay {
            if let effect = partyManager.restVotingManager.activeRestEffect {
                RestEffectOverlayView(effect: effect) {
                    partyManager.restVotingManager.activeRestEffect = nil  // ✅ Исправлено
                }
                .zIndex(10000)
            }
        }
        // 🆕 Overlay эффекта отдыха
        .overlay {
            if let effect = partyManager.restVotingManager.activeRestEffect {
                RestEffectOverlayView(effect: effect) {
                    partyManager.restVotingManager.activeRestEffect = nil
                }
                .zIndex(10000)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            Text("👑").font(.system(size: 40))
            Text("ПАРТИЯ").font(.system(size: 10)).tracking(3)
                .foregroundColor(theme.textDim)
            
            // ✅ НОВОЕ: Счётчики активных и удалённых
            let activeCount = partyManager.partyMembers.filter { !$0.isCharacterDeleted }.count
            let deletedCount = partyManager.partyMembers.filter { $0.isCharacterDeleted }.count
            
            HStack(spacing: 16) {
                Text("\(activeCount) \(activeMemberWord)")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(showDeletedCharacters ? theme.textDim : theme.primary)
                
                if deletedCount > 0 {
                    Text("·")
                        .foregroundColor(theme.textDim)
                    
                    Text("\(deletedCount) \(deletedMemberWord)")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(showDeletedCharacters ? theme.primary : theme.textDim)
                }
            }
            
            // ✅ НОВОЕ: Переключатель вкладок
            if deletedCount > 0 {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeletedCharacters = false
                        }
                    } label: {
                        Text("АКТИВНЫЕ")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundColor(showDeletedCharacters ? theme.textDim : theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(showDeletedCharacters ? Color.clear : theme.primary)
                            .cornerRadius(4)  //Кроссплатформенное решение
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeletedCharacters = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("УДАЛЁННЫЕ")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(!showDeletedCharacters ? theme.textDim : theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(!showDeletedCharacters ? Color.clear : theme.danger.opacity(0.8))
                        .cornerRadius(4)  //Кроссплатформенное решение
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                )
            }
                
            
            DSdivider().padding(.horizontal, 60)
        }
    }
    private var partyMemberWord: String {
        switch partyManager.partyMembers.count {
        case 1: return "герой"
        case 2, 3, 4: return "героя"
        default: return "героев"
        }
    }
    
    private var activeMemberWord: String {
        let count = partyManager.partyMembers.filter { !$0.isCharacterDeleted }.count
        switch count {
        case 1: return "герой"
        case 2, 3, 4: return "героя"
        default: return "героев"
        }
    }

    private var deletedMemberWord: String {
        let count = partyManager.partyMembers.filter { $0.isCharacterDeleted }.count
        switch count {
        case 1: return "погибший"
        case 2, 3, 4: return "погибших"
        default: return "погибших"
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            
            if showDeletedCharacters {
                //Empty state для удалённых персонажей
                Image(systemName: "graveyard")
                    .font(.system(size: 60))
                    .foregroundColor(theme.textDim.opacity(0.4))
                Text("Кладбище пусто")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.text)
                Text("Здесь будут отображаться персонажи,\nкоторые покинули партию")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
                    .multilineTextAlignment(.center)
            } else {
                //Empty state для активных персонажей
                Image(systemName: "person.3")
                    .font(.system(size: 60))
                    .foregroundColor(theme.textDim.opacity(0.4))
                Text("Пока никто не подключился")
                    .font(.system(size: 14)).foregroundColor(theme.textDim)
            }
            
            Spacer().frame(height: 60)
        }
    }
    
    private var partyGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 16
        ) {
            //Фильтруем по текущей вкладке
            let filteredMembers = showDeletedCharacters
                ? partyManager.partyMembers.filter { $0.isCharacterDeleted }
                : partyManager.partyMembers.filter { !$0.isCharacterDeleted }
            
            ForEach(filteredMembers) { member in
                NavigationLink {
                    DungeonMasterDetailView(memberID: member.id)
                } label: {
                    PartyMemberCard(member: member)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DungeonMasterMemberCard: View {
    @Environment(\.theme) private var theme
    let member: PartyMember
    
    var body: some View {
        VStack(spacing: 12) {
            // Аватар с индикатором статуса
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarData: member.avatarData, race: member.race, size: 80)
                
                // 🟢🔴 Индикатор онлайн/офлайн
                Circle()
                    .fill(member.isConnected ? Color.green : theme.danger)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(theme.surface, lineWidth: 2)
                    )
                    .offset(x: 4, y: 4)
            }
            
            // Имя + статус
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(member.isConnected ? theme.primary : theme.textDim)
                    .lineLimit(1)
                
                if !member.isConnected {
                    Text("⚫ ОФЛАЙН")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundColor(theme.danger)
                }
            }
            
            Text("\(member.race.rawValue) · \(member.characterClass)")
                .font(.system(size: 10))
                .foregroundColor(theme.textDim)
                .lineLimit(1)
            
            DSdivider()
                .padding(.horizontal, 10)
            
            // HP бар
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.surfaceAlt)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 2)
                         .fill(hpColor)
                         .frame(width: geo.size.width * member.hpFraction, height: 6)
                         .animation(.spring(response: 0.4, dampingFraction: 0.7), value: member.currentHP)
                        }
                }
                .frame(height: 6)
                
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(theme.danger)
                    Text("\(member.currentHP) / \(member.maxHP)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(hpColor)
                }
            }
            
            HStack(spacing: 8) {
                DSBadge(text: "Веха \(member.level)", color: .dsGold)
                Spacer()
                Text("Стресс: \(member.stress)")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textDim)
            }
            
            if member.hasFullProfile {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 8))
                    Text("Подробно")
                        .font(.system(size: 9))
                }
                .foregroundColor(theme.primaryDim)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    member.isConnected ? theme.primary.opacity(0.3) : theme.danger.opacity(0.3),
                    lineWidth: 0.5
                )
        )
        .cornerRadius(6)
        .opacity(member.isConnected ? 1.0 : 0.65)  // 🆕 Полупрозрачность
    }
    
    private var hpColor: Color {
        let f = member.hpFraction
        if f > 0.5 { return theme.primary }
        if f > 0.25 { return .orange }
        return theme.danger
    }
}

