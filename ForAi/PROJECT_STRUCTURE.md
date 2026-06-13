Clarity/
├── 📄 ClarityApp.swift                      # Точка входа приложения
├── 📄 RootView.swift                        # Корневой view (навигация)
├── 📄 Clarity-Info.plist                    # Конфигурация приложения
├── 📄 Clarity.xcodeproj/                    # Xcode проект
│
├── 🎨 Theme/                                # Дизайн-система Dark Souls стиля
│   ├── DSColors.swift                       # Цветовая палитра (dsGold, dsRed)
│   ├── DSModifiers.swift                    # Кастомные ViewModifier'ы
│   ├── View+CornerRadius.swift              # Расширения для скруглений
│   └── Components/                          # Переиспользуемые UI компоненты
│       ├── CornerOrnaments.swift            # Декоративные углы
│       ├── DSdivider.swift                  # Разделители
│       └── DSSectionHeader.swift            # Заголовки секций
│
├── 👁️ Views/                                # UI слой (SwiftUI)
│   ├── ContentView.swift                    # Главный контейнер
│   ├── CharacterInfoView.swift              # Просмотр инфо о персонаже
│   │
│   ├── 🎭 Party/                            # Мультиплеер и партии
│   │   ├── PartyLobbyView.swift             # Главное лобби
│   │   ├── DungeonMasterView.swift          # UI для ДМа
│   │   ├── DungeonMasterDetailView.swift    # Детали игрока (ДМ)
│   │   ├── PartyStatusIndicator.swift       # Индикатор подключения
│   │   ├── RestVoteOverlayView.swift        # Оверлей голосования за отдых
│   │   ├── RestEffectOverlayView.swift      # Оверлей эффекта отдыха
│   │   │
│   │   ├── DMComponents/                    # Компоненты для ДМа
│   │   │   ├── CampaignSelectionView.swift  # Выбор кампании
│   │   │   ├── DBasicInfoSection.swift      # Базовая инфа игрока
│   │   │   ├── DMDetailHeader.swift         # Шапка деталей
│   │   │   └── DMSections/
│   │   │       ├── DMStatsSection.swift     # Статы игрока
│   │   │       ├── DMSkillsSection.swift    # Навыки игрока
│   │   │       └── DMInventorySection.swift # Инвентарь игрока
│   │   │
│   │   └── LobbyComponents/                 # Компоненты лобби
│   │       ├── RoleSelectionView.swift      # Выбор роли (ДМ/Игрок)
│   │       ├── PlayerFlowView.swift         # ⭐ Выбор персонажа (игрок)
│   │       ├── HostingView.swift            # UI хостинга (ДМ)
│   │       ├── SearchingView.swift          # UI поиска (Игрок)
│   │       ├── ConnectingView.swift       # Процесс подключения
│   │       ├── ConnectedView.swift          # Успешное подключение
│   │       └── RulesConfigurationView.swift # Настройка правил
│   │
│   ├── 🎴 CharacterCreation/                # Создание персонажа
│   │   ├── CharacterCreationView.swift      # Главный wizard
│   │   ├── Steps/                           # Шаги создания
│   │   │   ├── NameStepView.swift
│   │   │   ├── RaceStepView.swift
│   │   │   ├── ClassStepView.swift
│   │   │   └── StatsStepView.swift
│   │   └── Components/
│   │       ├── RaceCard.swift
│   │       └── PointBuyRow.swift
│   │
│   ├── 📋 CharacterSheet/                   # Лист персонажа
│   │   ├── CharacterSheetView.swift         # Главный экран
│   │   ├── PreviewHelper.swift              # Превью для SwiftUI
│   │   ├── Sections/                        # Секции листа
│   │   │   ├── CharacterHeaderSection.swift
│   │   │   ├── HPSection.swift              # Хиты
│   │   │   ├── HPHistorySheet.swift         # История изменений HP
│   │   │   ├── PartyMembersDrawer.swift     # Боковая панель партии
│   │   │   └── TabSection.swift
│   │   ├── Stats/
│   │   │   ├── StatsTabView.swift
│   │   │   ├── DSCombatStatsView.swift
│   │   │   └── DSStatCard.swift
│   │   ├── Skills/SkillsTabView.swift
│   │   ├── Inventory/
│   │   │   ├── InventoryTabView.swift
│   │   │   ├── InventoryItemRow.swift
│   │   │   └── ItemEditorView.swift
│   │   ├── Equipment/                       # Экипировка (пусто?)
│   │   ├── Stress/StressTrackerView.swift
│   │   ├── InstrumentMods/                  # Модификации инструментов (бард)
│   │   │   ├── InstrumentModsTabView.swift
│   │   │   ├── InstrumentModSlotView.swift
│   │   │   ├── InstrumentModPickerView.swift
│   │   │   └── InstrumentModHeader.swift
│   │   └── Components/
│   │       ├── MilestonePopupView.swift
│   │       └── DemotionPopupView.swift
│   │
│   ├── 🗺️ Map/                              # Карта мира
│   │   ├── MapView.swift
│   │   └── ZoomedLocationView.swift
│   │
│   ├── 🃏 Tarot/                            # Карты Таро
│   │   ├── TarotTabView.swift
│   │   ├── TarotCardView.swift
│   │   └── TarotCardEditorView.swift
│   │
│   └── 🔧 Shared/                           # Общие компоненты
│       ├── AvatarView.swift                 # Аватар персонажа
│       ├── DSHPButton.swift                 # Кнопка HP
│       ├── DSBadge.swift                    # Бейджи
│       ├── StatRow.swift, InfoRow.swift     # Строки данных
│       ├── RuleToggle.swift                 # Переключатель правил
│       ├── PartyMemberRow.swift             # Строка участника
│       ├── SkeletonLoader.swift             # Скелетоны загрузки
│       ├── SkeletonCharacterRow.swift
│       ├── SparkleEffect.swift              # Эффект искр
│       ├── LockedComponents.swift           # Заблокированные UI
│       ├── IconHelper.swift                 # Помощник иконок
│       └── DatabaseRecoveryView.swift       # UI восстановления БД
│
├── ⚙️ Core/                                 # Бизнес-логика
│   │
│   ├── 📦 Models/                           # Модели данных (SwiftData)
│   │   ├── DNDCharacter.swift               # ⭐ ГЛАВНАЯ модель персонажа
│   │   ├── AbilityScores.swift              # Характеристики (STR, DEX...)
│   │   ├── Campaign.swift                   # Модель кампании
│   │   ├── CharacterClass.swift             # Классы (fighter, bard...)
│   │   ├── ClassProficiencies.swift         # Владение классами
│   │   ├── DNDAlignment.swift               # Мировоззрение
│   │   ├── EquipmentSlot.swift              # Слоты экипировки
│   │   ├── HPChange.swift                   # Запись изменения HP
│   │   ├── InstrumentType.swift             # Типы инструментов
│   │   ├── InstrumentModification.swift     # Модификации
│   │   ├── InstrumentModificationLibrary.swift
│   │   ├── InstrumentModificationSlot.swift
│   │   ├── InventoryItem.swift              # Предмет инвентаря
│   │   ├── MapLocation.swift                # Локация на карте
│   │   ├── Race.swift                       # Расы
│   │   └── TarotCard.swift                  # Карта таро
│   │
│   ├── 🎉 Party/                            # Логика партии
│   │   ├── PartyManager.swift               # ⭐ ГЛАВНЫЙ менеджер (Singleton)
│   │   ├── PartyManager+Connection.swift    # MC делегаты (подключение)
│   │   ├── PartyManager+Messages.swift      # Сетевые сообщения
│   │   ├── PartyManager+Persistence.swift 
│   │   ├── CampaignManager.swift            # ⭐ Менеджер кампаний
│   │   ├── PartyMember.swift                # Участник партии
│   │   ├── PartyMessage.swift               # Типы сообщений
│   │   ├── RestVotingManager.swift          # Голосование за отдых
│   │   └── GameRules.swift                  # Правила игры
│   │
│   ├── 📊 CharacterStore.swift              # ⭐ SwiftData store персонажей
│   ├── 📚 Constants.swift                   # Константы приложения
│   ├── 🎵 SoundManager.swift                # Звуки
│   ├── 🏆 MilestoneLibrary.swift            # Библиотека достижений
│   └── 🛠️ DatabaseRecovery.swift            # Восстановление БД
│
├── 🔨 Utils/                                # Утилиты
│   ├── PlatformCompatibility.swift          # iOS/macOS совместимость
│   └── ImageCompressor.swift                # Сжатие изображений
│
├── 🎵 Resources/
│   └── Sounds/                              # Звуковые файлы
│
├── 🤖 ForAi/                                # Документация для ИИ
│   ├── PROJECT_STRUCTURE.md
│   └── TODO.md
│
└── 🧪 ClarityTests/                         # Unit тесты
    ├── ClarityTests.swift
    ├── AbilityScoresTests.swift
    ├── ConstantsTests.swift
    ├── DNDCharacterTests.swift
    ├── GameRulesTests.swift
    ├── InventoryItemTests.swift
    ├── PartyMemberTests.swift
    └── TarotCardTests.swift
