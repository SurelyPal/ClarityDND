//
//  SparkleEffect.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

/// Эффект мерцающих звёздочек, появляющихся в случайных местах экрана.
/// Используется для визуального акцента при важных событиях (level up, достижение).
struct SparkleEffect: View {
    
    // MARK: - Параметры
    
    /// Количество одновременно видимых звёздочек
    let sparkleCount: Int
    
    /// Длительность жизни одной звёздочки (секунды)
    let lifetime: Double
    
    /// Цвет звёздочек
    let color: Color
    
    /// 🆕 Триггер для запуска эффекта (используется извне)
    let trigger: Bool
    
    // MARK: - Состояние
    
    @State private var sparkles: [Sparkle] = []
    
    /// Модель одной звёздочки
    struct Sparkle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
    }
    
    // MARK: - Инициализаторы
    
    init(sparkleCount: Int = 15, lifetime: Double = 2.0, color: Color = .dsGold, trigger: Bool = false) {
        self.sparkleCount = sparkleCount
        self.lifetime = lifetime
        self.color = color
        self.trigger = trigger
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                        .scaleEffect(sparkle.scale)
                        .opacity(sparkle.opacity)
                        .rotationEffect(.degrees(sparkle.rotation))
                        .position(x: sparkle.x, y: sparkle.y)
                        .shadow(color: color.opacity(sparkle.opacity * 0.6), radius: 4)
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                startSparkling(in: proxy.size)
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    sparkles.removeAll()
                    startSparkling(in: proxy.size)
                }
            }
            .onChange(of: proxy.size) { _, newSize in
                sparkles.removeAll()
                startSparkling(in: newSize)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Генерация эффекта
    
    private func startSparkling(in containerSize: CGSize) {
        guard containerSize.width > 0 && containerSize.height > 0 else { return }
        
        for i in 0..<sparkleCount {
            let delay = Double(i) * (lifetime / Double(sparkleCount * 2))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                spawnSparkle(in: containerSize)
            }
        }
    }
    
    private func spawnSparkle(in containerSize: CGSize) {
        let sparkle = Sparkle(
            x: CGFloat.random(in: 20...max(20, containerSize.width - 20)),
            y: CGFloat.random(in: 20...max(20, containerSize.height - 20)),
            scale: 0.1,
            opacity: 0,
            rotation: Double.random(in: 0...360)
        )
        
        let sparkleID = sparkle.id
        sparkles.append(sparkle)
        
        // ✅ ИСПРАВЛЕНО: Анимация появления — ищем по ID, не по индексу
        withAnimation(.easeOut(duration: lifetime * 0.3)) {
            if let currentIndex = sparkles.firstIndex(where: { $0.id == sparkleID }) {
                sparkles[currentIndex].opacity = 1.0
                sparkles[currentIndex].scale = CGFloat.random(in: 0.6...1.4)
                sparkles[currentIndex].rotation += 180
            }
        }
        
        // ✅ ИСПРАВЛЕНО: Анимация исчезновения — ищем по ID заново
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime * 0.3) {
            withAnimation(.easeIn(duration: lifetime * 0.7)) {
                if let currentIndex = sparkles.firstIndex(where: { $0.id == sparkleID }) {
                    sparkles[currentIndex].opacity = 0
                    sparkles[currentIndex].scale = 0.1
                    sparkles[currentIndex].rotation += 180
                }
            }
            
            // ✅ ИСПРАВЛЕНО: Удаление — ищем по ID заново
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime * 0.7) {
                sparkles.removeAll { $0.id == sparkleID }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        SparkleEffect(sparkleCount: 20, lifetime: 2.5, color: .dsGold)
    }
    .frame(width: 400, height: 600)
    .preferredColorScheme(.dark)
}
