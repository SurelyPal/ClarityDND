//
//  PartyMembersDrawer.swift
//  Clarity
//
//  Выезжающая панель с профилями сопартийцев
//

import SwiftUI

struct PartyMembersDrawer: View {
    @ObservedObject var partyManager: PartyManager
    @Binding var isOpen: Bool
    let members: [PartyMember]
    let onSelect: (PartyMember) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            
            Spacer()
            // ═══════════════════════════════════════
            // 📜 СОДЕРЖИМОЕ DRAWER'А
            // ═══════════════════════════════════════
            VStack(spacing: 0) {
                // Заголовок
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.dsGold)
                    
                    Text("ПАРТИЯ")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(2)
                        .foregroundColor(Color.dsGold)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            isOpen = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.dsTextDim)
                            .padding(6)
                            .background(Color.dsSurfaceAlt)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)  // Учитываем safe area
                .padding(.bottom, 12)
                
                DSdivider()
                    .padding(.horizontal, 16)
                
                // Список игроков
                if members.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(partyManager.partyMembers) { member in
                                Button {
                                    onSelect(member)
                                } label: {
                                    PartyMemberCard(member: member)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
                
                Spacer()
                
                // Подсказка снизу
                VStack(spacing: 4) {
                    DSdivider()
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 9))
                        Text("Нажмите на профиль")
                            .font(.system(size: 9))
                            .tracking(0.5)
                    }
                    .foregroundColor(Color.dsTextDim)
                    .padding(.vertical, 12)
                }
            }
            .frame(width: 280)
                .background(Color.dsSurface)
                .overlay(
                    Rectangle()
                        .fill(Color.dsBorder)
                        .frame(width: 0.5),
                    alignment: .leading  // 🆕 Тень СЛЕВА от drawer'а
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: -5, y: 0)
            
            // Пустое пространство справа (чтобы drawer не занимал весь экран)
            Spacer()
        }
        .compositingGroup()
        .offset(x: isOpen ? 0 : 400)  // 🆕 +280 вместо -280 (уезжает вправо)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isOpen)
        .zIndex(1000)
    }
    
    // MARK: - Пустое состояние
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 36))
                .foregroundColor(Color.dsTextDim.opacity(0.3))
            
            Text("Партия пуста")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.dsText)
            
            Text("Здесь появятся профили ваших сопартийцев, когда они подключатся")
                .font(.system(size: 10))
                .foregroundColor(Color.dsTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

// ═══════════════════════════════════════
// 🃏 КАРТОЧКА ОДНОГО ИГРОКА В DRAWER'Е
// ═══════════════════════════════════════

struct PartyMemberCard: View {
    let member: PartyMember
    
    var body: some View {
        HStack(spacing: 12) {
            // Аватар с индикатором онлайн/офлайн
            ZStack(alignment: .bottomTrailing) {
                AvatarView(avatarData: member.avatarData, race: member.race, size: 50)
                
                Circle()
                    .fill(member.isConnected ? Color.green : Color.dsRed)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle().stroke(Color.dsSurface, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2)
            }
            
            // Информация
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(member.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(member.isConnected ? Color.dsText : Color.dsTextDim)
                        .lineLimit(1)
                    
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
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsTextDim)
                    .lineLimit(1)
                
                // HP индикатор
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color.dsRed)
                    
                    Text("\(member.currentHP)/\(member.maxHP)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(hpColor)
                    
                    Spacer()
                    
                    DSBadge(text: "Веха \(member.level)", color: .dsGold)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.dsTextDim)
        }
        .padding(12)
        .background(Color.dsSurfaceAlt)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    member.isConnected ? Color.dsGold.opacity(0.3) : Color.dsBorder.opacity(0.5),
                    lineWidth: 0.5
                )
        )
        .cornerRadius(6)
    }
    
    private var hpColor: Color {
        let fraction = member.hpFraction
        if fraction > 0.5 { return Color.dsGold }
        if fraction > 0.25 { return .orange }
        return Color.dsRed
    }
}

