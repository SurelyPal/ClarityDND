//
//  RoleSelectionView.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//


//
//  RoleSelectionView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var partyManager: PartyManager
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                partyManager.startHosting()
            } label: {
                VStack(spacing: 12) {
                    Text("👑").font(.system(size: 40))
                    Text("МАСТЕР ПАРТИИ")
                        .font(.system(size: 14, weight: .semibold)).tracking(1.5)
                        .foregroundColor(Color.dsGold)
                    Text("Создать комнату и видеть всех игроков в реальном времени")
                        .font(.system(size: 11))
                        .foregroundColor(Color.dsTextDim)
                        .multilineTextAlignment(.center)
                }
                .padding(20).frame(maxWidth: .infinity)
                .background(Color.dsSurface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dsGold, lineWidth: 1.5))
                .cornerRadius(8)
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