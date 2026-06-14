//
//  CharacterCreationView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct CharacterCreationView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var store: CharacterStore
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var character: DNDCharacter = DNDCharacter()
    
    private let totalSteps = 4
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    StepProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    
                    Group {
                        switch currentStep {
                        case 0: RaceStepView(selected: $character.race)
                        case 1: ClassStepView(selected: $character.characterClass)
                        case 2: StatsStepView(stats: $character.stats)
                        case 3: NameStepView(character: $character)
                        default: EmptyView()
                        }
                    }
                    
                    Spacer()
                    
                    nextButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
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
            .background(theme.primary)
            .foregroundColor(theme.background)
            .font(.system(size: 16, weight: .medium))
            .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }
    
    private func advance() {
        if currentStep < totalSteps - 1 {
            withAnimation { currentStep += 1 }
            SoundManager.shared.play(.pageTurn, haptic: .light)
        } else {
            store.add(character)
            dismiss()
            SoundManager.shared.play(.levelUp, haptic: .success)
        }
    }
}

// MARK: - Прогресс-бар

struct StepProgressBar: View {
    @Environment(\.theme) private var theme
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentStep ? theme.primary : theme.surfaceAlt)
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Preview
/*
#Preview {
    // Создаём тестовый SwiftData контейнер в памяти (in-memory)
    // Данные не сохраняются между запусками Preview
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DNDCharacter.self, configurations: config)
    let context = container.mainContext
    
    // Создаём CharacterStore, передавая ему контекст
    let store = CharacterStore(context: context)
    
    return CharacterCreationView()
        .environmentObject(store)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
*/
