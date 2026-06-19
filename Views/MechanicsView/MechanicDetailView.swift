//
//  MechanicDetailView.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import SwiftUI
import SwiftData

/// Экран детального просмотра и редактирования механики
struct MechanicDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var mechanic: Mechanic
    @State private var showingAddAction = false
    
    var body: some View {
        Form {
            Section("Основное") {
                TextField("Название", text: $mechanic.name)
                
                Picker("Триггер", selection: $mechanic.trigger) {
                    ForEach(MechanicTrigger.allCases) { trigger in
                        Text(trigger.displayName).tag(trigger)
                    }
                }
                
                Toggle("Активна", isOn: $mechanic.isEnabled)
            }
            
            Section("Действия") {
                if mechanic.actions.isEmpty {
                    ContentUnavailableView(
                        "Нет действий",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Добавьте первое действие")
                    )
                    .frame(height: 100)
                } else {
                    ForEach(mechanic.sortedActions) { action in
                        ActionRow(action: action)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let action = mechanic.sortedActions[index]
                            mechanic.removeAction(id: action.id)
                            modelContext.delete(action)
                        }
                    }
                    .onMove { indexSet, newIndex in
                        // Получаем индексы в отсортированном массиве
                        let sorted = mechanic.sortedActions
                        for oldIndex in indexSet {
                            mechanic.moveAction(from: oldIndex, to: newIndex)
                        }
                    }
                }
                
                Button {
                    showingAddAction = true
                } label: {
                    Label("Добавить действие", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(mechanic.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddAction) {
            AddActionSheet(mechanic: mechanic)
        }
        .onChange(of: mechanic.name) { _, _ in
            saveMechanic()
        }
        .onChange(of: mechanic.trigger) { _, _ in
            saveMechanic()
        }
        .onChange(of: mechanic.isEnabled) { _, _ in
            saveMechanic()
        }
    }
    
    private func saveMechanic() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
}

/// Строка в списке действий
struct ActionRow: View {
    let action: Action
    
    var body: some View {
        HStack {
            Image(systemName: action.type.iconName)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.type.displayName)
                    .font(.headline)
                
                Text(getActionDescription())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
    }
    
    private func getActionDescription() -> String {
        switch action.type {
        case .setField:
            if let params = try? JSONDecoder().decode(SetFieldParameters.self, from: action.parameters) {
                return "Установить \(params.fieldKey) = \(params.value)"
            }
        case .incrementField:
            if let params = try? JSONDecoder().decode(IncrementFieldParameters.self, from: action.parameters) {
                return "Увеличить \(params.fieldKey) на \(params.amount)"
            }
        case .decrementField:
            if let params = try? JSONDecoder().decode(DecrementFieldParameters.self, from: action.parameters) {
                return "Уменьшить \(params.fieldKey) на \(params.amount)"
            }
        case .rollDice:
            if let params = try? JSONDecoder().decode(RollDiceParameters.self, from: action.parameters) {
                return "Бросить \(params.diceCount)d\(params.diceSides)+\(params.modifier)"
            }
        case .showMessage:
            if let params = try? JSONDecoder().decode(ShowMessageParameters.self, from: action.parameters) {
                return params.message
            }
        }
        return "Не настроено"
    }
}

#Preview {
    let container = try! ModelContainer(for: Mechanic.self, Action.self)
    let mechanic = Mechanic(name: "Тестовая механика")
    container.mainContext.insert(mechanic)
    
    return NavigationStack {
        MechanicDetailView(mechanic: mechanic)
    }
    .modelContainer(container)
}