//
// SoundManager.swift
// Clarity
//
// Created by KEBAB on 05.06.2026.
//
import AVFoundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Синглтон для воспроизведения звуковых эффектов.
/// Все звуки пре-лоадятся в память при старте приложения,
/// чтобы избежать задержки при первом воспроизведении.
@MainActor
final class SoundManager {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    /// Все звуки игры
    enum Sound: String, CaseIterable {
        case levelUp = "level_up"        // ✨ Золотой звон, арпеджио
        case demotion = "demotion"       // 🔻 Тёмный гул, разбитое стекло
        case tarotDraw = "tarot_draw"    // 🃏 Шуршание карты
        case tarotFlip = "tarot_flip"    // 🔄 Переворот карты
        case equip = "equip"             // ⚔️ Металлический звон
        case pageTurn = "page_turn"      // 📖 Шелест страниц (навигация)
        
        /// Формат файла в бандле
        var fileExtension: String { "wav" }
    }
    
    private init() {
        configureAudioSession()
        preloadAll()
    }
    
    // MARK: - Настройка аудио-сессии
    
    private func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,           // Не прерывает музыку пользователя
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Не удалось настроить аудио-сессию: \(error)")
        }
        #elseif os(macOS)
        // На macOS AVAudioSession не нужен - система управляет аудио автоматически
        print("🎵 macOS: аудио-сессия не требуется")
        #endif
    }
    
    // MARK: - Preload всех звуков
    
    private func preloadAll() {
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(
                forResource: sound.rawValue,
                withExtension: sound.fileExtension
            ) else {
                print("⚠️ Звук не найден: \(sound.rawValue).\(sound.fileExtension)")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = volume(for: sound)
                players[sound.rawValue] = player
            } catch {
                print("⚠️ Не удалось загрузить звук \(sound.rawValue): \(error)")
            }
        }
    }
    
    /// Громкость для каждого звука (настраивается под баланс)
    private func volume(for sound: Sound) -> Float {
        switch sound {
        case .levelUp: return 0.7   // Яркий, торжественный
        case .demotion: return 0.6  // Зловещий, не оглушающий
        case .tarotDraw: return 0.5 // Тихий, атмосферный
        case .tarotFlip: return 0.4 // Очень тихий
        case .equip: return 0.5
        case .pageTurn: return 0.3  // Фоновый
        }
    }
    
    // MARK: - Публичный API
    
    /// Воспроизводит звук. Безопасно — не крашится если файл не найден.
    func play(_ sound: Sound) {
        guard let player = players[sound.rawValue] else {
            print("⚠️ Звук не загружен: \(sound.rawValue)")
            return
        }
        
        // Сбрасываем на начало, если звук ещё играет (rapid fire protection)
        if player.isPlaying {
            player.currentTime = 0
        }
        
        player.play()
    }
    
    /// Воспроизводит звук с тактильной отдачей
    func play(_ sound: Sound, haptic: HapticType) {
        play(sound)
        triggerHaptic(haptic)
    }
    
    enum HapticType {
        case light, medium, heavy, success, warning, error
    }
    
    private func triggerHaptic(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #elseif os(macOS)
        // На macOS тактильная отдача недоступна - игнорируем
        // Можно добавить звуковой feedback через NSSound.beep() если нужно
        #endif
    }
}
