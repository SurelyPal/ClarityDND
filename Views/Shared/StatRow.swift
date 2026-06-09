//
//  StatRow.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//


//
//  StatRow.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct StatRow: View {
    let name: String
    let value: Int
    let isLast: Bool
    
    var modifier: Int {
        Constants.Stat.modifier(for: value)
    }

    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(Color.dsText)
            
            Spacer()
            
            Text("\(value)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.dsText)
                .frame(width: 30, alignment: .trailing)
            
            Text(Constants.Stat.formattedModifier(modifier))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.dsGold)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.dsBorder)
                    .frame(height: 0.5)
            }
        }
    }
}