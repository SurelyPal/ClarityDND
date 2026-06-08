//
//  PartyStatusIndicator.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI

/// Глобальный индикатор статуса партии.
/// Размещается поверх всего приложения в AppRootView.
struct PartyStatusIndicator: View {
    @StateObject private var partyManager = PartyManager.shared
    @State private var pulse: Double = 0.6
    
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
                    color: isConnected ? glowColor.opacity(pulse * 0.6) : .clear,
                    radius: 8
                )
            }
            .buttonStyle(.plain)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShow)
            .onAppear {
                if isConnected {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        pulse = 1.0
                    }
                }
            }
        }
    }
    
    
    // MARK: - Иконка состояния
    
    @ViewBuilder
    private var indicatorIcon: some View {
        switch partyManager.connectionState {
        case .disconnected:
            EmptyView()
            
        case .selectingCharacter:
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 10))
                .foregroundColor(Color.dsGold)
            
        case .configuringRules:
            Image(systemName: "gearshape.fill")
                .font(.system(size: 10))
                .foregroundColor(Color.dsGold)
            
        case .hosting:
            Image(systemName: "crown.fill")
                .font(.system(size: 10))
                .foregroundColor(Color.dsGold)
            
        case .searching, .connecting:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                .scaleEffect(0.6)
            
        case .connected:
            if partyManager.role == .dungeonMaster {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsGold)
            } else {
                Image(systemName: "person.fill.checkmark")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Текст состояния
    
    @ViewBuilder
    private var indicatorText: some View {
        switch partyManager.connectionState {
        case .disconnected:
            EmptyView()
            
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
        partyManager.connectionState != .disconnected
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
            return Color.dsTextDim
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
            return Color.dsSurfaceAlt
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
            return Color.clear
        }
    }
    
    private var glowColor: Color {
        partyManager.role == .dungeonMaster ? Color.dsGold : .green
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

