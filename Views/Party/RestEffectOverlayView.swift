//
//  RestEffectOverlayView.swift
//  Clarity
//
//  Created by SurelyPal on 07.06.2026.
//

import SwiftUI

#if os(macOS)
import AppKit
#endif

struct RestEffectOverlayView: View {
    let effect: PartyManager.RestEffectEvent
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var particles: [Particle] = []
    @State private var glowPulse: Double = 0.6
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var targetY: CGFloat
        var rotation: Double
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Затемнённый фон
                Color.black.opacity(showContent ? 0.75 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: showContent)
                
                // 🌟 Пульсирующее свечение (цвет зависит от типа отдыха)
                if showContent {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    effectColor.opacity(glowPulse * 0.6),
                                    effectColor.opacity(glowPulse * 0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 300
                            )
                        )
                        .frame(width: 500, height: 500)
                        .blur(radius: 40)
                        .allowsHitTesting(false)
                }
                
                // ✨ Летающие частицы исцеления
                ForEach(particles) { particle in
                    Image(systemName: effect.restType == .short ? "sparkle" : "moon.stars.fill")
                        .font(.system(size: particle.size))
                        .foregroundColor(effectColor)
                        .opacity(particle.opacity)
                        .position(x: particle.x, y: particle.y)
                        .rotationEffect(.degrees(particle.rotation))
                        .allowsHitTesting(false)
                }
                
                // 🎯 Центральная карточка
                if showContent {
                    VStack(spacing: 20) {
                        // Иконка отдыха
                        Image(systemName: effect.restType.icon)
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(effectColor)
                            .shadow(color: effectColor.opacity(0.8), radius: 20)
                        
                        VStack(spacing: 8) {
                            Text(effect.restType.displayName.uppercased())
                                .font(.system(size: 10))
                                .tracking(4)
                                .foregroundColor(Color.dsTextDim)
                            
                            Text("Отдых начался")
                                .font(.system(size: 26, weight: .light))
                                .tracking(2)
                                .foregroundColor(effectColor)
                        }
                        
                        DSdivider()
                            .padding(.horizontal, 40)
                        
                        // Что восстановилось
                        VStack(spacing: 10) {
                            if effect.restType == .short {
                                EffectRow(icon: "heart.fill", text: "+25% HP", color: .dsRed)
                                EffectRow(icon: "wind", text: "-1 Стресс", color: .dsBlue)
                            } else {
                                EffectRow(icon: "heart.fill", text: "HP = максимум", color: .dsRed)
                                EffectRow(icon: "wind", text: "Стресс = 0", color: .dsBlue)
                                EffectRow(icon: "arrow.clockwise", text: "Перебросы = максимум", color: .dsGold)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(30)
                    .frame(maxWidth: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dsSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(effectColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: effectColor.opacity(glowPulse * 0.6), radius: 30)
                    .shadow(color: effectColor.opacity(glowPulse * 0.3), radius: 60)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .padding(.horizontal, 20)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5)) {
                    showContent = true
                }
                // ✅ ИСПРАВЛЕНО: используем размеры из GeometryReader вместо UIScreen
                generateParticles(centerX: proxy.size.width / 2, centerY: proxy.size.height / 2)
                startGlowPulse()
                
                // Автозакрытие через 3.5 секунды
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private var effectColor: Color {
        switch effect.restType {
        case .short: return .green
        case .long: return Color.dsGold
        }
    }
    
    // ✅ ИСПРАВЛЕНО: теперь принимает centerX и centerY как параметры
    private func generateParticles(centerX: CGFloat, centerY: CGFloat) {
        for i in 0..<25 {
            let angle = Double(i) * 14.4  // 360/25
            let radians = angle * .pi / 180
            let radius: CGFloat = 100
            let startX = centerX + CGFloat(cos(radians)) * radius
            let startY = centerY + CGFloat(sin(radians)) * radius
            
            let particle = Particle(
                x: startX,
                y: startY,
                size: CGFloat.random(in: 10...22),
                opacity: 1.0,
                targetY: startY - CGFloat.random(in: 150...300),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
        // Анимируем разлёт
        for i in 0..<particles.count {
            withAnimation(.easeOut(duration: 2.5).delay(Double(i) * 0.03)) {
                particles[i].y = particles[i].targetY
                particles[i].opacity = 0
                particles[i].rotation += 180
            }
        }
    }
    
    private func startGlowPulse() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowPulse = 1.0
        }
    }
}

// MARK: - Вспомогательный компонент
private struct EffectRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.dsText)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        RestEffectOverlayView(
            effect: PartyManager.RestEffectEvent(
                restType: .long,
                initiatorName: "Валериан",
                timestamp: Date()
            ),
            onDismiss: { }
        )
    }
    .preferredColorScheme(.dark)
}
