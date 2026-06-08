//
//  SkeletonLoader.swift
//  Clarity
//
//  Created by KEBAB on 08.06.2026.
//

import SwiftUI

/// Универсальный skeleton loader с пульсирующей анимацией в стиле Dark Souls
struct SkeletonLoader: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 4
    
    @State private var animate = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.dsSurface)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.dsGold.opacity(0.1), lineWidth: 1)
            )
            .opacity(animate ? 0.4 : 0.7)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate = true
            }
    }
}

/// Skeleton для круга (аватар)
struct SkeletonCircle: View {
    var size: CGFloat = 48
    
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(Color.dsSurface)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.dsGold.opacity(0.1), lineWidth: 1)
            )
            .opacity(animate ? 0.4 : 0.7)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        SkeletonLoader(width: 200, height: 16)
        SkeletonLoader(width: 150, height: 16)
        SkeletonLoader(height: 40)
        SkeletonCircle(size: 60)
    }
    .padding()
    .background(Color.dsBackground)
    .preferredColorScheme(.dark)
}
