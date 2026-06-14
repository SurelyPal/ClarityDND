
//  LockedComponents.swift
//  Clarity
//
//  Компоненты для блокировки полей с визуальными индикаторами
//

import SwiftUI

// MARK: - 🔒 Заблокированное текстовое поле

struct LockedField: View {
    @Environment(\.theme) private var theme
    let label: String
    let value: String
    let isLocked: Bool
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(isLocked ? theme.textDim : theme.primaryDim)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(theme.danger.opacity(0.7))
                }
            }
            
            if isLocked {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 14))
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.surfaceAlt.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(theme.danger.opacity(0.2), lineWidth: 0.5)
                    )
                    .cornerRadius(4)
            } else {
                TextField("", text: $text)
                    .font(.system(size: 14))
                    .foregroundColor(theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(theme.surfaceAlt)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(theme.border, lineWidth: 0.5)
                    )
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - 🔒 Заблокированная секция

struct LockedSection<Content: View>: View {
    @Environment(\.theme) private var theme
    let title: String
    let isLocked: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(isLocked ? theme.textDim : theme.primary)
                
                if isLocked {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("ЗАБЛОКИРОВАНО")
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1)
                    }
                    .foregroundColor(theme.danger)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(theme.danger.opacity(0.15))
                    .cornerRadius(3)
                }
            }
            
            content()
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.6 : 1.0)
        .overlay(
            isLocked ?
            RoundedRectangle(cornerRadius: 6)
                .stroke(theme.danger.opacity(0.3), lineWidth: 1)
                .allowsHitTesting(false)
            : nil
        )
    }
}

// MARK: - 🔒 Заблокированная кнопка

struct LockedButton: View {
    @Environment(\.theme) private var theme
    let title: String
    let icon: String
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .padding(.leading, 4)
                }
            }
            .foregroundColor(isLocked ? theme.textDim : theme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isLocked ? theme.surfaceAlt.opacity(0.3) : theme.surfaceAlt)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isLocked ? theme.danger.opacity(0.3) : theme.primary.opacity(0.3), lineWidth: 0.5)
            )
            .cornerRadius(4)
        }
        .disabled(isLocked)
    }
}

