//
//  DSSectionHeader.swift
//  Clarity
//

import SwiftUI

struct DSSectionHeader: View {
    @Environment(\.theme) private var theme
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            DSdivider()
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(theme.primaryDim)
            DSdivider()
        }
        .padding(.horizontal, 16)
    }
}
