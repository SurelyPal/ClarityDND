//
//  RoleSelectionView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var partyManager: PartyManager
    
    var body: some View {
        VStack(spacing: 16) {
            NavigationLink {
                CampaignSelectionView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 16))
                    
                    Text("ВЫБРАТЬ КАМПАНИЮ")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                }
                .foregroundColor(.dsBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dsGold)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            
            Button {
                partyManager.beginPlayerFlow()
            } label: {
                VStack(spacing: 12) {
                    Text("🗡️").font(.system(size: 40))
                    Text("ИГРОК")
                        .font(.system(size: 14, weight: .semibold)).tracking(1.5)
                        .foregroundColor(Color.dsText)
                    Text("Выбрать персонажа и подключиться к Мастеру")
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsTextDim)
                        .multilineTextAlignment(.center)
                }
                .padding(20).frame(maxWidth: .infinity)
                .background(Color.dsSurfaceAlt)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsBorder, lineWidth: 1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}
