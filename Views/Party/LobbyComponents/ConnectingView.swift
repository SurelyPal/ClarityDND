//
//  ConnectingView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct ConnectingView: View {
    let peerName: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.dsGold)
                .scaleEffect(1.3)
                .padding(.vertical, 20)

            VStack(spacing: 8) {
                Text("ПОДКЛЮЧЕНИЕ")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Color.dsGold)

                Text("Соединение с \(peerName)...")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
            }
        }
    }
}
