//
//  DMItemStorageView.swift
//  Clarity
//
//  Created by KEBAB on 14.06.2026.
//

import SwiftUI

struct DMItemStorageView: View {
    @ObservedObject var partyManager = PartyManager.shared
    @State private var showingAddItem = false
    @State private var editingItem: InventoryItem?

    var body: some View {
        VStack(spacing: 16) {
            // Заголовок
            HStack {
                DSSectionHeader(title: "Хранилище предметов")
                    .padding(.horizontal, 0)

                Spacer()

                Button {
                    showingAddItem = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .foregroundColor(Color.dsGold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // Статистика
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(Color.dsGold)
                Text("\(partyManager.dmItemStorage.count) предметов в хранилище")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsTextDim)
                Spacer()
            }
            .padding(.horizontal, 16)

            // Список предметов
            if partyManager.dmItemStorage.isEmpty {
                emptyStorageView
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(partyManager.dmItemStorage.enumerated()), id: \.element.id) { index, item in
                        storageItemRow(item: item, index: index)
                    }
                }
                .dsCard()
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        // Лист добавления нового предмета
        .sheet(isPresented: $showingAddItem) {
            ItemEditorView(item: InventoryItem()) { newItem in
                partyManager.addItemToStorage(newItem)
            }
        }
        // Лист редактирования
        .sheet(item: $editingItem) { item in
            ItemEditorView(item: item) { updatedItem in
                var storage = partyManager.dmItemStorage
                if let idx = storage.firstIndex(where: { $0.id == item.id }) {
                    storage[idx] = updatedItem
                    partyManager.dmItemStorage = storage
                }
            }
        }
    }

    // MARK: - Пустое хранилище
    private var emptyStorageView: some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 40))
                .foregroundColor(Color.dsTextDim.opacity(0.5))

            Text("Хранилище пусто")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.dsText)

            Text("Добавьте предметы, которые будете выдавать игрокам")
                .font(.system(size: 11))
                .foregroundColor(Color.dsTextDim)
                .multilineTextAlignment(.center)

            Button {
                showingAddItem = true
            } label: {
                Text("✦ Добавить первый предмет ✦")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundColor(Color.dsBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.dsGold)
                    .cornerRadius(3)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .dsCard()
        .padding(.horizontal, 16)
    }

    // MARK: - Строка предмета
    private func storageItemRow(item: InventoryItem, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: IconHelper.iconForItem(item))
                .font(.system(size: 18))
                .foregroundColor(Color.dsGold)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsText)

                if !item.stats.isEmpty {
                    Text(item.stats)
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsGold)
                }

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsTextDim)
                        .lineLimit(2)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    editingItem = item
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.dsGold)
                }
                .buttonStyle(.plain)

                Button {
                    partyManager.removeItemFromStorage(itemID: item.id)
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.dsRed)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if index < partyManager.dmItemStorage.count - 1 {
                Rectangle()
                    .fill(Color.dsBorder)
                    .frame(height: 0.5)
            }
        }
    }
}
