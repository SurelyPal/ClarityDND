// PartyStatusIndicator.swift
// Clarity
//
// Created by KEBAB on 05.06.2026.
//
import SwiftUI

/// Глобальный индикатор статуса партии.
/// Размещается поверх всего приложения в AppRootView.
struct PartyStatusIndicator: View {
    @ObservedObject private var partyManager = PartyManager.shared // ✅ Исправлено: @StateObject → @ObservedObject
    @State private var pulse: Double = 0.6
    @State private var showDisconnectError: Bool = false
    @State private var showDetailsSheet: Bool = false
    @State private var connectionStartTime: Date? = nil
    
    var body: some View {
        if shouldShow {
            NavigationLink(destination: PartyLobbyView()) {
                HStack(spacing: 6) {
                    indicatorIcon
                    indicatorText
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(backgroundColor)
                )
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
                .shadow(
                    color: isConnected ? glowColor.opacity(pulse * 0.9) : .clear,  // ✅ Было 0.6
                    radius: 10  // ✅ Было 8
                )
            }
            .buttonStyle(.plain)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShow)
            .onLongPressGesture {
                // ✅ Показываем детали при долгом нажатии
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showDetailsSheet = true
            }
            .onChange(of: partyManager.connectionState) { oldState, newState in
                handleStateChange(from: oldState, to: newState)
            }
            .onChange(of: isConnected) { _, connected in
                // ✅ Исправлено: анимация пульсации теперь корректно возобновляется
                if connected {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulse = 1.0
                    }
                    connectionStartTime = Date()
                } else {
                    pulse = 0.6
                }
            }
            .sheet(isPresented: $showDetailsSheet) {
                ConnectionDetailsSheet(
                    connectionState: partyManager.connectionState,
                    role: partyManager.role,
                    partyMembers: partyManager.partyMembers,
                    connectionStartTime: connectionStartTime,
                    disconnectReason: partyManager.disconnectReason
                )
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Обработка изменений состояния
    
    private func handleStateChange(from oldState: PartyManager.ConnectionState, to newState: PartyManager.ConnectionState) {
        // ✅ Тактильная обратная связь при изменении состояния
        switch newState {
        case .connected:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
        case .connecting, .searching:
            UISelectionFeedbackGenerator().selectionChanged()
            
        case .disconnected:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            
            // ✅ Показываем ошибку при потере связи (3 секунды)
            if case .connected = oldState {
                showDisconnectError = true
                
                // Через 3 секунды скрываем ошибку
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDisconnectError = false
                    }
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Иконка состояния
    
    @ViewBuilder
    private var indicatorIcon: some View {
        switch partyManager.connectionState {
        case .disconnected:
            if showDisconnectError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsRed)
            } else {
                EmptyView()
            }
            
        case .selectingCharacter:
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 10))
                .foregroundColor(Color.dsSoul)
            
        case .configuringRules:
            Image(systemName: "gearshape.fill")
                .font(.system(size: 10))
                .foregroundColor(Color.dsSoul)
            
        case .hosting:
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
                .foregroundColor(Color.dsSoul)
            
        case .searching, .connecting:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                .scaleEffect(0.6)
            
        case .connected:
            if partyManager.role == .dungeonMaster {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsSoul)
            } else {
                Image(systemName: "person.fill.checkmark")
                    .font(.system(size: 10))
                    .foregroundColor(.dsEstus)
            }
        }
    }
    
    // MARK: - Текст состояния
    
    @ViewBuilder
    private var indicatorText: some View {
        switch partyManager.connectionState {
        case .disconnected:
            if showDisconnectError {
                Text("Связь потеряна")
                    .foregroundColor(Color.dsRed)
            } else {
                EmptyView()
            }
            
        case .selectingCharacter:
            Text("Выбор героя")
            
        case .configuringRules:
            Text("Настройка правил")
            
        case .hosting:
            Text("ДМ · \(partyManager.partyMembers.count)")
            
        case .searching:
            Text("Поиск...")
            
        case .connecting(let peerName):
            Text(peerName)
                .lineLimit(1)
            
        case .connected:
            if partyManager.role == .dungeonMaster {
                Text("Партия · \(partyManager.partyMembers.count)")
            } else {
                Text("В партии")
            }
        }
    }
    
    // MARK: - Вспомогательные свойства
    
    private var shouldShow: Bool {
        // ✅ Показываем индикатор если:
        // 1. Не disconnected, ИЛИ
        // 2. Только что потеряли связь (показываем ошибку)
        partyManager.connectionState != .disconnected || showDisconnectError
    }
    
    private var isConnected: Bool {
        if case .connected = partyManager.connectionState { return true }
        return false
    }
    
    private var textColor: Color {
        switch partyManager.connectionState {
        case .selectingCharacter, .searching, .connecting:
            return Color.dsTextDim
            
        case .configuringRules:
            return Color.dsSoul
            
        case .hosting, .connected:
            return partyManager.role == .dungeonMaster ? Color.dsSoul : .white
            
        case .disconnected:
            return showDisconnectError ? Color.dsRed : Color.dsTextDim
        }
    }
    
    private var backgroundColor: Color {
        switch partyManager.connectionState {
        case .selectingCharacter:
            return Color.dsSoul.opacity(0.25)  // ✅ Было 0.1
            
        case .configuringRules:
            return Color.dsSoul.opacity(0.30)  // ✅ Было 0.15
            
        case .hosting:
            return Color.dsSoul.opacity(0.30)  // ✅ Было 0.15
            
        case .connected:
            return partyManager.role == .dungeonMaster
            ? Color.dsSoul.opacity(0.30)       // ✅ Было 0.15
            : Color.dsEstus.opacity(0.30)        // ✅ Было 0.15
            
        case .searching, .connecting:
            return Color.dsSurfaceAlt
            
        case .disconnected:
            return showDisconnectError ? Color.dsRed.opacity(0.30) : Color.dsSurfaceAlt  // ✅ Было 0.15
        }
    }
    
    private var borderColor: Color {
        switch partyManager.connectionState {
        case .selectingCharacter:
            return Color.dsSoul.opacity(0.7)  // ✅ Было 0.4
            
        case .configuringRules:
            return Color.dsSoul.opacity(0.8)  // ✅ Было 0.5
            
        case .hosting:
            return Color.dsSoul.opacity(0.8)  // ✅ Было 0.5
            
        case .connected:
            return partyManager.role == .dungeonMaster
            ? Color.dsSoul.opacity(0.8)       // ✅ Было 0.5
            : Color.dsEstus.opacity(0.8)        // ✅ Было 0.5
            
        case .searching, .connecting:
            return Color.dsBorder
            
        case .disconnected:
            return showDisconnectError ? Color.dsRed.opacity(0.8) : Color.clear  // ✅ Было 0.5
        }
    }
    
    private var glowColor: Color {
        partyManager.role == .dungeonMaster ? Color.dsSoul : .dsEstus
    }
}

