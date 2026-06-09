//
//  DemotionPopupView.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//

import SwiftUI

struct DemotionPopupView: View {
    let currentLevel: Int
    let rewards: [MilestoneReward]
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    // MARK: - Состояния анимации
    @State private var showPopup = false
    @State private var showRewards = false
    @State private var showButtons = false
    @State private var sparkleTrigger = false
    @State private var levelScale: CGFloat = 0.5
    @State private var levelOpacity: Double = 0
    
    // MARK: - Состояния свечения
    @State private var glowIntensity: Double = 0.6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 🌑 ЗАТЕМНЁННЫЙ ФОН
                Color.black.opacity(showPopup ? 0.85 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: showPopup)
                
                // 💥 КРАСНЫЕ ИСКРЫ (тёмная версия)
                DarkSparkleEffect(trigger: sparkleTrigger)
                    .allowsHitTesting(false)
                
                // 🎭 САМА КАРТОЧКА POPUP
                if showPopup {
                    VStack(spacing: 0) {
                        // ─── Заголовок ───
                        VStack(spacing: 8) {
                            Text("ОТКАТ ВЕХИ")
                                .font(.system(size: 10))
                                .tracking(3)
                                .foregroundColor(Color.dsRed.opacity(0.8))
                                .opacity(showPopup ? 1 : 0)
                            
                            // Анимированные числа уровня со стрелкой
                            HStack(spacing: 16) {
                                // Старый уровень (исчезает)
                                Text("\(currentLevel)")
                                    .font(.system(size: 32, weight: .light))
                                    .tracking(2)
                                    .foregroundColor(Color.dsTextDim)
                                    .strikethrough(true, color: Color.dsRed)
                                
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundColor(Color.dsRed)
                                
                                // Новый уровень (появляется)
                                ZStack {
                                    Text("\(currentLevel - 1)")
                                        .font(.system(size: 32, weight: .light))
                                        .tracking(2)
                                        .foregroundColor(Color.dsRed)
                                        .blur(radius: 15)
                                        .opacity(levelOpacity * 0.6)
                                    
                                    Text("\(currentLevel - 1)")
                                        .font(.system(size: 32, weight: .light))
                                        .tracking(2)
                                        .foregroundColor(Color.dsRed)
                                        .scaleEffect(levelScale)
                                        .opacity(levelOpacity)
                                }
                            }
                            
                            DSdivider()
                                .padding(.horizontal, 20)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.dsSurface)
                        .overlay(
                            CornerOrnaments(size: 16)
                        )
                        
                        Rectangle()
                            .fill(Color.dsRed.opacity(0.3))
                            .frame(height: 0.5)
                        
                        // ─── Список отзываемых наград ───
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(Array(rewards.enumerated()), id: \.element.id) { index, reward in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: reward.icon)
                                            .font(.system(size: 16))
                                            .foregroundColor(Color.dsRed.opacity(0.7))
                                            .frame(width: 28)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(reward.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(Color.dsText)
                                                .strikethrough(true, color: Color.dsRed.opacity(0.7))
                                            
                                            Text(reward.description)
                                                .font(.system(size: 11))
                                                .foregroundColor(Color.dsTextDim)
                                                .strikethrough(true, color: Color.dsRed.opacity(0.4))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color.dsRed.opacity(0.7))
                                            .padding(.top, 2)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .opacity(showRewards ? 1 : 0)
                                    .offset(x: showRewards ? 0 : -30)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(0.3 + Double(index) * 0.15),
                                        value: showRewards
                                    )
                                    .overlay(alignment: .bottom) {
                                        if index < rewards.count - 1 {
                                            Rectangle()
                                                .fill(Color.dsBorder)
                                                .frame(height: 0.5)
                                        }
                                    }
                                }
                                
                                // Предупреждение о HP
                                HStack(spacing: 10) {
                                    Image(systemName: "heart.slash.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.dsRed)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Максимум HP уменьшится на 5")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color.dsRed.opacity(0.9))
                                        
