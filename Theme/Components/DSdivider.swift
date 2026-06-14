//
//  DSdivider.swift
//  Clarity
//

import SwiftUI

struct DSdivider: View {
    @Environment(\.theme) private var theme
    var body: some View {
        HStack(spacing: 6) {
            line
            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
                .foregroundColor(theme.primaryDim)
            line
        }
        .padding(.vertical, 2)
    }
    
    private var line: some View {
        Rectangle()
            .fill(theme.border)
            .frame(height: 0.5)
    }
}
