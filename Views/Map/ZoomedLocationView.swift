//
//  ZoomedLocationView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct ZoomedLocationView: View {
    let location: MapLocation
    let onClose: () -> Void
    
    // Жесты для зума и перетаскивания
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.dsBackground.opacity(0.95).ignoresSafeArea()
            
            // Увеличенная карта
            GeometryReader { geo in
                Image("worldMap")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(scale * 3) // Базовое увеличение в 3 раза
                    .offset(x: initialOffset(for: geo.size).width + offset.width,
                            y: initialOffset(for: geo.size).height + offset.height)
                    .gesture(
                        // Зум двумя пальцами
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation { scale = 1; lastScale = 1 }
                                }
                            }
                    )
                    .simultaneousGesture(
                        // Перетаскивание
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
            }
            .clipped()
            
            // Верхняя панель с названием
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: location.icon)
                        .foregroundColor(Color.dsGold)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name.uppercased())
                            .font(.system(size: 16, weight: .medium))
                            .tracking(2)
                            .foregroundColor(Color.dsGold)
                        
                        Text(location.description)
                            .font(.system(size: 12))
                            .foregroundColor(Color.dsTextDim)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.dsGold)
                    }
                }
                .padding(16)
                .background(Color.dsSurface.opacity(0.95))
                .overlay(
                    Rectangle()
                        .fill(Color.dsBorder)
                        .frame(height: 0.5),
                    alignment: .bottom
                )
                
                Spacer()
                
                // Подсказка снизу
                Text("Сожмите пальцы чтобы увеличить • Перетащите чтобы посмотреть вокруг")
                    .font(.system(size: 11))
                    .tracking(1)
                    .foregroundColor(Color.dsTextDim)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.dsSurface.opacity(0.8))
                    .cornerRadius(3)
                    .padding(.bottom, 30)
            }
        }
        .transition(.opacity)
    }
    
    // Смещаем карту так, чтобы выбранная точка оказалась по центру
    private func initialOffset(for size: CGSize) -> CGSize {
        let offsetX = size.width * (0.5 - location.xPercent / 100) * 3
        let offsetY = size.height * (0.5 - location.yPercent / 100) * 3
        return CGSize(width: offsetX, height: offsetY)
    }
}
