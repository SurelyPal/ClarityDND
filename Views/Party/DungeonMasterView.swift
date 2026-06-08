//
//  DungeonMasterView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI

struct DungeonMasterView: View {
    @StateObject private var partyManager = PartyManager.shared
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    if partyManager.partyMembers.isEmpty {
                        emptyState
                    } else {
                        partyGrid
                        
                        // 🆕 Кнопка "Новая сессия" (сброс отдыхов)
                        Button {
                            partyManager.resetSession()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 14))
                                Text("Новая сессия")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(Color.dsBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dsGold)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        
                        Text("Сбросить все отдыхи для начала новой сессии")
                            .font(.system(size: 10))
                            .foregroundColor(Color.dsTextDim)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 20)
            }
            // 🆕 Pull-to-refresh для обновления данных партии
            .refreshable {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                await partyManager.requestFullSync()
            }
        }
        .navigationTitle("Экран Мастера")
        .navigationBarTitleDisplayMode(.inline)
        // 🆕 Overlay голосования за отдых (ДМ тоже голосует)
        .overlay {
            if let voteSession = partyManager.activeRestVote {
                RestVoteOverlayView(
                    session: voteSession,
                    myVoteSent: partyManager.myVoteSent,
                    isDungeonMaster: true,  // ДМ всегда ДМ
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
            if let effect = partyManager.activeRestEffect {
                RestEffectOverlayView(effect: effect) {
                    partyManager.activeRestEffect = nil
                }
                .zIndex(10000)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Text("👑").font(.system(size: 40))
            Text("ПАРТИЯ").font(.system(size: 10)).tracking(3)
                .foregroundColor(Color.dsTextDim)
            Text("\(partyManager.partyMembers.count) \(partyMemberWord)")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Color.dsGold)
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
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(Color.dsTextDim.opacity(0.4))
            Text("Пока никто не подключился")
                .font(.system(size: 14)).foregroundColor(Color.dsTextDim)
            Spacer().frame(height: 60)
        }
    }
    
    private var partyGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 16
        ) {
            ForEach(partyManager.partyMembers) { member in
                NavigationLink {
                    DungeonMasterDetailView(memberID: member.id)  // 🆕
                } label: {
                    PartyMemberCard(member: member)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct DungeonMasterMemberCard: View {
    let member: PartyMember
    
    var body: some View {
        VStack(spacing: 12) {
            // Аватар с индикатором статуса
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarData: member.avatarData, race: member.race, size: 80)
                
                // 🟢🔴 Индикатор онлайн/офлайн
                Circle()
                    .fill(member.isConnected ? Color.green : Color.dsRed)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(Color.dsSurface, lineWidth: 2)
                    )
                    .offset(x: 4, y: 4)
            }
            
            // Имя + статус
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(member.isConnected ? Color.dsGold : Color.dsTextDim)
                    .lineLimit(1)
                
                if !member.isConnected {
                    Text("⚫ ОФЛАЙН")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundColor(Color.dsRed)
                }
            }
            
            Text("\(member.race.rawValue) · \(member.characterClass)")
                .font(.system(size: 10))
                .foregroundColor(Color.dsTextDim)
                .lineLimit(1)
            
            DSdivider()
                .padding(.horizontal, 10)
            
            // HP бар
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.dsSurfaceAlt)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hpColor)
                            .frame(width: geo.size.width * member.hpFraction, height: 6)
                            .animation(.spring(), value: member.currentHP)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.dsRed)
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
                    .foregroundColor(Color.dsTextDim)
            }
            
            if member.hasFullProfile {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 8))
                    Text("Подробно")
                        .font(.system(size: 9))
                }
                .foregroundColor(Color.dsGoldDim)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.dsSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    member.isConnected ? Color.dsGold.opacity(0.3) : Color.dsRed.opacity(0.3),
                    lineWidth: 0.5
                )
        )
        .cornerRadius(6)
        .opacity(member.isConnected ? 1.0 : 0.65)  // 🆕 Полупрозрачность
    }
    
    private var hpColor: Color {
        let f = member.hpFraction
        if f > 0.5 { return Color.dsGold }
        if f > 0.25 { return .orange }
        return Color.dsRed
    }
}