                                        Text("Текущее здоровье будет ограничено новым максимумом")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.dsTextDim)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.dsRed.opacity(0.08))
                                .opacity(showRewards ? 1 : 0)
                                .animation(
                                    .easeInOut(duration: 0.4)
                                    .delay(0.3 + Double(rewards.count) * 0.15),
                                    value: showRewards
                                )
                            }
                        }
                        .background(Color.dsSurfaceAlt)
                        
                        // ─── Кнопки действий ───
                        // ─── Кнопки действий ───
                        HStack(spacing: 0) {
                            Button(action: cancelAction) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12))
                                    Text("Отмена")
                                        .font(.system(size: 14, weight: .medium))
                                        .tracking(0.5)
                                }
                                .foregroundColor(Color.dsText)
                                .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Добавлено maxHeight
                                .padding(.vertical, 18) // ✅ Увеличено с 16 до 18
                                .background(Color.dsSurface)
                            }
                            .frame(maxWidth: .infinity) // ✅ Добавлено на Button
                            
                            Rectangle()
                                .fill(Color.dsBorder)
                                .frame(width: 0.5)
                            
                            Button(action: confirmAction) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Откатить")
                                        .font(.system(size: 14, weight: .medium))
                                        .tracking(0.5)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Добавлено maxHeight
                                .padding(.vertical, 18) // ✅ Увеличено с 16 до 18
                                .background(Color.dsRed)
                            }
                            .frame(maxWidth: .infinity) // ✅ Добавлено на Button
                        }
                        .frame(height: 54) // ✅ Фиксированная высота секции кнопок
                        .opacity(showButtons ? 1 : 0)
                        .offset(y: showButtons ? 0 : 20)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(0.4 + Double(rewards.count) * 0.15),
                            value: showButtons
                        )
                    }
                    .frame(
                        maxWidth: min(geometry.size.width * 0.9, 500), // ✅ Адаптивно: 90% ширины или макс 500pt
                        maxHeight: geometry.size.height * 0.85 // ✅ Макс 85% высоты экрана
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.dsSurface)
                    )
                    // 🔴 КРАСНОЕ СВЕЧЕНИЕ (многослойное)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.dsRed,
                                        Color.dsRed.opacity(0.5),
                                        Color.dsRed
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.dsRed.opacity(glowIntensity * 0.8), radius: 15)
                    .shadow(color: Color.dsRed.opacity(glowIntensity * 0.5), radius: 30)
                    .shadow(color: Color.dsRed.opacity(glowIntensity * 0.3), radius: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.dsRed.opacity(0.3), lineWidth: 0.5)
                            .padding(2)
                    )
                    .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            startAnimationSequence()
            startGlowPulse()
        }
    }
    
    // MARK: - Запуск последовательной анимации
    private func startAnimationSequence() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showPopup = true
        }
        
        SoundManager.shared.play(.demotion, haptic: .warning)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sparkleTrigger = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                levelScale = 1.0
                levelOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showRewards = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showButtons = true
        }
    }
    
    private func startGlowPulse() {
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 1.0
        }
    }
    
    private func confirmAction() {
        withAnimation(.easeInOut(duration: 0.9)) {
            showPopup = false
            showRewards = false
            showButtons = false
            glowIntensity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onConfirm()
        }
    }
    
    private func cancelAction() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showPopup = false
            showRewards = false
            showButtons = false
            glowIntensity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onCancel()
        }
    }
}

// MARK: - Тёмные искры (для отката)
struct DarkSparkleEffect: View {
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
                Image(systemName: "xmark")
                    .font(.system(size: particle.size, weight: .bold))
                    .foregroundColor(Color.dsRed)
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
        
        for i in 0..<15 {
            let particle = Particle(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2,
                size: CGFloat.random(in: 10...18),
                opacity: 1.0,
                angle: Double(i) * 24.0,
                speed: Double.random(in: 80...140),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            particles = []
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        
        DemotionPopupView(
            currentLevel: 3,
            rewards: [
                MilestoneReward(
                    icon: "shield.lefthalf.filled",
                    title: "Выбор подкласса",
                    description: "Ваш путь обретает уникальное направление."
                ),
                MilestoneReward(
                    icon: "bolt.fill",
                    title: "+5 к максимальному HP",
                    description: "Опыт делает вас выносливее."
                )
            ],
            onConfirm: { print("Confirmed") },
            onCancel: { print("Cancelled") }
        )
    }
    .preferredColorScheme(.dark)
}
