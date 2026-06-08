//
//  CharacterHeaderSection.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI
import PhotosUI

struct CharacterHeaderSection: View, Equatable {
    @Binding var character: DNDCharacter
    @Binding var currentHP: Int  // 🆕 Добавлено для performDemotion
    let canEdit: Bool
    let onLevelUp: () -> Void
    @EnvironmentObject var store: CharacterStore  // 🆕 Добавлено для performDemotion
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showingDemotePopup = false  // 🆕 Заменило showLevelDownConfirmation
    @State private var demotionRewards: [MilestoneReward] = []  // 🆕 Добавлено
    
    static func == (lhs: CharacterHeaderSection, rhs: CharacterHeaderSection) -> Bool {
        lhs.character.name == rhs.character.name &&
        lhs.character.race == rhs.character.race &&
        lhs.character.characterClass == rhs.character.characterClass &&
        lhs.character.level == rhs.character.level &&
        lhs.character.instrument == rhs.character.instrument &&
        lhs.character.alignment == rhs.character.alignment &&
        lhs.character.avatarData == rhs.character.avatarData &&
        lhs.canEdit == rhs.canEdit
    }
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                // СЛЕВА: Большой аватар с кнопкой камеры
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        avatarData: character.avatarData,
                        race: character.race,
                        size: 120
                    )
                    
                    if canEdit {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showPhotoPicker = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.dsBackground)
                                .frame(width: 32, height: 32)
                                .background(Color.dsGold)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.dsBackground, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: 6)
                    }
                }
                
                // ПОСЕРЕДИНЕ: Имя, бейджи, мировоззрение
                VStack(alignment: .leading, spacing: 8) {
                    Text(character.displayName.uppercased())
                        .font(.system(size: 20, weight: .light))
                        .tracking(3)
                        .foregroundColor(Color.dsGold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            badgeViews
                        }
                        
                        FlowLayout(spacing: 6) {
                            badgeViews
                        }
                    }
                    
                    Text(character.alignment.rawValue.uppercased())
                        .font(.system(size: 10))
                        .tracking(2)
                        .foregroundColor(Color.dsTextDim)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // СПРАВА: Кнопки вехи (повышение + понижение)
                VStack(spacing: 8) {
                    // Кнопка ПОВЫШЕНИЯ вехи
                    if !character.isMaxLevel {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.4)) {
                                onLevelUp()
                            }
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.up.forward.circle.fill")
                                    .font(.system(size: 22))
                                
                                Text("Веха")
                                    .font(.system(size: 9, weight: .medium))
                                    .tracking(0.5)
                            }
                            .foregroundColor(canEdit ? Color.dsBackground : Color.dsTextDim)
                            .frame(width: 58, height: 58)
                            .background(canEdit ? Color.dsGold : Color.dsSurfaceAlt)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(canEdit ? Color.dsGold.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canEdit)
                    }
                    
                    // 🆕 Кнопка ОТКАТА (перенесена из CharacterSheetView)
                    if character.level > 1 {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            demotionRewards = MilestoneLibrary.rewards(for: character.level)
                            withAnimation(.spring(response: 0.4)) {
                                showingDemotePopup = true
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .font(.system(size: 28))
                                .foregroundColor(canEdit ? Color.dsRed.opacity(0.8) : Color.dsTextDim)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canEdit)
                    }
                    
                    // Замок если нельзя редактировать
                    if !canEdit && (character.level > 1 || !character.isMaxLevel) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.dsTextDim)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            DSdivider().padding(.horizontal, 30)
        }
        .padding(.top, 16)
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await loadSelectedPhoto(newItem)
            }
        }
        // 🆕 Popup отката уровня (перенесён из CharacterSheetView)
        .overlay {
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
                .zIndex(1000)
            }
        }
    }
    
    // MARK: - 🆕 Откат уровня (перенесён из CharacterSheetView)
    
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
    
    // MARK: - Бейджи
    
    @ViewBuilder
    private var badgeViews: some View {
        DSBadge(text: character.race.rawValue, color: .dsBlue)
        DSBadge(text: character.characterClass.rawValue, color: .dsGoldDim)
        DSBadge(text: "ВЕХА \(character.level)", color: .dsRed)
        
        if let instrumentName = character.instrument,
           let type = InstrumentType.from(name: instrumentName) {
            HStack(spacing: 4) {
                Image(systemName: type.sfSymbol)
                    .font(.system(size: 9))
                Text(instrumentName)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(type.accentColor.opacity(0.12))
            .foregroundColor(type.accentColor)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(type.accentColor.opacity(0.3), lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Загрузка выбранного фото
    
    private func loadSelectedPhoto(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                #if os(iOS)
                if let uiImage = UIImage(data: data) {
                    let compressedData = compressImage(uiImage, maxSize: 512)
                    await MainActor.run {
                        character.avatarData = compressedData
                    }
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: data) {
                    let compressedData = compressImage(nsImage, maxSize: 512)
                    await MainActor.run {
                        character.avatarData = compressedData
                    }
                }
                #endif
            }
        } catch {
            print("⚠️ Ошибка загрузки фото: \(error)")
        }
    }
    
    // MARK: - Сжатие изображения
    
    #if os(iOS)
    private func compressImage(_ image: UIImage, maxSize: CGFloat) -> Data? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage.jpegData(compressionQuality: 0.7)
    }
    #elseif os(macOS)
    private func compressImage(_ image: NSImage, maxSize: CGFloat) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        let size = bitmap.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        bitmap.draw(in: CGRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        guard let resizedTiffData = resizedImage.tiffRepresentation,
              let resizedBitmap = NSBitmapImageRep(data: resizedTiffData) else {
            return nil
        }
        
        return resizedBitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
    #endif
}

// MARK: - FlowLayout для переноса бейджей на несколько строк

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + result.frames[index].minX,
                y: bounds.minY + result.frames[index].minY
            )
            subview.place(at: point, anchor: .topLeading, proposal: proposal)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (frames: [CGRect], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            let frame = CGRect(x: currentX, y: currentY, width: size.width, height: size.height)
            frames.append(frame)
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxX = max(maxX, currentX)
        }
        
        let totalHeight = currentY + lineHeight
        return (frames, CGSize(width: maxX, height: totalHeight))
    }
}
