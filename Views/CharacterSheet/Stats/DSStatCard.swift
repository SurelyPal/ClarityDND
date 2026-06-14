//
//  DSStatCard.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct DSStatCard: View {
    @Environment(\.theme) private var theme
    let short: String
    let value: Int
    
    // ✅ БЫЛО: (value - 10) / 2 → СТАЛО: использует Constants
    private var modifier: Int { Constants.Stat.modifier(for: value) }
    private var modText: String { Constants.Stat.formattedModifier(modifier) }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(modText)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(theme.primary)
            Text("\(value)")
                .font(.system(size: 12))
                .foregroundColor(theme.textDim)
            DSdivider()
            Text(short)
                .font(.system(size: 9, weight: .medium))
                .tracking(2)
                .foregroundColor(theme.textDim)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .dsCard()
    }
}

