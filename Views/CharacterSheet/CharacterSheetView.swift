//
//  CharacterSheetView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//
import SwiftData
import SwiftUI

#if os(macOS)
import AppKit
#endif

struct CharacterSheetView: View {
    @Environment(\.theme) private var theme
    @State private var showEditBlockedAlert = false
    @ObservedObject private var partyManager = PartyManager.shared
    
    @EnvironmentObject var store: CharacterStore
    @State var character: DNDCharacter
    @State private var currentHP: Int
    @State private var selectedTab = 0
    @State private var showingMap = false
    @State private var showingMilestonePopup = false
    
    // Состояния для drawer'а партии
    @State private var isDrawerOpen = false
    @State private var drawerDragOffset: CGFloat = 0
    @State private var selectedMember: PartyMember? = nil
    @State private var isDraggingHorizontally = false
    
    //   Состояния для отката уровня (перенесено из CharacterHeaderSection)
    @State private var showingDemotePopup = false
    @State private var demotionRewards: [MilestoneReward] = []
    
    init(character: DNDCharacter) {
        self._character = State(initialValue: character)
        self._currentHP = State(initialValue: character.currentHP)
    }
    
    // MARK: - Проверка прав редактирования
    
    private var canEditCharacter: Bool {
        if partyManager.gameRules.canEditCharacterOutsideParty {
            return true
        }
        if partyManager.role == .dungeonMaster {
            return partyManager.partyMembers.contains { member in
                member.id == character.id && member.isConnected
            }
        } else {
            if case .connected = partyManager.connectionState {
                return true
            }
            return false
        }
    }
    
    // MARK: - Главный body (композиция)
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            mainScrollContent
                .scrollDisabled(isDraggingHorizontally || isDrawerOpen)
            
