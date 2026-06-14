//
//  MilestonePopupView.swift
//  Clarity.app
//

import SwiftUI

struct MilestonePopupView: View {
    let newMilestone: Int
    let rewards: [MilestoneReward]
    let onConfirm: () -> Void
    @Environment(\.theme) private var theme
    // MARK: - Состояния анимации
    @State private var showPopup = false
    @State private var showRewards = false
    @State private var showButton = false
    @State private var sparkleTrigger = false
    @State private var levelScale: CGFloat = 0.5
    @State private var levelOpacity: Double = 0
    
    // MARK: - Состояния свечения
    @State private var glowIntensity: Double = 0.6
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // ═══════════════════════════════════════════
            // 🌑 ЗАТЕМНЁННЫЙ ФОН
            // ═══════════════════════════════════════════
            Color.black.opacity(showPopup ? 0.85 : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: showPopup)
            
            // ═══════════════════════════════════════════
            // ✨ ЭФФЕКТ ИСКР (поверх фона, под карточкой)
            // ═══════════════════════════════════════════
            SparkleEffect(trigger: sparkleTrigger)
                .allowsHitTesting(false)
            
            // ═══════════════════════════════════════════
            // 🔆 ВНЕШНЕЕ СВЕЧЕНИЕ (аура вокруг окна)
            // ═══════════════════════════════════════════
            if showPopup {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        RadialGradient(
                            colors: [
                                theme.primary.opacity(glowIntensity * 0.4),
                                theme.primary.opacity(glowIntensity * 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 250
                        )
                    )
                    .frame(width: 420, height: 620)
                    .blur(radius: 30)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
            
            // ═══════════════════════════════════════════
            // 🃏 САМА КАРТОЧКА POPUP
            // ═══════════════════════════════════════════
            if showPopup {
                VStack(spacing: 0) {
                    // ─── Заголовок ───
                    VStack(spacing: 8) {
                        Text("НОВАЯ ВЕХА")
                            .font(.system(size: 10))
                            .tracking(3)
                            .foregroundColor(theme.textDim)
                            .opacity(showPopup ? 1 : 0)
                        
                        // Анимированное число уровня с glow
                        ZStack {
                            // Свечение под текстом
                            Text("УРОВЕНЬ \(newMilestone)")
                                .font(.system(size: 28, weight: .light))
                                .tracking(2)
                                .foregroundColor(theme.primary)
                                .blur(radius: 20)
                                .opacity(levelOpacity * 0.5)
                            
                            // Основной текст
                            Text("УРОВЕНЬ \(newMilestone)")
                                .font(.system(size: 28, weight: .light))
                                .tracking(2)
                                .foregroundColor(theme.primary)
                                .scaleEffect(levelScale)
                                .opacity(levelOpacity)
                        }
                        
                        DSdivider()
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(theme.surface)
                    .overlay(
                        CornerOrnaments(size: 16)
                    )
                    
                    Rectangle()
                        .fill(theme.border)
                        .frame(height: 0.5)
                    
                    // ─── Список наград (появляются последовательно) ───
                    VStack(spacing: 0) {
                        ForEach(Array(rewards.enumerated()), id: \.element.id) { index, reward in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: reward.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(theme.primary)
                                    .frame(width: 32)
                                    .padding(.top, 2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reward.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(theme.text)
                                    Text(reward.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textDim)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
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
                                        .fill(theme.border)
                                        .frame(height: 0.5)
                                }
                            }
                        }
                    }
                    .background(theme.surfaceAlt)
                    
                    // ─── Кнопка подтверждения ───
                    Button(action: confirmAction) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                            Text("Принять судьбу")
                                .font(.system(size: 15, weight: .medium))
                                .tracking(1)
                        }
                        .foregroundColor(theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primary)
                    }
                    .buttonStyle(.plain)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(0.3 + Double(rewards.count) * 0.15),
                        value: showButton
                    )
                }
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.surface)
                )
                // 🔆 ЗОЛОТОЕ СВЕЧЕНИЕ (многослойное)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.primary,
                                    theme.primaryDim,
                                    theme.primary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                // Три слоя тени для реалистичного свечения
                .shadow(color: theme.primary.opacity(glowIntensity * 0.8), radius: 15)
                .shadow(color: theme.primary.opacity(glowIntensity * 0.5), radius: 30)
                .shadow(color: theme.primary.opacity(glowIntensity * 0.3), radius: 50)
                // Внутренняя тонкая подсветка
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.primary.opacity(0.3), lineWidth: 0.5)
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
        SoundManager.shared.play(.levelUp, haptic: .success)
        // 2. Запускаем искры (чуть позже)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sparkleTrigger = true
        }
        
        // 3. Анимируем появление числа уровня
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                levelScale = 1.0
                levelOpacity = 1.0
            }
        }
        
        // 4. Показываем награды (запускается через .animation modifier)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showRewards = true
        }
        
        // 5. Показываем кнопку
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showButton = true
        }
    }
    
    // MARK: - Пульсация свечения (бесконечная)
    
    private func startGlowPulse() {
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 1.0
        }
    }
    
    // MARK: - Обработка подтверждения
    
    private func confirmAction() {
        // Останавливаем пульсацию и плавно убираем окно
        withAnimation(.easeInOut(duration: 0.3)) {
            showPopup = false
            showRewards = false
            showButton = false
            glowIntensity = 0
        }
        
        // Вызываем callback после завершения анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onConfirm()
        }
    
    }
}

// MARK: - Preview
#Preview {
    @Environment(\.theme) var theme
    ZStack {
        theme.background.ignoresSafeArea()
        
        MilestonePopupView(
            newMilestone: 3,
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
            ]
        ) {
            print("Confirmed!")
        }
    }
    .preferredColorScheme(.dark)
}

