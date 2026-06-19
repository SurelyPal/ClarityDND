//
//  DynamicFieldView.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import SwiftUI
import SwiftData

/// Универсальный рендерер для динамических полей
/// Автоматически выбирает UI контрол в зависимости от типа поля
struct DynamicFieldView: View {
    @Bindable var fieldValue: FieldValue
    let fieldDefinition: FieldDefinition
    
    var body: some View {
        HStack {
            // Название поля с цветным индикатором
            HStack(spacing: 8) {
                if let colorHex = fieldDefinition.displayColor {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 12, height: 12)
                }
                
                Text(fieldDefinition.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Рендерим контрол в зависимости от типа
            switch fieldDefinition.fieldType {
            case .integer:
                IntegerFieldView(fieldValue: fieldValue, fieldDefinition: fieldDefinition)
                
            case .text:
                TextFieldView(fieldValue: fieldValue, fieldDefinition: fieldDefinition)
                
            case .boolean:
                BooleanFieldView(fieldValue: fieldValue, fieldDefinition: fieldDefinition)
                
            case .enumType:
                EnumFieldView(fieldValue: fieldValue, fieldDefinition: fieldDefinition)
                
            case .dice:
                DiceFieldView(fieldValue: fieldValue, fieldDefinition: fieldDefinition)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Integer Field (Stepper)
private struct IntegerFieldView: View {
    @Bindable var fieldValue: FieldValue
    let fieldDefinition: FieldDefinition
    
    var body: some View {
        Stepper(
            value: Binding(
                get: { fieldValue.getIntValue() },
                set: { fieldValue.setIntValue($0) }
            ),
            in: (fieldDefinition.minValue ?? 0)...(fieldDefinition.maxValue ?? 9999),
            step: 1
        ) {
            Text("\(fieldValue.getIntValue())")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .labelsHidden()
    }
}

// MARK: - Text Field (TextField)
private struct TextFieldView: View {
    @Bindable var fieldValue: FieldValue
    let fieldDefinition: FieldDefinition
    
    var body: some View {
        TextField(
            "Введите \(fieldDefinition.name)",
            text: Binding(
                get: { fieldValue.getStringValue() },
                set: { fieldValue.setStringValue($0) }
            )
        )
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 200)
    }
}

// MARK: - Boolean Field (Toggle)
private struct BooleanFieldView: View {
    @Bindable var fieldValue: FieldValue
    let fieldDefinition: FieldDefinition
    
    var body: some View {
        Toggle(
            "",
            isOn: Binding(
                get: { fieldValue.getBoolValue() },
                set: { fieldValue.setBoolValue($0) }
            )
        )
        .labelsHidden()
        .toggleStyle(.switch)
    }
}

// MARK: - Enum Field (Picker)
private struct EnumFieldView: View {
    @Bindable var fieldValue: FieldValue
    let fieldDefinition: FieldDefinition
    
    var body: some View {
        // TODO: В будущем здесь будет парсинг опций из jsonValue
        Text("Enum (скоро)")
            .foregroundColor(.secondary)
    }
}

// MARK: - Dice Field (Dice Roller)
private struct DiceFieldView: View {
    @Bindable var fieldValue: FieldValue
    let fieldDefinition: FieldDefinition
    
    var body: some View {
        // TODO: В будущем здесь будет DiceRoller
        Text("Dice (скоро)")
            .foregroundColor(.secondary)
    }
}

// MARK: - Color Extension для HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
