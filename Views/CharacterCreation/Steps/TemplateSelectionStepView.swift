//
//  TemplateSelectionStepView.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI
import SwiftData

struct TemplateSelectionStepView: View {
    @Environment(\.theme) private var theme
    @Binding var selectedTemplate: GameTemplate?
    let templates: [GameTemplate]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                stepHeader
                
                DSdivider().padding(.bottom, 8)
                
                if templates.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(templates) { template in
                            TemplateCard(
                                name: template.name,
                                description: template.templateDescription,
                                isSelected: selectedTemplate?.id == template.id
                            )
                            .onTapGesture {
                                selectedTemplate = template
                                SoundManager.shared.play(.pageTurn, haptic: .light)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Шаг 1 из 5")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(theme.textDim)
            Text("Выберите шаблон игры")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(theme.primary)
                .padding(.bottom, 8)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(theme.textDim.opacity(0.5))
            
            Text("Шаблонов пока нет")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("Создайте шаблон в настройках, чтобы начать создание персонажа")
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Карточка шаблона

struct TemplateCard: View {
    @Environment(\.theme) private var theme
    let name: String
    let description: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(theme.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }
            }
            
            Text(name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.text)
                .lineLimit(1)
            
            Text(description.isEmpty ? "Без описания" : description)
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surfaceAlt)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected ? Color.green : theme.border,
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }
}

// MARK: - Preview

#Preview {
    TemplateSelectionStepView(
        selectedTemplate: .constant(nil),
        templates: []
    )
}
