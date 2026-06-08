//
//  TarotTabView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct TarotTabView: View {
    
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    @State private var showingAddCard = false
    @State private var editingCard: TarotCard? = nil
    
    var body: some View {
        
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill").foregroundColor(Color.dsGold)
                Text("Карты таро")
                    .font(.system(size: 13))
                    .tracking(1)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
                Text("\(character.tarotCards.count) карт")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
            }
            .padding(.horizontal, 16)
            
            if character.tarotCards.isEmpty {
                emptyDeckView
            } else {
                deckView
            }
        }
        .sheet(isPresented: $showingAddCard) {
            TarotCardEditorView(card: TarotCard()) { newCard in
                character.tarotCards.append(newCard)
                store.update(character)
            }
        }
        .sheet(item: $editingCard) { card in
            TarotCardEditorView(card: card) { updatedCard in
                if let index = character.tarotCards.firstIndex(where: { $0.id == card.id }) {
                    character.tarotCards[index] = updatedCard
                    store.update(character)
                }
            }
        }
    }
    
    private var emptyDeckView: some View {
        VStack(spacing: 12) {
            Text("🃏").font(.system(size: 40))
            Text("Колода пуста")
                .font(.system(size: 14))
                .foregroundColor(Color.dsTextDim)
            
            Button {
                character.tarotCards = TarotCard.starterDeck
                store.update(character)
            } label: {
                Text(canEdit ? "✦  Получить стартовую колоду  ✦" : "🔒 Заблокировано")  // 🆕
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color.dsBackground)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.dsGold)
                    .cornerRadius(3)
            }
            .buttonStyle(.plain)
            .disabled(!canEdit)                // 🆕
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    private var deckView: some View {
        VStack(spacing: 16) {
            // Сетка карт
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach($character.tarotCards) { $card in
                    TarotCardView(
                        card: $card,
                        canEdit: canEdit,                    // 🆕
                        onUse: {
                            guard card.canUse else { return }
                            card.use()
                            store.update(character)
                        },
                        onEdit: { editingCard = card }
                    )
                }
                .padding(.horizontal, 16)
                
                Button { showingAddCard = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: canEdit ? "plus" : "lock.fill")
                        Text("Добавить карту")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(canEdit ? Color.dsGoldDim : Color.dsTextDim)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.dsSurface)
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.dsBorder, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)                    // 🆕
                .padding(.horizontal, 16)
            }
        }
        
    }
}
