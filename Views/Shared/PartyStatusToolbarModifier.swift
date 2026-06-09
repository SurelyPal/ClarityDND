//
//  PartyStatusToolbarModifier.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

/// Модификатор для добавления PartyStatusIndicator в Toolbar
struct PartyStatusToolbarModifier: ViewModifier {
    @ObservedObject private var partyManager = PartyManager.shared
    @State private var showDetailsSheet = false
    @State private var pulse: Double = 0.6
    @State private var showDisconnectError = false
    @State private var connectionStartTime: Date? = nil

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if shouldShow {
                        Button {
                            // Tap — переход в PartyLobbyView
                        } label: {
                            NavigationLink(destination: PartyLobbyView()) {
                                HStack(spacing: 4) {
                                    indicatorIcon
                                    indicatorText
                                }
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(textColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(backgroundColor)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                                .shadow(
                                    color: isConnected ? glowColor.opacity(pulse * 0.6) : .clear,
                                    radius: 6
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .onLongPressGesture {
                            PlatformCompatibility.hapticNotification(.success)
                            showDetailsSheet = true
                        }
                        .onChange(of: partyManager.connectionState) { oldState, newState in
                            handleStateChange(from: oldState, to: newState)
                        }
                        .onChange(of: isConnected) { _, connected in
                            if connected {
                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                    pulse = 1.0
                                }
                                connectionStartTime = Date()
                            } else {
                                pulse = 0.6
                            }
                        }
                    }
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

    // MARK: - Обработка изменений состояния

    private func handleStateChange(from oldState: PartyManager.ConnectionState, to newState: PartyManager.ConnectionState) {
        switch newState {
        case .connected:
            PlatformCompatibility.hapticNotification(.success)
            
        case .connecting, .searching:
            #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
            
        case .disconnected:
            PlatformCompatibility.hapticNotification(.error)
            
            if case .connected = oldState {
                showDisconnectError = true
                
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
                    .font(.system(size: 9))
                    .foregroundColor(Color.dsRed)
            } else {
                EmptyView()
            }
            
        case .selectingCharacter:
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 9))
                .foregroundColor(Color.dsGold)
            
        case .configuringRules:
            Image(systemName: "gearshape.fill")
                .font(.system(size: 9))
                .foregroundColor(Color.dsGold)
            
        case .hosting:
            Image(systemName: "crown.fill")
                .font(.system(size: 9))
                .foregroundColor(Color.dsGold)
            
        case .searching, .connecting:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                .scaleEffect(0.5)
            
        case .connected:
            if partyManager.role == .dungeonMaster {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9))
                    .foregroundColor(Color.dsGold)
            } else {
                Image(systemName: "person.fill.checkmark")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
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
                    .font(.system(size: 9))
            } else {
                EmptyView()
            }
            
        case .selectingCharacter:
            Text("Выбор героя")
                .font(.system(size: 9))
            
        case .configuringRules:
            Text("Настройка правил")
                .font(.system(size: 9))
            
        case .hosting:
            Text("ДМ · \(partyManager.partyMembers.count)")
                .font(.system(size: 9))
            
        case .searching:
            Text("Поиск...")
                .font(.system(size: 9))
            
        case .connecting(let peerName):
            Text(peerName)
                .lineLimit(1)
                .font(.system(size: 9))
            
        case .connected:
            if partyManager.role == .dungeonMaster {
                Text("Партия · \(partyManager.partyMembers.count)")
                    .font(.system(size: 9))
            } else {
                Text("В партии")
                    .font(.system(size: 9))
            }
        }
    }

    // MARK: - Вспомогательные свойства

    private var shouldShow: Bool {
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
            return Color.dsGold
            
        case .hosting, .connected:
            return partyManager.role == .dungeonMaster ? Color.dsGold : .white
            
        case .disconnected:
            return showDisconnectError ? Color.dsRed : Color.dsTextDim
        }
    }

    private var backgroundColor: Color {
        switch partyManager.connectionState {
        case .selectingCharacter:
            return Color.dsGold.opacity(0.1)
            
        case .configuringRules:
            return Color.dsGold.opacity(0.15)
            
        case .hosting:
            return Color.dsGold.opacity(0.15)
            
        case .connected:
            return partyManager.role == .dungeonMaster
            ? Color.dsGold.opacity(0.15)
            : Color.green.opacity(0.15)
            
        case .searching, .connecting:
            return Color.dsSurfaceAlt
            
        case .disconnected:
            return showDisconnectError ? Color.dsRed.opacity(0.15) : Color.dsSurfaceAlt
        }
    }

    private var borderColor: Color {
        switch partyManager.connectionState {
        case .selectingCharacter:
            return Color.dsGold.opacity(0.4)
            
        case .configuringRules:
            return Color.dsGold.opacity(0.5)
            
        case .hosting:
            return Color.dsGold.opacity(0.5)
            
        case .connected:
            return partyManager.role == .dungeonMaster
            ? Color.dsGold.opacity(0.5)
            : Color.green.opacity(0.5)
            
        case .searching, .connecting:
            return Color.dsBorder
            
        case .disconnected:
            return showDisconnectError ? Color.dsRed.opacity(0.5) : Color.clear
        }
    }

    private var glowColor: Color {
        partyManager.role == .dungeonMaster ? Color.dsGold : .green
    }
}

// MARK: - Extension для удобного использования

extension View {
    /// Добавляет PartyStatusIndicator в Toolbar
    func partyStatusToolbar() -> some View {
        modifier(PartyStatusToolbarModifier())
    }
}
