//
//  EditTemplateView.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI
import SwiftData

struct EditTemplateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var template: GameTemplate
    
    // Локальные состояния для редактирования
    @State private var name: String
    @State private var templateDescription: String
    @State private var selectedRaces: Set<String>
    @State private var selectedClasses: Set<String>
    
    init(template: GameTemplate) {
        self.template = template
        _name = State(initialValue: template.name)
        _templateDescription = State(initialValue: template.templateDescription)
        _selectedRaces = State(initialValue: Set(template.availableRaces))
        _selectedClasses = State(initialValue: Set(template.availableClasses))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text("✦ РЕДАКТИРОВАНИЕ ✦")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(3)
                            .foregroundColor(theme.primaryDim)
                        
                        Text("Шаблон Игры")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Базовая информация
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Название")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(theme.text)
                                    
                                    TextField("Название", text: $name)
                                        .textFieldStyle(.plain)
                                        .padding(12)
                                        .background(theme.surface)
                                        .foregroundColor(theme.text)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(theme.border, lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Описание")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(theme.text)
                                    
                                    TextField("Описание", text: $templateDescription, axis: .vertical)
                                        .textFieldStyle(.plain)
                                        .lineLimit(3...6)
                                        .padding(12)
                                        .background(theme.surface)
                                        .foregroundColor(theme.text)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(theme.border, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            DSdivider()
                            
                            // Выбор рас
                            raceSelectionSection
                            
                            DSdivider()
                            
                            // Выбор классов
                            classSelectionSection
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Кнопки действий
                    VStack(spacing: 12) {
                        Button {
                            saveChanges()
                        } label: {
                            HStack {
                                Text("Сохранить изменения")
                                Image(systemName: "checkmark")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(name.isEmpty ? theme.primary.opacity(0.3) : theme.primary)
                            .foregroundColor(theme.background)
                            .font(.system(size: 16, weight: .medium))
                            .cornerRadius(3)
                        }
                        .buttonStyle(.plain)
                        .disabled(name.isEmpty || template.isBuiltIn)
                        
                        if template.isBuiltIn {
                            Text("Встроенные шаблоны нельзя редактировать")
                                .font(.system(size: 11))
                                .foregroundColor(theme.textDim)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    // MARK: - Секции выбора
    
    private var raceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Доступные расы")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text("Если ничего не выбрано — доступны все расы")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
            }
            .padding(.horizontal, 20)
            
            ChipFlowLayout(spacing: 8) {
                ForEach(Race.allCases) { race in
                    RaceChip(
                        race: race,
                        isSelected: selectedRaces.contains(race.rawValue)
                    ) {
                        toggleRace(race)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                Button {
                    selectedRaces = Set(Race.allCases.map { $0.rawValue })
                } label: {
                    Text("Выбрать все")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.surface)
                        .foregroundColor(theme.primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    selectedRaces.removeAll()
                } label: {
                    Text("Сбросить")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.surface)
                        .foregroundColor(theme.textDim)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var classSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Доступные классы")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primary)
                
                Text("Если ничего не выбрано — доступны все классы")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
            }
            .padding(.horizontal, 20)
            
            ChipFlowLayout(spacing: 8) {
                ForEach(CharacterClass.allCases) { charClass in
                    ClassChip(
                        characterClass: charClass,
                        isSelected: selectedClasses.contains(charClass.rawValue)
                    ) {
                        toggleClass(charClass)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                Button {
                    selectedClasses = Set(CharacterClass.allCases.map { $0.rawValue })
                } label: {
                    Text("Выбрать все")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.surface)
                        .foregroundColor(theme.primary)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button {
                    selectedClasses.removeAll()
                } label: {
                    Text("Сбросить")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.surface)
                        .foregroundColor(theme.textDim)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Действия
    
    private func toggleRace(_ race: Race) {
        if template.isBuiltIn { return }
        if selectedRaces.contains(race.rawValue) {
            selectedRaces.remove(race.rawValue)
        } else {
            selectedRaces.insert(race.rawValue)
        }
        SoundManager.shared.play(.pageTurn, haptic: .light)
    }
    
    private func toggleClass(_ charClass: CharacterClass) {
        if template.isBuiltIn { return }
        if selectedClasses.contains(charClass.rawValue) {
            selectedClasses.remove(charClass.rawValue)
        } else {
            selectedClasses.insert(charClass.rawValue)
        }
        SoundManager.shared.play(.pageTurn, haptic: .light)
    }
    
    private func saveChanges() {
        template.name = name
        template.templateDescription = templateDescription
        template.availableRaces = Array(selectedRaces)
        template.availableClasses = Array(selectedClasses)
        
        try? context.save()
        SoundManager.shared.play(.levelUp, haptic: .success)
        dismiss()
    }
}
