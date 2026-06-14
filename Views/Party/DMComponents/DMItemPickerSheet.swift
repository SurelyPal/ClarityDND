//
//  DMItemPickerSheet.swift
//  Clarity
//
//  Created by KEBAB on 14.06.2026.
//

import SwiftUI

struct DMItemPickerSheet: View {
    let member: PartyMember
    let onSelect: (InventoryItem) -> Void

    @ObservedObject var partyManager = PartyManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingAddItem = false

    var body: some View {
        VStack(spacing: 16) {
            Text("✦ ВЫДАТЬ ПРЕДМЕТ ✦")
                .font(.system(size: 11, weight: .bold))
                .tracking(3)
                .foregroundColor(Color.dsGold)

            Text("Игрок: \(member.name)")
                .font(.system(size: 13))
                .foregroundColor(Color.dsTextDim)

            DSdivider()
                .padding(.horizontal, 40)

            if partyManager.dmItemStorage.isEmpty {
                // Пустое хранилище
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 40))
                        .foregroundColor(Color.dsTextDim.opacity(0.5))

                    Text("Хранилище пусто")
                        .font(.system(size: 13))
                        .foregroundColor(Color.dsText)

                    Button {
                        showingAddItem = true
                    } label: {
                        Text("✦ Добавить предмет ✦")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.dsBackground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.dsGold)
                            .cornerRadius(3)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                // Список предметов
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(partyManager.dmItemStorage) { item in
                            Button {
                                onSelect(item)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: IconHelper.iconForItem(item))
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.dsGold)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.dsText)

                                        if !item.stats.isEmpty {
                                            Text(item.stats)
                                                .font(.system(size: 10))
                                                .foregroundColor(Color.dsGold)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.dsGold)
                                }
                                .padding(12)
                                .background(Color.dsSurface)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.dsBorder, lineWidth: 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("ОТМЕНА")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dsSurfaceAlt)
                    .foregroundColor(Color.dsText)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(Color.dsBackground)
        .presentationDetents([.medium, .large])
        // Лист добавления предмета прямо из пикера
        .sheet(isPresented: $showingAddItem) {
            ItemEditorView(item: InventoryItem()) { newItem in
                partyManager.addItemToStorage(newItem)
            }
        }
    }
}
