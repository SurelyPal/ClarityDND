//
//  AvatarView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import SwiftUI

struct AvatarView: View {
    let avatarData: Data?
    let race: Race
    var size: CGFloat = 90
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.dsSurface)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.dsBorderBright, lineWidth: 1)
                )
            
            if let data = avatarData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 8, height: size - 8)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                // ✅ SF Symbol вместо emoji
                Image(systemName: race.icon)
                    .font(.system(size: size * 0.45))
                    .foregroundColor(Color.dsGold)
            }
            
            CornerOrnaments(size: size * 0.22)
                .frame(width: size, height: size)
        }
    }
}

