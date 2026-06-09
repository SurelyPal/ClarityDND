//
//  RuleToggle.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct RuleToggle: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color.dsGold)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.dsText)
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsTextDim)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.dsGold)
        }
        .padding(.vertical, 6)
    }
}
