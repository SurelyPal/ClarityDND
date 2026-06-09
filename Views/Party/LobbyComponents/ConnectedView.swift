//
//  ConnectedView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct ConnectedView: View {
    @ObservedObject var partyManager: PartyManager

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("ПАРТИЯ (\(partyManager.partyMembers.count))")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
            }

            VStack(spacing: 4) {
                ForEach(partyManager.partyMembers) { member in
                    PartyMemberRow(member: member)
                        .padding(.vertical, 2)
                }
            }
            .background(Color.dsSurfaceAlt)
            .cornerRadius(6)

            Button {
                PlatformCompatibility.hapticNotification(.warning)
                partyManager.leaveRoom()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                    Text("Покинуть партию")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.dsRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dsSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.dsRed.opacity(0.4), lineWidth: 1)
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - SkeletonLoader для списка персонажей

struct SkeletonCharacterRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.dsSurfaceAlt)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dsSurfaceAlt)
                    .frame(width: 120, height: 12)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dsSurfaceAlt)
                    .frame(width: 180, height: 10)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.dsSurfaceAlt.opacity(0.5))
        .cornerRadius(6)
    }
}