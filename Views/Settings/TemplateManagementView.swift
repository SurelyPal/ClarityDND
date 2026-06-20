//
// TemplateManagementView.swift
// Clarity
//
// Created by KEBAB on 19.06.2026.
//

import SwiftUI
import SwiftData

/// Экран управления шаблонами игр
struct TemplateManagementView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GameTemplate.name) private var templates: [GameTemplate]
    @State private var showingAddTemplate = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    headerSection
                    
                    if templates.isEmpty {
                        emptyState
                    } else {
                        templatesList
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTemplate = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Новый шаблон")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(theme.primary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Шаблоны игр")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplateView()
            }
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("✦ СИСТЕМЫ ✦")
                .font(.system(size: 9, weight: .medium))
                .tracking(3)
                .foregroundColor(theme.primaryDim)
            
            Text("Шаблоны Игр")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.primary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(theme.primaryDim.opacity(0.5))
            
            Text("Шаблонов пока нет")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(theme.text)
            
            Text("Создайте свой первый шаблон игры,\nчтобы начать создавать персонажей")
                .font(.system(size: 14))
                .foregroundColor(theme.textDim)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddTemplate = true
                SoundManager.shared.play(.pageTurn, haptic: .light)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Создать шаблон")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.primary)
                .foregroundColor(theme.background)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var templatesList: some View {
        List {
            ForEach(templates) { template in
                TemplateRowView(template: template)
                    .listRowBackground(theme.surface)
                    .listRowSeparatorTint(theme.border)
            }
            .onDelete(perform: deleteTemplates)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.background)
    }
    
    // MARK: - Actions
    
    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = templates[index]
            // Нельзя удалить встроенные шаблоны
            if template.isBuiltIn {
                print("⚠️ Нельзя удалить встроенный шаблон: \(template.name)")
                continue
            }
            context.delete(template)
        }
        try? context.save()
    }
}

// MARK: - Строка шаблона
struct TemplateRowView: View {
    @Environment(\.theme) private var theme
    let template: GameTemplate
    
    var body: some View {
        VStack(spacing: 12) {
            // Основная информация
            NavigationLink(destination: TemplateDetailView(template: template)) {
                HStack(spacing: 12) {
                    // Иконка шаблона
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(template.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.text)
                            
                            if template.isBuiltIn {
                                Text("ВСТРОЕН")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.primary.opacity(0.2))
                                    .foregroundColor(theme.primary)
                                    .cornerRadius(4)
                            }
                        }
                        
                        if !template.templateDescription.isEmpty {
                            Text(template.templateDescription)
                                .font(.system(size: 12))
                                .foregroundColor(theme.textDim)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 10))
                            Text("\(template.fieldDefinitions.count)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(theme.textDim)
                        
                        Text("полей")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textDim)
                    }
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            DSdivider()
            
