//
//  DSdivider.swift
//  Clarity
//

import SwiftUI

struct DSdivider: View {
    var body: some View {
        HStack(spacing: 6) {
            line
            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
                .foregroundColor(Color.dsGoldDim)
            line
        }
        .padding(.vertical, 2)
    }
    
    private var line: some View {
        Rectangle()
            .fill(Color.dsBorder)
            .frame(height: 0.5)
    }
}
