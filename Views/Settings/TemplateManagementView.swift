//
//  TemplateManagementView.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//

import SwiftUI
import SwiftData

/// Экран управления шаблонами игр
struct TemplateManagementView: View {
    @Environment(\.modelContext) private var context
    @Query private var templates: [GameTemplate]
    
    @State private var showingAddTemplate = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    NavigationLink(destination: TemplateDetailView(template: template)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.headline)
                                Text(template.templateDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(template.fieldDefinitions.count) полей")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink {
                                    MechanicsListView(gameTemplate: template)
                                } label: {
                                    Label("Механики: \(template.name)", systemImage: "gearshape.2")
                                }
                }
                .onDelete(perform: deleteTemplates)
            }
            .navigationTitle("Шаблоны игр")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingAddTemplate = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplateView()
            }
        }
    }
    
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

// MARK: - Детальный вид шаблона
struct TemplateDetailView: View {
    @Bindable var template: GameTemplate
    @Environment(\.modelContext) private var context
    @State private var showingAddField = false
    
    var body: some View {
        List {
            Section("Информация") {
                LabeledContent("Название", value: template.name)
                LabeledContent("Описание", value: template.templateDescription)
                LabeledContent("Встроенный", value: template.isBuiltIn ? "Да" : "Нет")
            }
            
            Section("Поля") {
                ForEach(template.fieldDefinitions) { field in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(field.name)
                                .font(.headline)
                            Text("Ключ: \(field.key)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: field.fieldType.icon)
                            .foregroundColor(.blue)
                    }
                }
                .onDelete(perform: deleteFields)
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingAddField = true }) {
                    Image(systemName: "plus")
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

// MARK: - Добавление нового шаблона
struct AddTemplateView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var templateDescription = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например: Моя система", text: $name)
                }
                
                Section("Описание") {
                    TextField("Описание системы", text: $templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Новый шаблон")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        let template = GameTemplate(
                            name: name,
                            templateDescription: templateDescription,
                            isBuiltIn: false
                        )
                        context.insert(template)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Добавление нового поля
    struct AddFieldView: View {
        @Environment(\.modelContext) private var context
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
                Form {
                    Section("Идентификация") {
                        TextField("Название (например: Стресс)", text: $name)
                        TextField("Ключ (латиница, например: stress)", text: $key)
#if os(iOS)
    .textInputAutocapitalization(.never)
    #endif
    .autocorrectionDisabled(true)
                    }
                    
                    Section("Тип поля") {
                        Picker("Тип", selection: $fieldType) {
                            ForEach(FieldType.allCases) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                    }
                    
                    Section("Значение по умолчанию") {
                        TextField("0", text: $defaultValue)
                    }
                    
                    Section("Отображение") {
                        Toggle("Показывать в листе персонажа", isOn: $showOnSheet)
                        Toggle("Игрок может редактировать", isOn: $isEditableByPlayer)
                    }
                }
                .navigationTitle("Новое поле")
                // ✅ СТАЛО
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { dismiss() }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Добавить") {
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
                            dismiss()
                        }
                        .disabled(name.isEmpty || key.isEmpty)
                    }
                }
            }
        }
    }
}
// MARK: - Добавление нового поля
struct AddFieldView: View {
    @Environment(\.modelContext) private var context
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
            Form {
                Section("Идентификация") {
                    TextField("Название (например: Стресс)", text: $name)
                    TextField("Ключ (латиница, например: stress)", text: $key)
                            #if os(iOS)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled(true)
                }
                
                Section("Тип поля") {
                    Picker("Тип", selection: $fieldType) {
                        ForEach(FieldType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section("Значение по умолчанию") {
                    TextField("0", text: $defaultValue)
                }
                
                Section("Отображение") {
                    Toggle("Показывать в листе персонажа", isOn: $showOnSheet)
                    Toggle("Игрок может редактировать", isOn: $isEditableByPlayer)
                }
            }
            .navigationTitle("Новое поле")
            // ✅ СТАЛО
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
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
                        dismiss()
                    }
                    .disabled(name.isEmpty || key.isEmpty)
                }
            }
        }
    }
}
