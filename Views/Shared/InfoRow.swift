//
//  InfoRow.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct InfoRow: View {
    @Environment(\.theme) private var theme
    let icon: String
    let label: String
    let value: String
    let isLast: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(theme.primaryDim)
                .font(.system(size: 12))
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(theme.text)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 0.5)
            }
        }
    }
}
