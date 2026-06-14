//
//  TarotTabView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct TarotTabView: View {
    @Environment(\.theme) private var theme
    @Binding var character: DNDCharacter
    let canEdit: Bool
    @EnvironmentObject var store: CharacterStore
    @State private var showingAddCard = false
    @State private var editingCard: TarotCard? = nil
    
    var body: some View {
        
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill").foregroundColor(theme.primary)
                Text("Карты таро")
                    .font(.system(size: 13))
                    .tracking(1)
                    .foregroundColor(theme.textDim)
                Spacer()
                Text("\(character.tarotCards.count) карт")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
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
                .foregroundColor(theme.textDim)
            
            Button {
                character.tarotCards = TarotCard.starterDeck
                store.update(character)
            } label: {
                Text(canEdit ? "✦  Получить стартовую колоду  ✦" : "🔒 Заблокировано")  // 🆕
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1)
                    .foregroundColor(theme.background)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(theme.primary)
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
                    .foregroundColor(canEdit ? theme.primaryDim : theme.textDim)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(theme.surface)
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(theme.border, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canEdit)                    // 🆕
                .padding(.horizontal, 16)
            }
        }
        
    }
}
