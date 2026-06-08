//
//  RaceStepView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI

struct RaceStepView: View {
    @Binding var selected: Race
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                stepHeader
                
                DSdivider().padding(.bottom, 8)
                
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(Race.allCases) { race in
                        RaceCard(
                            icon: race.icon,
                            name: race.rawValue,
                            desc: race.shortDescription,
                            isSelected: selected == race
                        )
                        .onTapGesture { selected = race }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Шаг 1 из 4")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(Color.dsTextDim)
            Text("Выберите расу")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color.dsGold)
                .padding(.bottom, 8)
        }
    }
}
