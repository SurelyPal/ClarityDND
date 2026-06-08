//
//  ItemEditorView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI

struct ItemEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State var item: InventoryItem
    let onSave: (InventoryItem) -> Void
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ПРЕДМЕТ")
                            .font(.system(size: 10))
                            .tracking(3)
                            .foregroundColor(Color.dsTextDim)
                        Text(item.name.isEmpty ? "Новый предмет" : item.name)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(Color.dsGold)
                        DSdivider()
                    }
                    
                    editorField(label: "НАЗВАНИЕ",
                                placeholder: "Меч тьмы, Кольцо удачи...",
                                text: $item.name)
                    
                    slotPicker
                    
                    editorField(label: "СТАТЫ",
                                placeholder: "+2 к силе, 1d8 урона, -1 к ловкости...",
                                text: $item.stats)
                    
                    descriptionEditor
                    
                    saveButton
                }
                .padding(20)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var slotPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ТИП ПРЕДМЕТА")
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(Color.dsTextDim)
            
            HStack {
                Image(systemName: item.slot.icon)
                    .foregroundColor(Color.dsGold)
                    .frame(width: 20)
                
                Picker("Тип", selection: $item.slot) {
                    ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                        HStack {
                            Image(systemName: slot.icon)
                            Text(slot.rawValue)
                        }.tag(slot)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.dsText)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.dsSurface)
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.dsBorder, lineWidth: 0.5)
            )
        }
    }
    
    private var descriptionEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ОПИСАНИЕ")
                .font(.system(size: 10))
                .tracking(2)
                .foregroundColor(Color.dsTextDim)
            
            TextEditor(text: $item.description)
                .font(.system(size: 14))
                .foregroundColor(Color.dsText)
                .frame(minHeight: 120)
                .padding(10)
                .background(Color.dsSurface)
                .cornerRadius(3)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.dsBorder, lineWidth: 0.5)
                )
                .overlay(alignment: .topLeading) {
                    if item.description.isEmpty {
                        Text("Опишите предмет, его историю, особые свойства...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.dsTextDim.opacity(0.6))
                            .padding(14)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    private var saveButton: some View {
        // Кнопка сохранить
        Button(action: {
            // ✅ ПРЕДМЕТ ВСЕГДА СОХРАНЯЕТСЯ В ИНВЕНТАРЬ (не надет)
            // Слот определяет ТИП предмета, а не факт его ношения
            
            // При создании нового предмета — всегда не надет
            // При редактировании существующего — сохраняем текущее состояние
            if item.isEquipped && !item.slot.isEquippable {
                // Если слот сменили на не-экипируемый — принудительно снять
                item.isEquipped = false
            }
            
            onSave(item)
            dismiss()
        }) {
            Text("✦  Сохранить предмет  ✦")
                .font(.system(size: 15, weight: .medium))
                .tracking(1)
                .foregroundColor(Color.dsBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(item.name.isEmpty ? Color.dsGoldDim : Color.dsGold)
                .cornerRadius(3)
        }
        .disabled(item.name.isEmpty)
        .buttonStyle(.plain)
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

