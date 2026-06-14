//
//  NameStepView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI
import PhotosUI

struct NameStepView: View {
    @Environment(\.theme) private var theme
    @Binding var character: DNDCharacter
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                stepHeader
                
                avatarSection
                DSdivider()
                nameField
                backgroundField
                
                if character.characterClass == .bard {
                    instrumentPicker
                }
                
                alignmentGrid
            }
            .padding(.horizontal, 20)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let item = newItem,
                      let data = try? await item.loadTransferable(type: Data.self),
                      let compressed = ImageCompressor.compress(data) else { return }
                character.avatarData = compressed
            }
        }
    }
    
    // MARK: - Аватар
    
    private var avatarSection: some View {
        VStack(spacing: 12) {
            AvatarView(
                avatarData: character.avatarData,
                race: character.race,
                size: 120
            )
            
            HStack(spacing: 10) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 11))
                        Text("Выбрать из галереи")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(0.5)
                    }
                    .foregroundColor(theme.background)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(theme.primary)
                    .cornerRadius(3)
                }
                .buttonStyle(.plain)
                
                if character.avatarData != nil {
                    Button {
                        withAnimation { character.avatarData = nil }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(theme.danger)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(theme.danger.opacity(0.15))
                            .cornerRadius(3)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Инструмент (для барда)

    private var instrumentPicker: some View {
        
        VStack(alignment: .leading, spacing: 10) {
            Text("МУЗЫКАЛЬНЫЙ ИНСТРУМЕНТ")
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(theme.textDim)
            
            Text("Инструмент будет автоматически добавлен в инвентарь. Модификации привязаны к конкретному инструменту.")
                .font(.system(size: 10))
                .foregroundColor(theme.textDim.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 10) {
                instrumentButton(type: .lute)
                instrumentButton(type: .flute)
                instrumentButton(type: .drum)
            }
        }
    }

    private func instrumentButton(type: InstrumentType) -> some View {
        let isSelected = character.instrument == type.rawValue
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                // Удаляем старый инструмент из инвентаря, если был
                character.inventory.removeAll { item in
                    item.slot == .misc && InstrumentType.from(name: item.name) != nil
                }
                
                // Устанавливаем legacy поле
                character.instrument = type.rawValue
                
                // Создаём предмет-инструмент и сразу экипируем
                var instrumentItem = InventoryItem()
                instrumentItem.name = type.rawValue
                instrumentItem.description = type.loreDescription
                instrumentItem.slot = .misc  // Используем существующий слот
                instrumentItem.isEquipped = true
                
                character.inventory.append(instrumentItem)
            }
        } label: {
            VStack(spacing: 8) {
                Text(type.icon).font(.system(size: 28))
                Text(type.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? theme.primary : theme.textDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? type.backgroundColor : theme.surface)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        isSelected ? type.accentColor : theme.border,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
    // MARK: - Поля ввода
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Шаг 4 из 4")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(theme.textDim)
            Text("Имя и мировоззрение")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(theme.primary)
            DSdivider().padding(.top, 4)
        }
    }
    
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ИМЯ ГЕРОЯ")
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(theme.textDim)
            TextField("Aragorn, Legolas...", text: $character.name)
                .font(.system(size: 15))
                .foregroundColor(theme.text)
                .padding(12)
                .background(theme.surface)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(theme.border, lineWidth: 0.5)
                )
        }
    }
    
    private var backgroundField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ПРЕДЫСТОРИЯ")
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(theme.textDim)
            TextField("Аколит, Преступник, Герой...", text: $character.background)
                .font(.system(size: 15))
                .foregroundColor(theme.text)
                .padding(12)
                .background(theme.surface)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(theme.border, lineWidth: 0.5)
                )
        }
    }
    
    private var alignmentGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("МИРОВОЗЗРЕНИЕ")
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(theme.textDim)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 3),
                spacing: 8
            ) {
                ForEach(DNDAlignment.allCases) { item in
                    AlignmentButton(
                        title: item.rawValue,
                        isSelected: character.alignment == item,
                        action: { character.alignment = item }
                    )
                }
            }
        }
    }
}

struct AlignmentButton: View {
    @Environment(\.theme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10))
                .tracking(0.5)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .background(isSelected ? theme.primary.opacity(0.12) : theme.surface)
                .foregroundColor(isSelected ? theme.primary : theme.textDim)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            isSelected ? theme.primary : theme.border,
                            lineWidth: isSelected ? 1 : 0.5
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
