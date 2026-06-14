//
//  PartyLobbyView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct PartyLobbyView: View {
    @Environment(\.theme) private var theme
    @ObservedObject private var partyManager = PartyManager.shared
    @EnvironmentObject var store: CharacterStore

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    currentFlowView
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Лобби партии")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
    }
    

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("CLARITY")
                .font(.system(size: 28, weight: .thin))
                .tracking(6)
                .foregroundColor(theme.primary)

            DSdivider().padding(.horizontal, 40)

            Text("МУЛЬТИПЛЕЕР")
                .font(.system(size: 10))
                .tracking(3)
                .foregroundColor(theme.textDim)
        }
    }

    // MARK: - Switch по состоянию подключения

    @ViewBuilder
    private var currentFlowView: some View {
        switch partyManager.connectionState {
        case .disconnected:
            
            RoleSelectionView(partyManager: partyManager)

        case .selectingCharacter:
            PlayerFlowView(partyManager: partyManager)
                .environmentObject(store)

        case .configuringRules:
            RulesConfigurationView(partyManager: partyManager)

        case .hosting(let code):
            HostingView(partyManager: partyManager, roomCode: code)

        case .searching:
            SearchingView(partyManager: partyManager)

        case .connecting(let peerName):
            ConnectingView(peerName: peerName)

        case .connected:
            ConnectedView(partyManager: partyManager)
        }
    }
}
