//
//  AddActionSheet.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import SwiftUI
import SwiftData

/// Модальное окно для выбора типа действия
struct AddActionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mechanic: Mechanic
    
    var body: some View {
        NavigationStack {
            List {
                Section("Выберите тип действия") {
                    ForEach(ActionType.allCases) { actionType in
                        Button {
                            addAction(ofType: actionType)
                        } label: {
                            HStack {
                                Image(systemName: actionType.iconName)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(actionType.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(actionType.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Добавить действие")
            // ✅ СТАЛО
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addAction(ofType type: ActionType) {
        // Создаём действие с пустыми параметрами
        let action = Action(
            mechanic: mechanic,
            order: mechanic.actions.count,
            type: type,
            parameters: Data()
        )
        
        mechanic.actions.append(action)
        modelContext.insert(action)
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при добавлении действия: \(error)")
        }
        
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: Mechanic.self, Action.self)
    let mechanic = Mechanic(name: "Тестовая механика")
    container.mainContext.insert(mechanic)
    
    return AddActionSheet(mechanic: mechanic)
        .modelContainer(container)
}
