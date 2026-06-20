//
//  StepProgressBar.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//

import SwiftUI

struct StepProgressBar: View {
    @Environment(\.theme) private var theme
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                // Точка прогресса
                Circle()
                    .fill(index <= currentStep ? theme.primary : theme.border)
                    .frame(width: 12, height: 12)
                
                // Линия между точками (кроме последней)
                if index < totalSteps - 1 {
                    Rectangle()
                        .fill(index < currentStep ? theme.primary : theme.border)
                        .frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StepProgressBar(currentStep: 2, totalSteps: 5)
        .padding()
}
