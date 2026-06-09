Структура проекта ClarityDND 

Описание: SwiftUI-приложение для управления D&D персонажами с локальным мультиплеером (MultipeerConnectivity). Поддерживает iOS (iPhone/iPad) и macOS.
Clarity/
├── 🚀 КОРНЕВЫЕ ФАЙЛЫ
├── AppRootView.swift                      # Корневая навигация: меню → создание → игра
├── Clarity-Info.plist                     # Конфигурация iOS/macOS (permissions, capabilities)
├── Clarity.xcodeproj                      # Конфигурация Xcode проекта
├── ClarityApp.swift                       # 🚀 Точка входа (@main): создаёт CharacterStore, PartyManager
│
├── ⚙️ Core/                               # БИЗНЕС-ЛОГИКА (ядро приложения)
│   ├── Assets.xcassets                    # 🖼️ Изображения, цвета, иконки
│   ├── CharacterStore.swift               # 🗄️ ObservableObject: хранилище персонажей (CRUD + JSON)
│   ├── Constants.swift                    # 🔢 Глобальные константы приложения
│   ├── DatabaseRecovery.swift             # 🔄 Восстановление данных при сбоях БД
│   ├── MilestoneLibrary.swift             # 🎯 Библиотека вех (level up награды по уровням)
│   ├── SoundManager.swift                 # 🔊 Звуки + haptic feedback (singleton)
│   │
│   ├── 📦 Models/                         # МОДЕЛИ ДАННЫХ
│   │   ├── AbilityScores.swift            # 💪 STR, DEX, CON, INT, WIS, CHA
│   │   ├── CharacterClass.swift           # 🗡️ Enum классов (fighter, wizard, rogue, ...)
│   │   ├── ClassProficiencies.swift       # 🎯 Владения класса (оружие, броня, навыки)
│   │   ├── DNDAlignment.swift             # ⚖️ Мировоззрение (lawful good, chaotic evil, ...)
│   │   ├── DNDCharacter.swift             # 🎭 ГЛАВНАЯ МОДЕЛЬ (ObservableObject): HP, level, inventory
│   │   ├── EquipmentSlot.swift            # 🛡️ Слоты экипировки
│   │   ├── HPChange.swift                 # ❤️ Изменения HP (лечение/урон)
│   │   ├── InstrumentModification.swift   # 🔧 Модификации инструментов
│   │   ├── InstrumentModificationLibrary.swift  # Библиотека модификаций
│   │   ├── InstrumentModificationSlot.swift     # Слоты модификаций
│   │   ├── InstrumentType.swift           # 🎸 Типы инструментов (lute, drum, ...)
│   │   ├── InventoryItem.swift            # 🎒 Предметы инвентаря
│   │   ├── MapLocation.swift              # 🗺️ Локации на карте мира
│   │   ├── Race.swift                     # 👤 Enum рас (human, elf, dwarf, ...)
│   │   └── TarotCard.swift                # 🃏 Карты таро (игровая механика)
│   │
│   └── 🎲 Party/                          # МУЛЬТИПЛЕЕР (MultipeerConnectivity)
│       ├── GameRules.swift                # 📜 Правила игры (canShortRest, canLongRest)
│       ├── PartyManager.swift             # 👑 Singleton-менеджер: @Published partyMembers, connectionState
│       │                                    #   Throttling: basicSync=0.3s, broadcast=0.5s
│       │                                    #   Heartbeat таймеры, lastUpdateTime для версионирования
│       ├── PartyManager+Connection.swift  # 🌐 MCSessionDelegate + Advertiser/Browser delegates
│       │                                    #   handlePeerConnected/Disconnected, heartbeat
│       ├── PartyManager+Messages.swift    # 📨 Обработка сообщений: handleCharacterUpdated,
│       │                                    #   syncBasic (debounce), forceSyncBasic, broadcastPartyList
│       ├── PartyManager+Persistence.swift # 💾 savePartyState/loadPartyState (UserDefaults)
│       ├── PartyMember.swift              # 👥 struct: id, peerID, currentHP, maxHP, isConnected
│       ├── PartyMessage.swift             # 📦 Enum Codable: playerJoined, characterUpdated,
│       │                                    #   partyList, restVote*, heartbeat*, hostStopped
│       └── RestVotingManager.swift        # 🗳️ Логика голосования за отдых (RestVoteSession)
│
├── 🤖 ForAi/                              # ДОКУМЕНТАЦИЯ ДЛЯ ИИ-АССИСТЕНТОВ
│   ├── PROJECT_STRUCTURE.md               # Описание архитектуры проекта
│   └── TODO.md                            # Задачи и планы развития
│
├── 🔊 Resources/
│   └── Sounds/                            # Звуковые эффекты (.wav)
│
├── 🎨 Theme/                              # ДИЗАЙН-СИСТЕМА (Design System)
│   ├── DSColors.swift                     # Палитра: dsGold, dsRed, dsBackground, ...
│   ├── DSModifiers.swift                  # View-модификаторы (кнопки, карточки, тени)
│   └── Components/                        # Переиспользуемые UI-компоненты темы
│       ├── CornerOrnaments.swift          # Декоративные уголки в стиле D&D
│       ├── DSdivider.swift                # Разделители
│       └── DSSectionHeader.swift          # Заголовки секций
│
├── 🛠️ Utils/                              # ВСПОМОГАТЕЛЬНЫЕ УТИЛИТЫ
│   ├── ImageCompressor.swift              # 🖼️ Сжатие изображений (для аватаров)
│   └── PlatformCompatibility.swift        # 📱 Абстракция различий iOS/macOS
│
├── 🖼️ Views/                              # ПОЛЬЗОВАТЕЛЬСКИЙ ИНТЕРФЕЙС (SwiftUI)
│   ├── ContentView.swift                  # Главный View (роутинг)
│   │
│   ├── ✨ CharacterCreation/              # СОЗДАНИЕ ПЕРСОНАЖА (wizard)
│   │   ├── CharacterCreationView.swift    # Главный View создания
│   │   ├── Components/
│   │   │   ├── PointBuyRow.swift          # Point buy система распределения очков
│   │   │   └── RaceCard.swift             # Карточка расы для выбора
│   │   └── Steps/                         # Шаги мастера создания
│   │       ├── ClassStepView.swift        # Выбор класса
│   │       ├── NameStepView.swift         # Ввод имени
│   │       ├── RaceStepView.swift         # Выбор расы
│   │       └── StatsStepView.swift        # Распределение характеристик
│   │
│   ├── 📋 CharacterSheet/                 # ЛИСТ ПЕРСОНАЖА
│   │   ├── CharacterSheetView.swift       # Главный View листа
│   │   ├── Components/                    # Popup-компоненты
│   │   │   ├── DemotionPopupView.swift    # 📉 Popup понижения вехи
│   │   │   └── MilestonePopupView.swift   # 🎉 Popup повышения вехи
│   │   ├── Equipment/
│   │   │   └── EquipmentPanel.swift       # 🛡️ Панель экипировки
│   │   ├── InstrumentMods/                # 🎸 Модификации инструментов
│   │   │   ├── InstrumentModHeader.swift  # Шапка модификации
│   │   │   ├── InstrumentModPickerView.swift  # Выбор модификации
│   │   │   ├── InstrumentModSlotView.swift    # Слот модификации
│   │   │   └── InstrumentModsTabView.swift    # Вкладка модификаций
│   │   ├── Inventory/                     # 🎒 Инвентарь
│   │   │   ├── InventoryItemRow.swift     # Строка предмета
│   │   │   ├── InventoryTabView.swift     # Вкладка инвентаря
│   │   │   └── ItemEditorView.swift       # Редактор предмета
│   │   ├── Sections/                      # Секции листа
│   │   │   ├── CharacterHeaderSection.swift  # Шапка (имя, раса, класс, уровень)
│   │   │   ├── HPHistorySheet.swift       # История изменений HP
│   │   │   ├── HPSection.swift            # Секция HP (кнопки +/-)
│   │   │   ├── PartyMembersDrawer.swift   # 🎯 Drawer с членами партии (@Published)
│   │   │   └── TabSection.swift           # Переключение вкладок
│   │   ├── Skills/
│   │   │   └── SkillsTabView.swift        # 🎯 Вкладка навыков
│   │   ├── Stats/                         # 💪 Характеристики
│   │   │   ├── DSCombatStatsView.swift    # Боевые характеристики
│   │   │   ├── DSStatCard.swift           # Карточка характеристики
│   │   │   └── StatsTabView.swift         # Вкладка характеристик
│   │   └── Stress/
│   │       └── StressTrackerView.swift    # 😰 Трекер стресса
│   │
│   ├── 🗺️ Map/                            # КАРТА МИРА
│   │   ├── MapView.swift                  # Главная карта
│   │   └── ZoomedLocationView.swift       # Детали локации при зуме
│   │
│   ├── 🎲 Party/                          # МУЛЬТИПЛЕЕР UI
│   │   ├── DungeonMasterDetailView.swift  # Детали игрока для ДМ-а
│   │   ├── DungeonMasterView.swift        # 👑 View для ДМ-а
│   │   ├── PartyLobbyView.swift           # 🚪 Лобби партии (выбор роли)
│   │   ├── PartyStatusIndicator.swift     # 📶 Индикатор подключения
│   │   ├── RestEffectOverlayView.swift    # 💤 Overlay эффекта отдыха
│   │   ├── RestVoteOverlayView.swift      # 🗳️ Overlay голосования за отдых
│   │   ├── DMComponents/                  # Компоненты для ДМ-а
│   │   │   ├── DMBasicInfoSection.swift   # Базовая информация об игроке
│   │   │   ├── DMDetailHeader.swift       # Шапка деталей игрока
│   │   │   └── DMSections/
│   │   │       ├── DMInventorySection.swift  # Инвентарь игрока (для ДМ)
│   │   │       ├── DMSkillsSection.swift     # Навыки игрока (для ДМ)
│   │   │       └── DMStatsSection.swift      # Характеристики игрока (для ДМ)
│   │   └── LobbyComponents/               # Компоненты лобби
│   │       ├── ConnectedView.swift        # Состояние: подключено
│   │       ├── ConnectingView.swift       # Состояние: подключение
│   │       ├── HostingView.swift          # ДМ создаёт комнату
│   │       ├── PlayerFlowView.swift       # Поток игрока
│   │       ├── RoleSelectionView.swift    # Выбор роли (ДМ/Игрок)
│   │       ├── RulesConfigurationView.swift  # Настройка правил
│   │       └── SearchingView.swift        # Игрок ищет комнату
│   │
│   ├── 🔗 Shared/                         # ОБЩИЕ КОМПОНЕНТЫ (используются везде)
│   │   ├── AvatarView.swift               # 👤 Аватар персонажа
│   │   ├── DatabaseRecoveryView.swift     # View восстановления БД
│   │   ├── DSBadge.swift                  # 🏷️ Бейджи
│   │   ├── DSHPButton.swift               # ❤️ Кнопка HP (+/-) — триггерит syncBasic
│   │   ├── IconHelper.swift               # 🎨 Помощник иконок
│   │   ├── InfoRow.swift                  # ℹ️ Информационная строка
│   │   ├── LockedComponents.swift         # 🔒 Заблокированные компоненты
│   │   ├── PartyMemberRow.swift           # 👥 Строка члена партии (для drawer)
│   │   ├── RuleToggle.swift               # ⚙️ Переключатель правил
│   │   ├── SkeletonCharacterRow.swift     # Скелетон строки персонажа
│   │   ├── SkeletonLoader.swift           # 💀 Скелетон-загрузчики
│   │   ├── SparkleEffect.swift            # ✨ Эффект искр (level up)
│   │   └── StatRow.swift                  # 📊 Строка характеристики
│   │
│   └── 🃏 Tarot/                          # МЕХАНИКА ТАРО
│       ├── TarotCardEditorView.swift      # Редактор карты
│       ├── TarotCardView.swift            # Просмотр карты
│       └── TarotTabView.swift             # Вкладка таро
│
└── 🧪 ClarityTests/                       # UNIT-ТЕСТЫ
    ├── AbilityScoresTests.swift           # Тесты характеристик
    ├── ClarityTests.swift                 # Базовые тесты приложения
    ├── ConstantsTests.swift               # Тесты констант
    ├── DNDCharacterTests.swift            # Тесты модели персонажа
    ├── GameRulesTests.swift               # Тесты правил игры
    ├── InventoryItemTests.swift           # Тесты инвентаря
    ├── PartyMemberTests.swift             # Тесты члена партии
    └── TarotCardTests.swift               # Тесты таро
