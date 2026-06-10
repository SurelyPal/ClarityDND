//
//  PlatformCompatibility.swift
//  Clarity
//
//  Created by AI on 11.06.2026.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Кроссплатформенный helper для платформо-зависимых API.
/// Инкапсулирует различия между iOS и macOS в одном месте.
enum PlatformCompatibility {
    
    // MARK: - Haptic Feedback
    
    /// Типы уведомлений для тактильной отдачи
    enum NotificationType {
        case success, warning, error
    }
    
    /// Типы ударов для тактильной отдачи
    enum ImpactType {
        case light, medium, heavy
    }
    
    /// Типы выбора для тактильной отдачи
    enum SelectionType {
        case changed
    }
    
    // MARK: - Haptic Notification
    
    /// Показывает тактильную отдачу типа "уведомление"
    /// - Parameter type: тип уведомления (success, warning, error)
    static func hapticNotification(_ type: NotificationType) {
        #if os(iOS)
        // ✅ ПРЯМОЙ ВЫЗОВ UIKit API (НЕ вызываем hapticNotification!)
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .success:
            generator.notificationOccurred(.success)
        case .warning:
            generator.notificationOccurred(.warning)
        case .error:
            generator.notificationOccurred(.error)
        }
        #elseif os(macOS)
        // На macOS нет тактильной отдачи — используем звуковой сигнал
        NSSound.beep()
        #endif
    }
    
    // MARK: - Haptic Impact
    
    /// Показывает тактильную отдачу типа "удар"
    /// - Parameter type: сила удара (light, medium, heavy)
    static func hapticImpact(_ type: ImpactType) {
        #if os(iOS)
        // ✅ ПРЯМОЙ ВЫЗОВ UIKit API
        switch type {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        #elseif os(macOS)
        // На macOS нет тактильной отдачи — игнорируем
        // (можно добавить визуальный feedback при желании)
        #endif
    }
    
    // MARK: - Haptic Selection
    
    /// Показывает тактильную отдачу типа "выбор"
    /// - Parameter type: тип выбора (changed)
    static func hapticSelection(_ type: SelectionType = .changed) {
        #if os(iOS)
        // ✅ ПРЯМОЙ ВЫЗОВ UIKit API
        let generator = UISelectionFeedbackGenerator()
        switch type {
        case .changed:
            generator.selectionChanged()
        }
        #elseif os(macOS)
        // На macOS нет тактильной отдачи — игнорируем
        #endif
    }
    
    // MARK: - Device Name
    
    /// Возвращает имя устройства для MultipeerConnectivity
    static var deviceName: String {
        #if os(iOS)
        // ✅ ПРЯМОЙ ДОСТУП к UIDevice (НЕ вызываем PlatformCompatibility.deviceName!)
        return UIDevice.current.name
        #elseif os(macOS)
        // На macOS используем Host API из Foundation
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        #else
        return "Unknown Device"
        #endif
    }
}
