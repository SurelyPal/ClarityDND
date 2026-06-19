import SwiftUI
import SwiftData

/// Экран со списком всех механик игрового шаблона
struct MechanicsListView: View {
    @Environment(\.modelContext) private var modelContext
    let gameTemplate: GameTemplate
    
    /// Отсортированный список механик для отображения
    private var sortedMechanics: [Mechanic] {
        gameTemplate.mechanics.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if gameTemplate.mechanics.isEmpty {
                    ContentUnavailableView(
                        "Нет механик",
                        systemImage: "gearshape.2",
                        description: Text("Создайте первую механику для автоматизации игровых процессов")
                    )
                } else {
                    List {
                        ForEach(sortedMechanics) { mechanic in
                            MechanicRow(
                                mechanic: mechanic,
                                onToggle: { toggleMechanic(mechanic) }
                            )
                        }
                        .onDelete(perform: deleteMechanics)
                    }
                }
            }
            .navigationTitle("Механики")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createMechanic) {
                        Label("Добавить механику", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    // MARK: - Действия
    
    /// Создать новую механику
    private func createMechanic() {
        let newMechanic = Mechanic(
            name: "Новая механика",
            trigger: .manual,
            gameTemplate: gameTemplate
        )
        
        gameTemplate.mechanics.append(newMechanic)
        modelContext.insert(newMechanic)
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при создании механики: \(error)")
        }
    }
    
    /// Удалить механики по индексам
    private func deleteMechanics(at offsets: IndexSet) {
        for index in offsets {
            let mechanic = sortedMechanics[index]
            gameTemplate.mechanics.removeAll { $0.id == mechanic.id }
            modelContext.delete(mechanic)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении механики: \(error)")
        }
    }
    
    /// Переключить активность механики
    private func toggleMechanic(_ mechanic: Mechanic) {
        mechanic.isEnabled.toggle()
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при переключении механики: \(error)")
        }
    }
}

/// Строка в списке механик
struct MechanicRow: View {
    let mechanic: Mechanic
    let onToggle: () -> Void
    
    var body: some View {
        NavigationLink {
            MechanicDetailView(mechanic: mechanic)
        } label: {
            HStack {
                // Иконка триггера
                Image(systemName: mechanic.trigger.iconName)
                    .foregroundStyle(mechanic.isEnabled ? .blue : .gray)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mechanic.name)
                        .font(.headline)
                        .foregroundStyle(mechanic.isEnabled ? .primary : .secondary)
                    
                    Text(mechanic.trigger.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Переключатель активности
                Toggle("", isOn: Binding(
                    get: { mechanic.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
        }
    }
}
/* #Preview {
    let container = try! ModelContainer(for: Mechanic.self, GameTemplate.self)
    let template = GameTemplate(
        name: "Test Template",
        templateDescription: "Тестовый шаблон для превью",
        isBuiltIn: false
    )
    container.mainContext.insert(template)
    
    MechanicsListView(gameTemplate: template)
        .modelContainer(container)
}
*/
