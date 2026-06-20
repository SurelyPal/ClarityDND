import SwiftUI
import SwiftData

struct CharacterCreationView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var store: CharacterStore
    @Environment(\.dismiss) var dismiss
    
    // 🆕 НОВОЕ: Загружаем все шаблоны из SwiftData
    @Query(sort: \GameTemplate.name) private var allTemplates: [GameTemplate]
    
    @State private var currentStep = 0
    @State private var character: DNDCharacter = DNDCharacter()
    @State private var selectedTemplate: GameTemplate? // 🆕 НОВОЕ
    
    private let totalSteps = 5 // 🆕 ИЗМЕНЕНО: было 4, стало 5

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    StepProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(EdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20))

                    Group {
                        switch currentStep {
                        case 0:
                            TemplateSelectionStepView(
                                selectedTemplate: $selectedTemplate,
                                templates: allTemplates
                            )
                        case 1:
                            RaceStepView(
                                selected: $character.race,
                                template: selectedTemplate // 🆕 НОВОЕ
                            )
                        case 2:
                            ClassStepView(
                                selected: $character.characterClass,
                                template: selectedTemplate // 🆕 НОВОЕ
                            )
                        case 3:
                            StatsStepView(stats: $character.stats)
                        case 4:
                            NameStepView(character: $character)
                        default:
                            EmptyView()
                        }
                    }

                    Spacer()

                    nextButton
                        .padding(EdgeInsets(top: 0, leading: 20, bottom: 30, trailing: 20))
                }
                .navigationTitle("Новый персонаж")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        backButton
                    }
                }
                #elseif os(macOS)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        backButton
                    }
                }
                #endif
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Кнопки навигации

    private var backButton: some View {
        Button(currentStep == 0 ? "Отмена" : "Назад") {
            if currentStep == 0 {
                dismiss()
            } else {
                withAnimation { currentStep -= 1 }
                SoundManager.shared.play(.pageTurn)
            }
        }
    }

    private var nextButton: some View {
        Button(action: advance) {
            HStack {
                Text(currentStep < totalSteps - 1 ? "Далее" : "Записать в книгу")
                Image(systemName: currentStep < totalSteps - 1 ? "arrow.right" : "checkmark")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(canProceed ? theme.primary : theme.primary.opacity(0.3))
            .foregroundColor(theme.background)
            .font(.system(size: 16, weight: .medium))
            .cornerRadius(3)
        }
        .buttonStyle(.plain)
        .disabled(!canProceed)
    }
    
    // 🆕 НОВОЕ: Проверяем, можно ли перейти к следующему шагу
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return selectedTemplate != nil
        default:
            return true
        }
    }

    private func advance() {
        if currentStep < totalSteps - 1 {
            withAnimation { currentStep += 1 }
            SoundManager.shared.play(.pageTurn, haptic: .light)
        } else {
            // 🆕 НОВОЕ: Устанавливаем templateID перед сохранением
            character.templateID = selectedTemplate?.id
            
            store.add(character)
            dismiss()
            SoundManager.shared.play(.levelUp, haptic: .success)
        }
    }
}
