//
//  InfoRow.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let isLast: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.dsGoldDim)
                .font(.system(size: 12))
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.dsText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.dsGold)
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
