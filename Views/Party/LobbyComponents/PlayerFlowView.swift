//
// PlayerFlowView.swift
// Clarity
//
import SwiftData
import SwiftUI

struct PlayerFlowView: View {

    // MARK: - Свойства

    @ObservedObject var partyManager: PartyManager
    @EnvironmentObject var store: CharacterStore

    @State private var isLoadingCharacters = true

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {

            // Заголовок
            VStack(spacing: 8) {
                Text("🗡️").font(.system(size: 40))
                Text("ВЫБЕРИТЕ ГЕРОЯ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Text("Кто отправится в путь?")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color.dsGold)
            }
            .padding(.top, 10)

            DSdivider().padding(.horizontal, 40)

            // Список персонажей или пустое состояние
            // 🆕 ФИЛЬТРУЕМ: показываем только НЕ удалённых персонажей
            let activeCharacters = store.characters.filter { !$0.isDeleted }

            // Список персонажей или пустое состояние
            if isLoadingCharacters {
                loadingState
            } else if activeCharacters.isEmpty {
                emptyState
            } else {
                characterList
            }

            Spacer()

            // ✅ Кнопка "Найти партию" (появляется только когда выбран персонаж)
            if !isLoadingCharacters && partyManager.selectedCharacter != nil {
                Button {
                    guard let char = partyManager.selectedCharacter else { return }

                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    #endif

                    partyManager.startSearching(with: char)

                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("НАЙТИ ПАРТИЮ")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                    }
                    .foregroundColor(Color.dsBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dsGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            } else if !isLoadingCharacters {
                Text("Выберите героя, чтобы подключиться")
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsTextDim)
            }

            // ✅ КРИТИЧНО: Кнопка "Отмена" ВСЕГДА видна (вне условных блоков!)
            Button {
                #if os(iOS)
                PlatformCompatibility.hapticImpact(.light)
                #endif

                // Возвращаемся к выбору роли
                partyManager.connectionState = .disconnected

            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Отмена")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color.dsRed)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.dsRed.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
        .onAppear {
            // Небольшая задержка для плавной анимации появления
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoadingCharacters = false
                }
            }
        }
    }

    // MARK: - Секции UI

    private var loadingState: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonCharacterRow()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color.dsTextDim.opacity(0.5))
            Text("У вас нет персонажей")
                .font(.system(size: 14))
                .foregroundColor(Color.dsText)
            Text("Создайте героя в Книге Судеб,\nчтобы присоединиться к партии")
                .font(.system(size: 11))
                .foregroundColor(Color.dsTextDim)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }

    private var characterList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(store.characters.filter { !$0.isDeleted }) { char in
                    Button {
                        #if os(iOS)
                        PlatformCompatibility.hapticImpact(.light)
                        #endif

                        // Устанавливаем выбранного персонажа в PartyManager
                        partyManager.setSelectedCharacter(char)

                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(
                                avatarData: char.avatarData,
                                race: char.race,
                                size: 48
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(char.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.dsText)
                                Text("\(char.race.rawValue) · \(char.characterClass.rawValue) · Веха \(char.level)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.dsTextDim)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.dsRed)
                                    Text("\(char.currentHP)/\(char.hitPoints)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(char.hpColor)
                                }

                                // Галочка выбранного персонажа
                                if partyManager.selectedCharacter?.id == char.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.dsGold)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(Color.dsTextDim.opacity(0.5))
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            partyManager.selectedCharacter?.id == char.id
                            ? Color.dsGold.opacity(0.1)
                            : Color.dsSurfaceAlt
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    partyManager.selectedCharacter?.id == char.id
                                    ? Color.dsGold
                                    : Color.dsBorder,
                                    lineWidth: partyManager.selectedCharacter?.id == char.id ? 1.5 : 0.5
                                )
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PartyLobbyView()
        .environmentObject(CharacterStore(context: ModelContext(try! ModelContainer(for: DNDCharacter.self))))
        .preferredColorScheme(.dark)
}
