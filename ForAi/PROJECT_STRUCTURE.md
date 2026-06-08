Clarity/
│
├── 🎯 КОРНЕВЫЕ ФАЙЛЫ
│   ├── Clarity.xcodeproj          # Проект Xcode
│   ├── Clarity-Info.plist         # Конфигурация приложения
│   ├── ClarityApp.swift           # Точка входа (@main)
│   └── AppRootView.swift          # Корневой View
│
├── 📂 Resources/                  # Ресурсы приложения
│   └── 📂 Sounds/                 # 🎵 Звуковые эффекты
│
├── 📂 ForAi/                      # 🤖 Документация для AI
│   ├── PROJECT_STRUCTURE.md       # Структура проекта
│   └── TODO.md                    # Список задач
│
├── 🎨 Theme/                      # Дизайн-система (Dark Souls стиль)
│   ├── DSColors.swift             # Палитра цветов
│   ├── DSModifiers.swift          # ViewModifiers
│   └── 📂 Components/             # Переиспользуемые UI-компоненты
│       ├── CornerOrnaments.swift  # Декоративные углы
│       ├── DSSectionHeader.swift  # Заголовки секций
│       └── DSdivider.swift        # Разделители
│
├── 👁️ Views/                      # Все экраны приложения
│   ├── ContentView.swift          # Главный контейнер
│   │
│   ├── 📂 Party/                  # 🎲 Мультиплеер (MultipeerConnectivity)
│   │   ├── PartyLobbyView.swift           # Лобби подключения
│   │   ├── DungeonMasterView.swift        # Экран Мастера
│   │   ├── DungeonMasterDetailView.swift  # Детальный профиль игрока
│   │   ├── PartyStatusIndicator.swift     # Индикатор "В партии"
│   │   ├── RestVoteOverlayView.swift      # Плашка голосования за отдых
│   │   └── RestEffectOverlayView.swift    # Анимация эффекта отдыха
│   │
│   ├── 📂 Map/                    # 🗺️ Карта мира
│   │   ├── MapView.swift                  # Основная карта
│   │   └── ZoomedLocationView.swift       # Детальный вид локации
│   │
│   ├── 📂 Tarot/                  # 🃏 Карты Таро
│   │   ├── TarotTabView.swift             # Вкладка таро
│   │   ├── TarotCardView.swift            # Отображение карты
│   │   └── TarotCardEditorView.swift      # Редактор карты
│   │
│   ├── 📂 CharacterSheet/         # 📜 Лист персонажа (главный экран)
│   │   ├── CharacterSheetView.swift       # Основной View
│   │   │
│   │   ├── 📂 Sections/           # Секции листа
│   │   │   ├── CharacterHeaderSection.swift   # Шапка (имя, класс, аватар)
│   │   │   ├── HPSection.swift                # Здоровье (+ StressSection wrapper)
│   │   │   ├── TabSection.swift               # Табы навигации
│   │   │   └── PartyMembersDrawer.swift       # Выезжающая панель партии
│   │   │
│   │   ├── 📂 Stats/              # 🎯 Характеристики
│   │   │   ├── StatsTabView.swift             # Вкладка характеристик
│   │   │   ├── DSStatCard.swift               # Карточка стата
│   │   │   └── DSCombatStatsView.swift        # Боевые статы
│   │   │
│   │   ├── 📂 Skills/             # ⚔️ Навыки
│   │   │   └── SkillsTabView.swift
│   │   │
│   │   ├── 📂 Inventory/          # 🎒 Инвентарь
│   │   │   ├── InventoryTabView.swift         # Вкладка инвентаря
│   │   │   ├── InventoryItemRow.swift         # Строка предмета
│   │   │   └── ItemEditorView.swift           # Редактор предмета
│   │   │
│   │   ├── 📂 Equipment/          # 🛡️ Экипировка
│   │   │   └── EquipmentPanel.swift
│   │   │
│   │   ├── 📂 Stress/             # 😰 Стресс
│   │   │   └── StressTrackerView.swift
│   │   │
│   │   ├── 📂 InstrumentMods/     # 🎸 Модификации инструментов
│   │   │   ├── InstrumentModsTabView.swift
│   │   │   ├── InstrumentModSlotView.swift
│   │   │   ├── InstrumentModPickerView.swift
│   │   │   └── InstrumentModHeader.swift
│   │   │
│   │   └── 📂 Components/         # Вспомогательные компоненты
│   │       ├── MilestonePopupView.swift       # Popup повышения уровня
│   │       └── DemotionPopupView.swift        # Popup отката уровня
│   │
│   ├── 📂 CharacterCreation/      # ✨ Создание персонажа
│   │   ├── CharacterCreationView.swift        # Главный экран создания
│   │   ├── 📂 Steps/              # Шаги создания
│   │   │   ├── NameStepView.swift             # Имя
│   │   │   ├── RaceStepView.swift             # Раса
│   │   │   ├── ClassStepView.swift            # Класс
│   │   │   └── StatsStepView.swift            # Характеристики
│   │   └── 📂 Components/         # Компоненты создания
│   │       ├── RaceCard.swift
│   │       └── PointBuyRow.swift
│   │
│   └── 📂 Shared/                 # 🔧 Общие компоненты
│       ├── AvatarView.swift               # Аватар персонажа
│       ├── DSBadge.swift                  # Бейджи
│       ├── DSHPButton.swift               # Кнопка HP
│       ├── SparkleEffect.swift            # Эффект искр
│       ├── LockedComponents.swift         # Заблокированные UI
│       └── DatabaseRecoveryView.swift     # Восстановление БД
│
├── 🧠 Core/                       # Бизнес-логика
│   ├── 📂 Models/                 # 📦 Модели данных
│   │   ├── DNDCharacter.swift             # Главная модель (@Model SwiftData)
│   │   ├── AbilityScores.swift            # 6 характеристик (Sendable)
│   │   ├── CharacterClass.swift           # Классы персонажей
│   │   ├── ClassProficiencies.swift       # Владение навыками по классам
│   │   ├── Race.swift                     # Расы
│   │   ├── DNDAlignment.swift             # Мировоззрение
│   │   ├── InventoryItem.swift            # Предмет инвентаря (Sendable)
│   │   ├── EquipmentSlot.swift            # Слоты экипировки
│   │   ├── TarotCard.swift                # Карта Таро (Sendable)
│   │   ├── MapLocation.swift              # Точка на карте (Sendable)
│   │   ├── InstrumentType.swift           # Типы инструментов
│   │   ├── InstrumentModification.swift   # Модификация (Sendable)
│   │   ├── InstrumentModificationSlot.swift
│   │   └── InstrumentModificationLibrary.swift
│   │
│   ├── 📂 Party/                  # 🎲 Система партии
│   │   ├── PartyManager.swift             # Центральный синглтон (MCSession)
│   │   ├── PartyMessage.swift             # Enum всех сетевых сообщений
│   │   ├── PartyMember.swift              # Struct для игрока в партии
│   │   └── GameRules.swift                # Правила игры (счётчики отдыхов)
│   │
│   ├── Assets.xcassets            # Графические ресурсы
│   ├── CharacterStore.swift       # SwiftData store
│   ├── Constants.swift            # Глобальные константы
│   ├── DatabaseRecovery.swift     # Восстановление БД
│   ├── MilestoneLibrary.swift     # Библиотека вех (level up)
│   └── SoundManager.swift         # Менеджер звуков и haptic
│
├── 🛠️ Utils/                      # Вспомогательные утилиты
│   └── ImageCompressor.swift      # Сжатие изображений (для аватаров)
│
└── 🧪 ClarityTests/               # Unit-тесты
    ├── ClarityTests.swift                 # Базовые тесты
    ├── DNDCharacterTests.swift            # Тесты модели персонажа
    ├── AbilityScoresTests.swift           # Тесты характеристик
    ├── ConstantsTests.swift               # Тесты констант
    ├── InventoryItemTests.swift           # Тесты инвентаря (12 тестов)
    ├── TarotCardTests.swift               # Тесты карт Таро (17 тестов)
    ├── GameRulesTests.swift               # Тесты правил (8 тестов)
    └── PartyMemberTests.swift             # Тесты члена партии (14 тестов)
    
    🎯 КЛЮЧЕВЫЕ ФАЙЛЫ (знать обязательно)

Ключевые фичи по папкам

Party/ — мультиплеер с голосованием за отдых, синхронизацией HP/стресса/инвентаря
CharacterSheet/ — основной игровой экран с drawer'ом партии и overlay'ями
CharacterCreation/ — пошаговое создание персонажа
Tarot/ — колода карт Таро с эффектами
Map/ — интерактивная карта мира
Theme/ — единый Dark Souls стиль

⭐ Самые важные (часто меняются):

Views/CharacterSheet/CharacterSheetView.swift — главный hub, связывает все секции
Core/Party/PartyManager.swift — синглтон мультиплеера
Core/Models/DNDCharacter.swift — главная модель (@Model)
Core/CharacterStore.swift — CRUD + автосинхронизация
🆕 Недавно добавленные:

Views/CharacterSheet/Sections/PartyMembersDrawer.swift — drawer с профилями партии
Core/Party/GameRules.swift — правила ДМа
Views/Shared/LockedComponents.swift — компоненты блокировки
🎨 Дизайн-система:

Theme/DSColors.swift — все цвета (dsGold, dsRed, dsSurface...)
Theme/DSModifiers.swift — .dsCard(), .dsInnerCard()
Theme/Components/ — CornerOrnaments, DSSectionHeader, DSdivider
