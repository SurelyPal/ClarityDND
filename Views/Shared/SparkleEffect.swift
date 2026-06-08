//
//  SparkleEffect.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

/// Генерирует летящие золотые частицы (искры/звёзды)
struct SparkleEffect: View {
    @State private var particles: [Particle] = []
    let trigger: Bool
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var angle: Double
        var speed: Double
        var rotation: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "sparkle")
                    .font(.system(size: particle.size))
                    .foregroundColor(Color.dsGold)
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onChange(of: trigger) { _, newValue in
            if newValue {
                generateParticles()
            }
        }
    }
    
    private func generateParticles() {
        particles = []
        
        // Создаём 20 частиц
        for i in 0..<20 {
            let particle = Particle(
                x: UIScreen.main.bounds.width / 3,
                y: UIScreen.main.bounds.height / 3,
                size: CGFloat.random(in: 8...24),
                opacity: 2.0,
                angle: Double(i) * 18.0, // 360/20 = 18 градусов
                speed: Double.random(in: 80...150),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
        // Анимируем каждую частицу
        for i in 0..<particles.count {
            let particle = particles[i]
            let radians = particle.angle * .pi / 180
            let targetX = particle.x + CGFloat(cos(radians) * particle.speed)
            let targetY = particle.y + CGFloat(sin(radians) * particle.speed)
            
            withAnimation(.easeOut(duration: 1.2)) {
                particles[i].x = targetX
                particles[i].y = targetY
                particles[i].opacity = 0
                particles[i].rotation += 360
            }
        }
        
        // Очищаем частицы после анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            particles = []
        }
    }
}
