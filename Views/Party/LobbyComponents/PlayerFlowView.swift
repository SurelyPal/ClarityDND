//
//  PlayerFlowView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct PlayerFlowView: View {
    @ObservedObject var partyManager: PartyManager
    @EnvironmentObject var store: CharacterStore
    @State private var selectedCharacter: DNDCharacter?
    @State private var isLoadingCharacters = true
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoadingCharacters {
                characterSelection
            } else if store.characters.isEmpty {
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoadingCharacters = false
                }
            }
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
            
            if isLoadingCharacters {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCharacterRow()
                }
            } else {
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
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity
                    ))
                }
            }
            
            if !isLoadingCharacters && selectedCharacter != nil {
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
                .transition(.opacity)
            } else if !isLoadingCharacters {
                Text("Выберите героя, чтобы подключиться")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoadingCharacters)
    }
}