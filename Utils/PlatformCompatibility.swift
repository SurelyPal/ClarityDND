import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum PlatformCompatibility {
    /// Имя устройства (кроссплатформенная замена UIDevice.current.name)
    static var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(macOS)
        return Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        #else
        return "Unknown Device"
        #endif
    }
    
    /// Тактильный feedback (только iOS)
    static func hapticNotification(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
    
    enum HapticType {
        case success, warning, error
    }
}