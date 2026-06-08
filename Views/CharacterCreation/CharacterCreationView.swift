//
//  CharacterCreationView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct CharacterCreationView: View {
    @EnvironmentObject var store: CharacterStore
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var character = DNDCharacter()
    
    private let totalSteps = 4
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        backButton
                    }
                }
                
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
            .background(Color.dsGold)
            .foregroundColor(Color.dsBackground)
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
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.dsGold : Color.dsSurfaceAlt)
                    .frame(height: 2)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}
