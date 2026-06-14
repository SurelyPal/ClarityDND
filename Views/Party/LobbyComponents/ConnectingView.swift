//
//  ConnectingView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct ConnectingView: View {
    @Environment(\.theme) private var theme
    let peerName: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(theme.primary)
                .scaleEffect(1.3)
                .padding(.vertical, 20)

            VStack(spacing: 8) {
                Text("ПОДКЛЮЧЕНИЕ")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(theme.primary)

                Text("Соединение с \(peerName)...")
                    .font(.system(size: 11))
                    .foregroundColor(theme.textDim)
            }
        }
    }
}
