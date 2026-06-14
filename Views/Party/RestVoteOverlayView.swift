//
//  RestVoteOverlayView.swift
//  Clarity
//
//  Created by AI on 07.06.2026.
//

import SwiftUI

struct RestVoteOverlayView: View {
    @Environment(\.theme) private var theme
    let session: PartyManager.RestVoteSession
    let myVoteSent: Bool?
    let isDungeonMaster: Bool // 🆕
    let onVote: (Bool) -> Void
    let onCancel: (() -> Void)? // 🆕 Для отмены ДМ
    
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Затемнённый фон
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {} // Блокируем тапы
                
                VStack(spacing: 0) {
                    // ─── Заголовок ───
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: session.restType.icon)
                                .font(.system(size: 18))
                                .foregroundColor(restTypeColor)
                            
                            Text("ГОЛОСОВАНИЕ")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(2)
                                .foregroundColor(theme.textDim)
                        }
                        
                        Text(session.initiatorName)
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(theme.primary)
                        
                        Text("предлагает \(session.restType.displayName.lowercased())")
                            .font(.system(size: 14))
                            .foregroundColor(theme.text)
                        
                        DSdivider()
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(theme.surface)
                    .overlay(
                        CornerOrnaments(size: 14)
                    )
                    
                    Rectangle()
                        .fill(restTypeColor.opacity(0.3))
                        .frame(height: 0.5)
                    
                    // ─── Прогресс голосования ───
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            // 🆕 Заголовок для ДМа
                            if isDungeonMaster {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.primary)
                                    
                                    Text("Отслеживание голосов")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(theme.primary)
                                    
                                    Spacer()
                                }
                            }
                            
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.primary)
                                
                                Text("Голоса")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(theme.text)
                                
                                Spacer()
                                
                                Text("\(session.votes.count) / \(session.totalVoters)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.primary)
                            }
                            
                            // Прогресс-бар
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(theme.surfaceAlt)
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(restTypeColor)
                                        .frame(
                                            width: geo.size.width * CGFloat(session.votes.count) / CGFloat(session.totalVoters),
                                            height: 8
                                        )
                                        .animation(.spring(), value: session.votes.count)
                                }
                            }
                            .frame(height: 8)
                            
                            // Список проголосовавших
                            if !session.votes.isEmpty {
                                VStack(spacing: 6) {
                                    ForEach(Array(session.votes.keys), id: \.self) { voterID in
                                        HStack(spacing: 8) {
                                            Image(systemName: session.votes[voterID] == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(session.votes[voterID] == true ? .green : theme.danger)
                                            
                                            Text(voterID == session.initiatorID ? "Инициатор" : "Игрок")
                                                .font(.system(size: 11))
                                                .foregroundColor(theme.textDim)
                                            
                                            Spacer()
                                            
                                            Text(session.votes[voterID] == true ? "ЗА" : "ПРОТИВ")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(session.votes[voterID] == true ? .green : theme.danger)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(20)
                    }
                    .background(theme.surfaceAlt)
                    
                    // ─── Кнопки голосования ───
                    if isDungeonMaster {
                        // ДМ НЕ голосует — только наблюдает и может отменить
                        VStack(spacing: 12) {
                            VStack(spacing: 8) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.primary)
                                
                                Text("Наблюдение за голосованием")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.text)
                                
                                Text("Вы не участвуете в голосовании")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.textDim)
                            }
                            .padding(.vertical, 12)
                            
                            // Кнопка отмены для ДМа
                            if let onCancel = onCancel {
                                Button {
                                    onCancel()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 12))
                                        Text("Отменить голосование")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Добавлено maxHeight
                                    .padding(.vertical, 14) // ✅ Увеличено с 12 до 14
                                    .background(theme.danger)
                                    .cornerRadius(4)
                                }
                                .frame(maxWidth: .infinity) // ✅ Добавлено на Button
                            }
                        }
                        .frame(height: 120) // ✅ Фиксированная высота секции ДМ
                    } else if myVoteSent == nil {
                        // Игроки голосуют
                        HStack(spacing: 0) {
                            Button {
                                onVote(false)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14))
                                    Text("Против")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Добавлено maxHeight
                                .padding(.vertical, 18) // ✅ Увеличено с 16 до 18
                                .background(theme.danger)
                            }
                            .frame(maxWidth: .infinity) // ✅ Добавлено на Button
                            
                            Rectangle()
                                .fill(theme.border)
                                .frame(width: 0.5)
                            
                            Button {
                                onVote(true)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14))
                                    Text("За")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(theme.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Добавлено maxHeight
                                .padding(.vertical, 18) // ✅ Увеличено с 16 до 18
                                .background(theme.primary)
                            }
                            .frame(maxWidth: .infinity) // ✅ Добавлено на Button
                        }
                        .frame(height: 54) // ✅ Фиксированная высота секции кнопок
                    } else {
                        // Пользователь уже проголосовал
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: myVoteSent == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(myVoteSent == true ? .green : theme.danger)
                                
                                Text("Вы проголосовали: \(myVoteSent == true ? "ЗА" : "ПРОТИВ")")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(theme.text)
                            }
                            
                            Text("Ожидайте решения партии...")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textDim)
                            
                            // Кнопка отмены для ДМа
                            if isDungeonMaster, let onCancel = onCancel {
                                Button {
                                    onCancel()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 11))
                                        Text("Отменить голосование")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(theme.danger)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(theme.danger.opacity(0.1))
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 80) // ✅ Фиксированная минимальная высота
                        .padding(.vertical, 20)
                        .background(theme.surface)
                    }
                }
                .frame(
                    maxWidth: min(geometry.size.width * 0.9, 500), // ✅ Адаптивно: 90% или макс 500pt
                    maxHeight: geometry.size.height * 0.85 // ✅ Макс 85% высоты экрана
                )
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(restTypeColor.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: restTypeColor.opacity(pulseOpacity * 0.6), radius: 20)
                .shadow(color: restTypeColor.opacity(pulseOpacity * 0.3), radius: 40)
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseOpacity = 1.0
            }
        }
    }
    
    private var restTypeColor: Color {
        switch session.restType {
        case .short: return theme.tertiary
        case .long: return theme.primary
        }
    }
}

// MARK: - Preview
#Preview {
    @Environment(\.theme) var theme
    ZStack {
        theme.background.ignoresSafeArea()
        
        RestVoteOverlayView(
            session: PartyManager.RestVoteSession(
                initiatorID: UUID(),
                initiatorName: "Арагорн",
                restType: .short,
                votes: [UUID(): true],
                eligibleVoterIDs: [UUID(), UUID(), UUID(), UUID()] // 🆕 4 eligible voters
            ),
            myVoteSent: nil,
            isDungeonMaster: false, // 🆕 Добавили
            onVote: { _ in },
            onCancel: {} // 🆕 Добавили
        )
    }
    .preferredColorScheme(.dark)
}
