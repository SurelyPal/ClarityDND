//
//  CharacterSheetView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct CharacterSheetView: View {
    
    @State private var showEditBlockedAlert = false
    // 🆕 КРИТИЧНО: подписываемся на изменения PartyManager
    @ObservedObject private var partyManager = PartyManager.shared
    private var demotionMessage: String {
        let rewardTitles = demotionRewards.map { $0.title }.joined(separator: ", ")
        return """
    Уровень станет \(character.level - 1).
    Будут отозваны награды:
    \(rewardTitles)

    HP уменьшится на 5.
    """
    }
    // MARK: - Откат уровня
    
    private func performDemotion() {
        withAnimation(.spring(response: 0.4)) {
            character.level -= 1
            // 📉 Уменьшаем МАКСИМУМ HP на 5 (но не ниже 1)
            let newMaxHP = max(1, character.hitPoints - 5)
            character.hitPoints = newMaxHP
            // Если игрок был ранен — сохраняем его состояние (но не ниже 1)
            // Если был полностью здоров — опускаем до нового максимума
            currentHP = min(currentHP, newMaxHP)
            currentHP = max(1, currentHP)
            
            // 💀 Звук и визуальный эффект отката
            SoundManager.shared.play(.demotion, haptic: .warning)
            
            store.update(character, changed: .full)
        }
    }
    /// Проверяет, разрешено ли редактировать этого персонажа
    private var canEditCharacter: Bool {
        // Если правило разрешает — всегда можно
        if partyManager.gameRules.canEditCharacterOutsideParty {
             return true
        }
        
        // 🆕 РАЗНАЯ логика для ДМа и Игрока!
        if partyManager.role == .dungeonMaster {
            // ДМ проверяет свой список гостей
            return partyManager.partyMembers.contains { member in
                member.id == character.id && member.isConnected
            }
        } else {
            // 🆕 Игрок проверяет СОБСТВЕННОЕ состояние подключения
            if case .connected = partyManager.connectionState {
                return true
            }
            return false
        }
    }
    
    @EnvironmentObject var store: CharacterStore
    @State var character: DNDCharacter
    @State private var currentHP: Int
    @State private var selectedTab = 0
    @State private var showingMap = false
    @State private var showingMilestonePopup = false
    @State private var showingDemotePopup = false
    @State private var demotionRewards: [MilestoneReward] = []
    // 🆕 Состояния для drawer'а партии
    @State private var isDrawerOpen = false
    @State private var drawerDragOffset: CGFloat = 0
    @State private var selectedMember: PartyMember? = nil
    @State private var isDraggingHorizontally = false
    
    init(character: DNDCharacter) {
        self._character = State(initialValue: character)
        self._currentHP = State(initialValue: character.currentHP)
    }
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            
            ScrollView {
                
                VStack(spacing: 20) {
                    CharacterHeaderSection(
                        character: $character,
                        canEdit: canEditCharacter,
                        onLevelUp: { showingMilestonePopup = true }
                    )
                    .equatable()  // 🆕 ОПТИМИЗАЦИЯ
                    
                    HPSection(character: $character,
                               currentHP: $currentHP,
                              canEdit: canEditCharacter,
                              showEditBlockedAlert: $showEditBlockedAlert)
                    .equatable()  // 🆕 ОПТИМИЗАЦИЯ
                    
                    StressSection(character: $character, canEdit: canEditCharacter)
                    .equatable()  // 🆕 ОПТИМИЗАЦИЯ
                    
                    TabSection(character: $character, selectedTab: $selectedTab, canEdit: canEditCharacter)
                    .equatable()
                    
                    // 🆕 Кнопки отдыха (только в активной партии)
                    if case .connected = partyManager.connectionState {
                        VStack(spacing: 12) {
                            DSdivider()
                                .padding(.horizontal, 40)
                            
                            HStack(spacing: 12) {
                                // Короткий отдых
                                Button {
                                    SoundManager.shared.play(.equip, haptic: .medium)
                                    partyManager.initiateRestVote(type: .short, from: character)
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
                                    .foregroundColor(partyManager.gameRules.canShortRest ? Color.dsBackground : Color.dsTextDim)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(partyManager.gameRules.canShortRest ? Color.dsBlue : Color.dsSurfaceAlt)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .disabled(!partyManager.gameRules.canShortRest)
                                
                                // Долгий отдых
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
                                    .foregroundColor(partyManager.gameRules.canLongRest ? Color.dsBackground : Color.dsTextDim)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(partyManager.gameRules.canLongRest ? Color.dsGold : Color.dsSurfaceAlt)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                                .disabled(!partyManager.gameRules.canLongRest)
                            }
                            .padding(.horizontal, 16)
                            
                            Text("Доступно: \(partyManager.gameRules.shortRestsAvailable) коротких / \(partyManager.gameRules.longRestsAvailable) долгих")
                                .font(.system(size: 10))
                                .foregroundColor(Color.dsTextDim)
                                .padding(.top, 4)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .scrollDisabled(isDraggingHorizontally || isDrawerOpen)
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
                    
                    // 🆕 Drawer с профилями партии
            PartyMembersDrawer(
                isOpen: $isDrawerOpen,
                members: partyManager.partyMembers
            ) { member in
                selectedMember = member
                withAnimation(.spring(response: 0.4)) {
                    isDrawerOpen = false
                }
            }
            .offset(x: drawerDragOffset)  // 🆕 Следует за пальцем
            .allowsHitTesting(isDrawerOpen || drawerDragOffset < 0)  // 🆕 Активен при drag влево
            .zIndex(1000)
            
        }
        .navigationTitle(character.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // 🆕 Кнопка открытия drawer'а партии
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            isDrawerOpen.toggle()
                        }
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(Color.dsGold)
                                .font(.system(size: 16))
                            
                            if !partyManager.partyMembers.isEmpty {
                                Text("\(partyManager.partyMembers.count)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Color.dsBackground)
                                    .padding(3)
                                    .background(Color.dsGold)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                    
                    // Кнопка отката уровня
                    if character.level > 1 {
                        Button {
                            demotionRewards = MilestoneLibrary.rewards(for: character.level)
                            withAnimation(.spring(response: 0.4)) {
                                showingDemotePopup = true
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .foregroundColor(Color.dsRed.opacity(0.8))
                        }
                    }
                    
                    // Кнопка карты
                    Button(action: { showingMap = true }) {
                        Image(systemName: "map")
                            .foregroundColor(Color.dsGold)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMap) { MapView() }
        .overlay {
            // Popup повышения уровня
            if showingMilestonePopup {
                MilestonePopupView(
                    newMilestone: character.level + 1,
                    rewards: MilestoneLibrary.rewards(for: character.level + 1)
                ) {
                    character.levelUp()
                    currentHP = character.hitPoints
                    store.update(character)
                    showingMilestonePopup = false
                }
            }
            
            // ✅ НОВЫЙ Popup отката уровня
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
                
            }
        }
        // 🆕 Модальное окно с деталями выбранного игрока
        .sheet(item: $selectedMember) { member in
            NavigationStack {
                DungeonMasterDetailView(memberID: member.id)
                    .environmentObject(partyManager)  // 🆕 Передаём partyManager
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Закрыть") {
                                selectedMember = nil
                            }
                            .foregroundColor(Color.dsGold)
                        }
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .preferredColorScheme(.dark)
        // 🆕 Слушаем начало отдыха от ДМа
        .onChange(of: partyManager.connectionState) { oldState, newState in
            if case .connected = newState {
                // Проверяем не пришёл ли restStarted
                // Это обрабатывается в PartyManager.handle(message:)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)  // 🆕 Жест активируется только после 20px
                .onChanged { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    
                    // 🆕 Определяем: жест явно горизонтальный?
                    // +10px запас, чтобы случайные диагонали не блокировали скролл
                    let isHorizontalSwipe = abs(horizontal) > abs(vertical) + 10
                    
                    if isHorizontalSwipe {
                        isDraggingHorizontally = true  // 🛑 Останавливаем "эскалатор"
                    }
                    
                    // Логика drawer'а (только если жест горизонтальный)
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
                    
                    // Открытие/закрытие drawer'а
                    if !isDrawerOpen && isHorizontalSwipe && horizontal < -100 {
                        withAnimation(.spring(response: 0.4)) { isDrawerOpen = true }
                    } else if isDrawerOpen && isHorizontalSwipe && horizontal > 100 {
                        withAnimation(.spring(response: 0.4)) { isDrawerOpen = false }
                    }
                    
                    // Сброс
                    withAnimation(.spring(response: 0.4)) { drawerDragOffset = 0 }
                    isDraggingHorizontally = false  // ✅ Включаем "эскалатор" обратно
                }
        )
        
        .alert(
            partyManager.lastError != nil ? "Отключение от партии" : "Редактирование заблокировано",
            isPresented: $showEditBlockedAlert
        ) {
            Button("OK", role: .cancel) {
                partyManager.clearError()
                partyManager.clearDisconnectReason()
            }
        } message: {
            if let error = partyManager.lastError {
                Text(error)
            } else if let reason = partyManager.disconnectReason {
                Text(reason)
            } else {
                Text("Мастер запретил изменять героев вне активной партии.\nПодключитесь к ДМ, чтобы вносить изменения.")
            }
        }
        // 🆕 Overlay голосования за отдых
        .overlay {
            if let voteSession = partyManager.activeRestVote {
                RestVoteOverlayView(
                    session: voteSession,
                    myVoteSent: partyManager.myVoteSent,
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
        // 🆕 Overlay эффекта отдыха (анимация исцеления)
        .overlay {
            if let effect = partyManager.activeRestEffect {
                RestEffectOverlayView(effect: effect) {
                    // Сбрасываем триггер после анимации
                    partyManager.activeRestEffect = nil
                }
                .zIndex(10000)
            }
        }
        // 🆕 Применяем эффект отдыха к персонажу
        .onChange(of: partyManager.activeRestEffect) { _, newEffect in
            guard let effect = newEffect else { return }
            
            // Применяем эффект только к своему персонажу (в роли игрока)
            if partyManager.role == .player {
                partyManager.applyRestEffect(
                    to: character,
                    type: effect.restType,
                    store: store
                )
            }
        }
        .onChange(of: character.currentHP) { _, newValue in
                if currentHP != newValue {
                    currentHP = newValue
                }
            }
        // 🆕 Автоматически закрываем drawer при потере связи с ДМом
        .onChange(of: partyManager.connectionState) { _, newState in
            if case .disconnected = newState {
                // 🆕 Закрываем drawer
                if isDrawerOpen {
                    withAnimation(.spring(response: 0.4)) {
                        isDrawerOpen = false
                    }
                }
                
                // 🆕 Показываем alert о потере связи
                if partyManager.lastError != nil {
                    showEditBlockedAlert = true  // Переиспользуем существующий alert
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
}

