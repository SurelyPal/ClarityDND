//
//  ClassStepView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct ClassStepView: View {
    @Binding var selected: CharacterClass
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                stepHeader
                
                DSdivider().padding(.bottom, 8)
                
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(CharacterClass.allCases) { cls in
                        RaceCard(
                            icon: cls.icon,
                            name: cls.rawValue,
                            desc: cls.shortDescription,
                            isSelected: selected == cls
                        )
                        .onTapGesture { selected = cls }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Шаг 2 из 4")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(Color.dsTextDim)
            Text("Выберите класс")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color.dsGold)
                .padding(.bottom, 8)
        }
    }
}