            // Кнопка механик
            NavigationLink {
                MechanicsListView(gameTemplate: template)
            } label: {
                HStack {
                    Image(systemName: "gearshape.2.fill")
                        .foregroundColor(theme.primary)
                    
                    Text("Механики")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textDim)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Детальный вид шаблона
struct TemplateDetailView: View {
    @Bindable var template: GameTemplate
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @State private var showingAddField = false
    
    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()
            
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 24))
                                .foregroundColor(theme.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(theme.text)
                                
                                if template.isBuiltIn {
                                    Text("Встроенный шаблон")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.primary)
                                }
                            }
                        }
                        
                        if !template.templateDescription.isEmpty {
                            Text(template.templateDescription)
                                .font(.system(size: 14))
                                .foregroundColor(theme.textDim)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Информация")
                        .foregroundColor(theme.textDim)
                }
                
                Section {
                    ForEach(template.fieldDefinitions) { field in
                        FieldRowView(field: field)
                    }
                    .onDelete(perform: deleteFields)
                } header: {
                    HStack {
                        Text("Поля")
                            .foregroundColor(theme.textDim)
                        
                        Spacer()
                        
                        Text("\(template.fieldDefinitions.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textDim)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(theme.surfaceAlt)
                            .cornerRadius(4)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.background)
        }
        .navigationTitle(template.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if !template.isBuiltIn {
                    NavigationLink {
                        EditTemplateView(template: template)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.circle.fill")
                            Text("Изменить")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(theme.primary)
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddField = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Новое поле")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .sheet(isPresented: $showingAddField) {
            AddFieldView(template: template)
        }
    }
    
    private func deleteFields(at offsets: IndexSet) {
        for index in offsets {
            let field = template.fieldDefinitions[index]
            context.delete(field)
            template.fieldDefinitions.remove(at: index)
        }
        try? context.save()
    }
}

// MARK: - Строка поля
struct FieldRowView: View {
    @Environment(\.theme) private var theme
    let field: FieldDefinition
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка типа поля
            ZStack {
                Circle()
                    .fill(theme.surfaceAlt)
                    .frame(width: 36, height: 36)
                
                Image(systemName: field.fieldType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(field.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.text)
                
                HStack(spacing: 8) {
                    Text("Ключ: \(field.key)")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textDim)
                    
                    if field.showOnSheet {
                        Text("В листе")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(theme.primary.opacity(0.2))
                            .foregroundColor(theme.primary)
                            .cornerRadius(3)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(field.fieldType.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textDim)
                
                Text("По умолч: \(field.defaultValue)")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Добавление нового шаблона

struct AddTemplateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var templateDescription = ""
    
    // 🆕 НОВОЕ: Выбор доступных рас и классов
    @State private var selectedRaces: Set<String> = []
    @State private var selectedClasses: Set<String> = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text("✦ НОВЫЙ ✦")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(3)
                            .foregroundColor(theme.primaryDim)
                        
                        Text("Шаблон Игры")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Форма
                    ScrollView {
                        VStack(spacing: 20) {
                            // Базовая информация
                            VStack(spacing: 16) {
                                // Название
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Название")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(theme.text)
                                    
                                    TextField("Например: Моя система", text: $name)
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
                                
                                // Описание
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Описание")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(theme.text)
                                    
                                    TextField("Описание системы (необязательно)", text: $templateDescription, axis: .vertical)
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
                            
                            // 🆕 НОВОЕ: Выбор рас
                            raceSelectionSection
                            
                            DSdivider()
                            
                            // 🆕 НОВОЕ: Выбор классов
                            classSelectionSection
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Кнопка создания
                    Button {
                        createTemplate()
                    } label: {
                        HStack {
                            Text("Создать шаблон")
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
                    .disabled(name.isEmpty)
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
    
    // 🆕 НОВОЕ: Секция выбора рас
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
            
            // Чипы с расами
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
            
            // Кнопки быстрого выбора
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
    
    // 🆕 НОВОЕ: Секция выбора классов
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
            
            // Чипы с классами
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
            
            // Кнопки быстрого выбора
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
    
    // 🆕 НОВОЕ: Методы переключения
    private func toggleRace(_ race: Race) {
        if selectedRaces.contains(race.rawValue) {
            selectedRaces.remove(race.rawValue)
        } else {
            selectedRaces.insert(race.rawValue)
        }
        SoundManager.shared.play(.pageTurn, haptic: .light)
    }
    
    private func toggleClass(_ charClass: CharacterClass) {
        if selectedClasses.contains(charClass.rawValue) {
            selectedClasses.remove(charClass.rawValue)
        } else {
            selectedClasses.insert(charClass.rawValue)
        }
        SoundManager.shared.play(.pageTurn, haptic: .light)
    }
    
    private func createTemplate() {
        let template = GameTemplate(
            name: name,
            templateDescription: templateDescription,
            isBuiltIn: false,
            availableRaces: Array(selectedRaces), // 🆕 НОВОЕ
            availableClasses: Array(selectedClasses) // 🆕 НОВОЕ
        )
        context.insert(template)
        try? context.save()
        SoundManager.shared.play(.levelUp, haptic: .success)
        dismiss()
    }
}

// MARK: - Добавление нового поля
struct AddFieldView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    let template: GameTemplate
    @State private var name = ""
    @State private var key = ""
    @State private var fieldType: FieldType = .integer
    @State private var defaultValue = "0"
    @State private var showOnSheet = true
    @State private var isEditableByPlayer = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Заголовок
                    VStack(spacing: 8) {
                        Text("✦ НОВОЕ ✦")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(3)
                            .foregroundColor(theme.primaryDim)
                        
                        Text("Поле Шаблона")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(theme.primary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Форма
                    ScrollView {
                        VStack(spacing: 16) {
                            // Идентификация
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Идентификация")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.primary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Название")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textDim)
                                    
                                    TextField("Например: Стресс", text: $name)
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
                                    Text("Ключ (латиница)")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textDim)
                                    
                                    TextField("Например: stress", text: $key)
                                        .textFieldStyle(.plain)
                                        #if os(iOS)
                                        .textInputAutocapitalization(.never)
                                        #endif
                                        .autocorrectionDisabled(true)
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
                            
                            DSdivider()
                            
                            // Тип поля
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Тип поля")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.primary)
                                
                                Picker("Тип", selection: $fieldType) {
                                    ForEach(FieldType.allCases) { type in
                                        Label(type.displayName, systemImage: type.icon)
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(12)
                                .background(theme.surface)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                            }
                            
                            DSdivider()
                            
                            // Значение по умолчанию
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Значение по умолчанию")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textDim)
                                
                                TextField("0", text: $defaultValue)
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
                            
                            DSdivider()
                            
                            // Отображение
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Отображение")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.primary)
                                
                                Toggle(isOn: $showOnSheet) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Показывать в листе персонажа")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.text)
                                        
                                        Text("Поле будет видно игроку")
                                            .font(.system(size: 11))
                                            .foregroundColor(theme.textDim)
                                    }
                                }
                                .tint(theme.primary)
                                
                                Toggle(isOn: $isEditableByPlayer) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Игрок может редактировать")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(theme.text)
                                        
                                        Text("Разрешить игроку изменять значение")
                                            .font(.system(size: 11))
                                            .foregroundColor(theme.textDim)
                                    }
                                }
                                .tint(theme.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Кнопка добавления
                    Button {
                        addField()
                    } label: {
                        HStack {
                            Text("Добавить поле")
                            Image(systemName: "checkmark")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(name.isEmpty || key.isEmpty ? theme.primary.opacity(0.3) : theme.primary)
                        .foregroundColor(theme.background)
                        .font(.system(size: 16, weight: .medium))
                        .cornerRadius(3)
                    }
                    .buttonStyle(.plain)
                    .disabled(name.isEmpty || key.isEmpty)
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
    
    private func addField() {
        let field = FieldDefinition(
            name: name,
            key: key,
            fieldType: fieldType,
            defaultValue: defaultValue,
            showOnSheet: showOnSheet,
            isEditableByPlayer: isEditableByPlayer
        )
        template.fieldDefinitions.append(field)
        try? context.save()
        SoundManager.shared.play(.levelUp, haptic: .success)
        dismiss()
    }
}
// MARK: - Чип расы
struct RaceChip: View {
    @Environment(\.theme) private var theme
    let race: Race
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: race.icon)
                    .font(.system(size: 12))
                
                Text(race.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? theme.primary : theme.surface)
            .foregroundColor(isSelected ? theme.background : theme.text)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? theme.primary : theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Чип класса
struct ClassChip: View {
    @Environment(\.theme) private var theme
    let characterClass: CharacterClass
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: characterClass.icon)
                    .font(.system(size: 12))
                
                Text(characterClass.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? theme.primary : theme.surface)
            .foregroundColor(isSelected ? theme.background : theme.text)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? theme.primary : theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout для автоматического переноса чипов
struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }
        
        let totalHeight = currentY + lineHeight
        return (positions, CGSize(width: totalWidth, height: totalHeight))
    }
}