            drawerDimmer
            partyDrawer
        }
        .navigationTitle(character.displayName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        #endif
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingMap) { MapView() }
        .sheet(item: $selectedMember) { member in
            memberDetailSheet(member: member)
        }
        .preferredColorScheme(.dark)
        .overlay { milestoneOverlay }
        .overlay { restVoteOverlay }
        .overlay { restEffectOverlay }
        .overlay { demoteOverlay }
        .simultaneousGesture(drawerDragGesture)
        .alert(
            partyManager.lastError != nil ? "Отключение от партии" : "Редактирование заблокировано",
            isPresented: $showEditBlockedAlert
        ) {
            Button("OK", role: .cancel) {
                partyManager.clearError()
                partyManager.clearDisconnectReason()
            }
        } message: {
            errorMessage
        }
        .onChange(of: partyManager.restVotingManager.activeRestEffect) { _, newEffect in
            handleRestEffect(newEffect)
        }
        .onChange(of: character.currentHP) { _, newValue in
            if currentHP != newValue { currentHP = newValue }
        }
        .onChange(of: partyManager.connectionState) { _, newState in
            handleConnectionStateChange(newState)
        }
    }
    
    // MARK: - @ViewBuilder: Основной скролл-контент
    
    @ViewBuilder
    private var mainScrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                CharacterHeaderSection(
                    character: $character,
                    currentHP: $currentHP,
                    canEdit: canEditCharacter,
                    onLevelUp: { showingMilestonePopup = true },
                    onDemote: {
                        demotionRewards = MilestoneLibrary.rewards(for: character.level)
                        showingDemotePopup = true
                        store.update(character, changed: .full)
                    }
                )
                .equatable()
                .padding(.top, 15)
                HPSection(
                    character: $character,
                    currentHP: $currentHP,
                    canEdit: canEditCharacter,
                    showEditBlockedAlert: $showEditBlockedAlert
                )
                .equatable()
                
                StressSection(character: $character, canEdit: canEditCharacter)
                    .equatable()
                
                TabSection(character: $character, selectedTab: $selectedTab, canEdit: canEditCharacter)
                    .equatable()
                
                if case .connected = partyManager.connectionState {
                    restButtonsSection
                }
            }
            .padding(.bottom, 40)
        }
        
        //   PULL-TO-REFRESH: потяни вниз для переподключения к партии
        .refreshable {
            SoundManager.shared.play(.equip, haptic: .light)
            let success = await partyManager.reconnect()
            
            if success {
                // Успешное переподключение — синхронизируем данные
                if partyManager.role == .player {
                    partyManager.syncFull(character)
                }
            }
        }
        
        .scrollDisabled(isDraggingHorizontally || isDrawerOpen)
    }
        // MARK: - @ViewBuilder: Кнопки отдыха
        
        @ViewBuilder
        private var restButtonsSection: some View {
            VStack(spacing: 12) {
                DSdivider()
                    .padding(.horizontal, 40)
                
                HStack(spacing: 12) {
                    shortRestButton
                    longRestButton
                }
                .padding(.horizontal, 16)
                
                Text("Доступно: \(partyManager.gameRules.shortRestsAvailable) коротких / \(partyManager.gameRules.longRestsAvailable) долгих")
                    .font(.system(size: 10))
                    .foregroundColor(theme.textDim)
                    .padding(.top, 4)
            }
            .padding(.bottom, 20)
        }
        
        private var shortRestButton: some View {
            Button {
                if partyManager.gameRules.canShortRest {
                    SoundManager.shared.play(.equip, haptic: .medium)
                    partyManager.initiateRestVote(type: .short, from: character)
                } else {
                    PlatformCompatibility.hapticNotification(.warning)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 11))
                    Text("Короткий отдых")
                        .font(.system(size: 12, weight: .medium))
                    
                    if !partyManager.gameRules.canShortRest {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                    }
                }
                .foregroundColor(partyManager.gameRules.canShortRest ? theme.background : theme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(partyManager.gameRules.canShortRest ? theme.tertiary : theme.surfaceAlt.opacity(0.5))
                .cornerRadius(4)
                .opacity(partyManager.gameRules.canShortRest ? 1.0 : 0.6)
            }
            .buttonStyle(.plain)
        }
        
        private var longRestButton: some View {
            Button {
                SoundManager.shared.play(.equip, haptic: .medium)
                partyManager.initiateRestVote(type: .long, from: character)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 11))
                    Text("Долгий отдых")
                        .font(.system(size: 12, weight: .medium))
                    
                    if !partyManager.gameRules.canLongRest {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                    }
                }
                .foregroundColor(partyManager.gameRules.canLongRest ? theme.background : theme.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(partyManager.gameRules.canLongRest ? theme.primary : theme.surfaceAlt)
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .disabled(!partyManager.gameRules.canLongRest)
        }
        
        // MARK: - @ViewBuilder: Drawer затемнение
        
        @ViewBuilder
        private var drawerDimmer: some View {
            if isDrawerOpen {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4)) {
                            isDrawerOpen = false
                        }
                    }
            }
        }
        
        // MARK: - @ViewBuilder: Drawer с членами партии
        
        @ViewBuilder
        private var partyDrawer: some View {
            PartyMembersDrawer(
                partyManager: partyManager,
                isOpen: $isDrawerOpen,
                members: partyManager.partyMembers
            ) { member in
                selectedMember = member
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isDrawerOpen = false
                }
            }
            .frame(width: 280)
            .offset(x: drawerOffsetX)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDrawerOpen)
            .allowsHitTesting(isDrawerOpen || drawerDragOffset < 0)
            .zIndex(1000)
            .transition(.move(edge: .trailing))
        }
        
    private var drawerOffsetX: CGFloat {
        #if os(iOS)
        let screenWidth = UIScreen.main.bounds.width
        #elseif os(macOS)
        let screenWidth = NSScreen.main?.frame.width ?? 1024
        #else
        let screenWidth: CGFloat = 1024
        #endif
        
        if isDrawerOpen {
            return drawerDragOffset
        } else {
            return (screenWidth / 2 + 140) + drawerDragOffset
        }
    }
        
        // MARK: - @ViewBuilder: Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                drawerToggleButton
                mapButton
            }
        }
        #elseif os(macOS)
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 16) {
                drawerToggleButton
                mapButton
            }
        }
        #endif
    }
        
        private var drawerToggleButton: some View {
            Button {
                withAnimation(.spring(response: 0.4)) {
                    isDrawerOpen.toggle()
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16))
                    
                    if !partyManager.partyMembers.isEmpty {
                        Text("\(partyManager.partyMembers.count)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(theme.background)
                            .padding(3)
                            .background(theme.primary)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
        
        private var mapButton: some View {
            Button(action: { showingMap = true }) {
                Image(systemName: "map")
                    .foregroundColor(theme.primary)
            }
        }
        
        // MARK: - @ViewBuilder: Sheet с деталями члена партии
        
    @ViewBuilder
    private func memberDetailSheet(member: PartyMember) -> some View {
        NavigationStack {
            DungeonMasterDetailView(memberID: member.id)
                .environmentObject(partyManager)
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Закрыть") {
                            selectedMember = nil
                        }
                        .foregroundColor(theme.primary)
                    }
                    #elseif os(macOS)
                    ToolbarItem(placement: .navigation) {
                        Button("Закрыть") {
                            selectedMember = nil
                        }
                        .foregroundColor(theme.primary)
                    }
                    #endif
                }
        }
        #if os(iOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        #endif
    }
        
        // MARK: - @ViewBuilder: Overlay повышения уровня
        
        @ViewBuilder
        private var milestoneOverlay: some View {
            if showingMilestonePopup {
                MilestonePopupView(
                    newMilestone: character.level + 1,
                    rewards: MilestoneLibrary.rewards(for: character.level + 1)
                ) {
                    character.levelUp()
                    currentHP = character.hitPoints
                    
                    // ✅ ИСПРАВЛЕНО: явное указание .full для синхронизации level up
                    // Это отправляет ВСЕ данные включая новый maxHP и level
                    store.update(character, changed: .full)
                    PartyManager.shared.forceSyncBasic(character)
                    showingMilestonePopup = false
                    
                    print("🎯 Level up: \(character.displayName) → level=\(character.level), HP=\(character.currentHP)/\(character.hitPoints)")
                }
            }
        }
        // MARK: - @ViewBuilder: Overlay отката уровня
        
        @ViewBuilder
        private var demoteOverlay: some View {
            if showingDemotePopup {
                DemotionPopupView(
                    currentLevel: character.level,
                    rewards: demotionRewards,
                    onConfirm: {
                        performDemotion()
                        showingDemotePopup = false
                    },
                    onCancel: {
                        showingDemotePopup = false
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(10000)
            }
        }
        
        // MARK: - @ViewBuilder: Overlay голосования за отдых
        
        @ViewBuilder
        private var restVoteOverlay: some View {
            if let voteSession = partyManager.restVotingManager.activeRestVote {
                RestVoteOverlayView(
                    session: voteSession,
                    myVoteSent: partyManager.restVotingManager.myVoteSent,
                    isDungeonMaster: partyManager.role == .dungeonMaster,
                    onVote: { accepted in
                        partyManager.sendRestVote(accepted: accepted, from: character)
                    },
                    onCancel: {
                        partyManager.cancelRestVote()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(9999)
            }
        }
        
        // MARK: - @ViewBuilder: Overlay эффекта отдыха
        
        @ViewBuilder
        private var restEffectOverlay: some View {
            if let effect = partyManager.restVotingManager.activeRestEffect {
                RestEffectOverlayView(effect: effect) {
                    partyManager.restVotingManager.activeRestEffect = nil
                }
                .zIndex(10000)
            }
        }
        
        // MARK: - Жест открытия/закрытия drawer'а
        
        private var drawerDragGesture: some Gesture {
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    let isHorizontalSwipe = abs(horizontal) > abs(vertical) + 10
                    
                    if isHorizontalSwipe {
                        isDraggingHorizontally = true
                    }
                    
                    if isHorizontalSwipe {
                        if !isDrawerOpen && horizontal < 0 {
                            drawerDragOffset = max(horizontal, -280)
                        } else if isDrawerOpen && horizontal > 0 {
                            drawerDragOffset = min(horizontal, 280)
                        }
                    }
                }
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    let isHorizontalSwipe = abs(horizontal) > abs(vertical) + 10
                    
                    if !isDrawerOpen && isHorizontalSwipe && horizontal < -100 {
                        withAnimation(.spring(response: 0.4)) { isDrawerOpen = true }
                    } else if isDrawerOpen && isHorizontalSwipe && horizontal > 100 {
                        withAnimation(.spring(response: 0.4)) { isDrawerOpen = false }
                    }
                    
                    withAnimation(.spring(response: 0.4)) { drawerDragOffset = 0 }
                    isDraggingHorizontally = false
                }
        }
        
        // MARK: - Обработчики onChange
        
        private func handleRestEffect(_ newEffect: RestVotingManager.RestEffectEvent?) {
            // ✅ Эффект уже применён в PartyManager.handleRestStarted
            // Здесь только логирование (если нужно)
            guard let effect = newEffect else { return }
            print("🎬 Визуальный эффект отдыха: \(effect.restType.displayName)")
        }
        
        private func handleConnectionStateChange(_ newState: PartyManager.ConnectionState) {
            if case .disconnected = newState {
                if isDrawerOpen {
                    withAnimation(.spring(response: 0.4)) {
                        isDrawerOpen = false
                    }
                }
                if partyManager.lastError != nil {
                    showEditBlockedAlert = true
                }
            }
        }
        
        // MARK: - Откат уровня
        
        private func performDemotion() {
            guard character.level > 1 else { return }
            
            print("📉 DEMOTION НАЧАЛО: HP=\(currentHP)/\(character.hitPoints), level=\(character.level)")
            
            withAnimation(.spring(response: 0.4)) {
                character.level -= 1
                
                let newMaxHP = max(1, character.hitPoints - 5)
                character.hitPoints = newMaxHP
                
                let oldHP = currentHP
                currentHP = min(currentHP, newMaxHP)
                currentHP = max(1, currentHP)
                
                print("📉 DEMOTION ИЗМЕНЕНИЕ: oldHP=\(oldHP), newHP=\(currentHP), newMaxHP=\(newMaxHP)")
                
                SoundManager.shared.play(.demotion, haptic: .warning)
                
                store.update(character, changed: .full)
                
                print("📉 DEMOTION ПОСЛЕ STORE: HP=\(currentHP)/\(character.hitPoints)")
            }
            
            // ✅ ВАЖНО: добавляем задержку перед сетевой синхронизацией
            // Это гарантирует что store.update полностью завершится
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("📉 DEMOTION СИНХРОНИЗАЦИЯ: HP=\(self.currentHP)/\(self.character.hitPoints)")
                PartyManager.shared.forceSyncBasic(self.character)
            }
        }
        // MARK: - Текст ошибки для alert
        
        @ViewBuilder
        private var errorMessage: some View {
            if let error = partyManager.lastError {
                Text(error)
            } else if let reason = partyManager.disconnectReason {
                Text(reason)
            } else {
                Text("Мастер запретил изменять героев вне активной партии.\nПодключитесь к ДМ, чтобы вносить изменения.")
        }
    }
}


// ⚔️ Превью: Воин высокого уровня с низким HP (красный индикатор)
#Preview("Воин (низкое HP)") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeFighter()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

// 🎵 Превью: Бард с инструментом
#Preview("Бард с лютней") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeBard()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

// 🃏 Превью: Мистик с картами таро
#Preview("Мистик с таро") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeMystic()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

// 🏹 Превью: Следопыт (Ranger) — максимальный уровень
#Preview("Следопыт (max уровень)") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeRanger()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

// 🎨 Хелпер для создания тестовых данных
// MARK: - Previews

#Preview("Базовый персонаж (Плут)") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeRogue()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

#Preview("Воин (низкое HP)") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeFighter()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

#Preview("Бард с лютней") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeBard()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

#Preview("Мистик с таро") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeMystic()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}

#Preview("Следопыт (max уровень)") {
    let container = PreviewHelper.makeContainer()
    let character = PreviewHelper.makeRanger()
    container.mainContext.insert(character)
    let store = CharacterStore(context: container.mainContext)
    
    return NavigationStack {
        CharacterSheetView(character: character)
            .environmentObject(store)
    }
    .preferredColorScheme(.dark)
}
