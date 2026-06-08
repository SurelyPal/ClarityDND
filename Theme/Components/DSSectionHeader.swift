//
//  DSSectionHeader.swift
//  Clarity
//

import SwiftUI

struct DSSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            DSdivider()
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(2)
                .foregroundColor(Color.dsGoldDim)
            DSdivider()
        }
        .padding(.horizontal, 16)
    }
}
