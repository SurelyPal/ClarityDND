//
//  CornerOrnaments.swift
//  Clarity.app
//

import SwiftUI

struct CornerOrnaments: View {
    var size: CGFloat = 12
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    ornament
                    Spacer()
                    ornament.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                Spacer()
                HStack {
                    ornament.rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                    Spacer()
                    ornament.rotation3DEffect(.degrees(180), axis: (x: 1, y: 1, z: 0))
                }
            }
            .padding(6)
        }
    }
    
    private var ornament: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: size * 0.4))
            .foregroundColor(Color.dsGoldDim)
    }
}

