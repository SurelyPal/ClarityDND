//
//  TarotCardEditorView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct TarotCardEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var card: TarotCard
    let onSave: (TarotCard) -> Void
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок
                    VStack(alignment: .leading, spacing: 4) {
                        Text("КАРТА ТАРО")
                            .font(.system(size: 10))
                            .tracking(3)
                            .foregroundColor(Color.dsTextDim)
                        Text(card.name.isEmpty ? "Новая карта" : card.name)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Color.dsGold)
                        DSdivider()
                    }
                    
                    // Название карты
                    editorField(label: "НАЗВАНИЕ",
                                placeholder: "Шут, Маг, Смерть...",
                                text: $card.name)
                    
                    // Аркан
                    editorField(label: "АРКАН",
                                placeholder: "Старший аркан, Жезлы, Кубки...",
                                text: $card.arcana)
                    
                    // Эффект карты
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ЭФФЕКТ В ИГРЕ")
                            .font(.system(size: 10))
                            .tracking(2)
                            .foregroundColor(Color.dsTextDim)
                        TextEditor(text: $card.effect)
                            .font(.system(size: 14))
                            .foregroundColor(Color.dsText)
                            .frame(minHeight: 100)
                            .padding(10)
                            .background(Color.dsSurface)
                            .cornerRadius(3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.dsBorder, lineWidth: 0.5)
                            )
                            .overlay(
                                Group {
                                    if card.effect.isEmpty {
                                        Text("Опишите что происходит когда карта разыгрывается...")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.dsTextDim.opacity(0.6))
                                            .padding(14)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                    }
                    
                    // Количество использований за сессию
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ИСПОЛЬЗОВАНИЙ ЗА СЕССИЮ")
                            .font(.system(size: 10))
                            .tracking(2)
                            .foregroundColor(Color.dsTextDim)
                        HStack {
                            Button { if card.usesLeft > 1 { card.usesLeft -= 1 } } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(Color.dsTextDim)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(card.usesLeft)")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(Color.dsGold)
                                .frame(width: 50, alignment: .center)
                            
                            Button { card.usesLeft += 1 } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color.dsGoldDim)
                                    .font(.system(size: 20))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Перевёрнута или нет
                    HStack {
                        Text("ПЕРЕВЁРНУТАЯ КАРТА")
                            .font(.system(size: 10))
                            .tracking(2)
                            .foregroundColor(Color.dsTextDim)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { !card.isRevealed },
                            set: { card.isRevealed = !$0 }
                        ))
                        .tint(Color.dsRed)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.dsSurface)
                    .cornerRadius(3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.dsBorder, lineWidth: 0.5)
                    )
                    
                    // Сохранить
                    Button {
                        onSave(card)
                        dismiss()
                    } label: {
                        Text("✦  Сохранить карту  ✦")
                            .font(.system(size: 15, weight: .medium))
                            .tracking(1)
                            .foregroundColor(Color.dsBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(card.name.isEmpty ? Color.dsGoldDim : Color.dsGold)
                            .cornerRadius(3)
                    }
                    .disabled(card.name.isEmpty)
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func editorField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(Color.dsTextDim)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(Color.dsText)
                .padding(12)
                .background(Color.dsSurface)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.dsBorder, lineWidth: 0.5)
                )
        }
    }
}