// MARK: - Sheet с деталями подключения

struct ConnectionDetailsSheet: View {
    let connectionState: PartyManager.ConnectionState
    let role: PartyManager.Role
    let partyMembers: [PartyMember]
    let connectionStartTime: Date?
    let disconnectReason: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Заголовок
                HStack {
                    Text("✦ СТАТУС ПОДКЛЮЧЕНИЯ ✦")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(2)
                        .foregroundColor(Color.dsSoul)
                    
                    Spacer()
                    
                    Button("Закрыть") {
                        dismiss()
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Color.dsTextDim)
                }
                
                DSdivider()
                
                // Информация о роли
                DetailRow(
                    icon: role == .dungeonMaster ? "crown.fill" : "person.fill",
                    title: "Роль",
                    value: role == .dungeonMaster ? "Мастер подземелий" : "Игрок"
                )
                
                // Время подключения
                if let startTime = connectionStartTime {
                    DetailRow(
                        icon: "clock.fill",
                        title: "Время в сессии",
                        value: formatDuration(from: startTime)
                    )
                }
                
                // Количество игроков
                DetailRow(
                    icon: "person.3.fill",
                    title: "Игроков в партии",
                    value: "\(partyMembers.filter { $0.isConnected }.count) / \(partyMembers.count)"
                )
                
                // Статус подключения
                DetailRow(
                    icon: connectionIcon,
                    title: "Статус",
                    value: connectionStatusText,
                    valueColor: connectionStatusColor
                )
                
                // Причина отключения (если есть)
                if let reason = disconnectReason {
                    DetailRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Последняя ошибка",
                        value: reason,
                        valueColor: Color.dsRed
                    )
                }
                
                Spacer()
            }
            .padding(24)
        }
    }
    
    private var connectionIcon: String {
        switch connectionState {
        case .connected: return "checkmark.circle.fill"
        case .connecting, .searching: return "arrow.triangle.2.circlepath"
        case .disconnected: return "xmark.circle.fill"
        default: return "circle"
        }
    }
    
    private var connectionStatusText: String {
        switch connectionState {
        case .connected: return "Подключено"
        case .connecting: return "Подключение..."
        case .searching: return "Поиск..."
        case .hosting: return "Ожидание игроков"
        case .disconnected: return "Отключено"
        case .selectingCharacter: return "Выбор персонажа"
        case .configuringRules: return "Настройка правил"
        }
    }
    
    private var connectionStatusColor: Color {
        switch connectionState {
        case .connected: return .dsEstus
        case .connecting, .searching: return Color.dsSoul
        case .disconnected: return Color.dsRed
        default: return Color.dsTextDim
        }
    }
    
    private func formatDuration(from startTime: Date) -> String {
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes) мин \(seconds) сек"
        } else {
            return "\(seconds) сек"
        }
    }
}

// MARK: - Компонент строки деталей

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    var valueColor: Color = Color.dsText
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.dsSoul)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.dsBackground.ignoresSafeArea()
        
        VStack {
            HStack {
                Spacer()
                PartyStatusIndicator()
                    .padding(.trailing, 16)
                    .padding(.top, 8)
            }
            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
