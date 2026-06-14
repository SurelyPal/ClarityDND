Clarity/
├── ClarityApp.swift                          # Точка входа приложения, инициализация SwiftUI App
├── RootView.swift                            # Корневой View, определяет начальный экран
├── Clarity-Info.plist                        # Конфигурация приложения (разрешения, настройки)
│
├── Core/                                     # Ядро бизнес-логики
│   ├── CharacterStore.swift                  # Хранилище персонажей (CRUD операции)
│   ├── Constants.swift                       # Глобальные константы приложения
│   ├── DatabaseRecovery.swift                # Логика восстановления повреждённой БД
│   ├── MilestoneLibrary.swift                # Библиотека вех для повышения уровня
│   ├── SoundManager.swift                    # Синглтон управления звуками
│   ├── Assets.xcassets                       # Ресурсы изображений и цветов
│   │
│   ├── Models/                               # Модели данных (Codable structs)
│   │   ├── AbilityScores.swift               # Характеристики персонажа (STR, DEX, etc.)
│   │   ├── Campaign.swift                    # Модель кампании (название, правила, участники)
│   │   ├── CharacterClass.swift              # Класс персонажа (воин, маг, etc.)
│   │   ├── ClassProficiencies.swift          # Владения класса (оружие, броня, навыки)
│   │   ├── DNDAlignment.swift                # Мировоззрение персонажа (Lawful Good, etc.)
│   │   ├── DNDCharacter.swift                # Основная модель персонажа (все данные)
│   │   ├── EquipmentSlot.swift               # Enum слотов экипировки (голова, руки, etc.)
│   │   ├── HPChange.swift                    # Запись изменения HP (история)
│   │   ├── InstrumentModification.swift      # Модификация инструмента (бонусы)
│   │   ├── InstrumentModificationLibrary.swift # Библиотека доступных модификаций
│   │   ├── InstrumentModificationSlot.swift  # Слот модификации инструмента
│   │   ├── InstrumentType.swift              # Тип инструмента (лютня, флейта, etc.)
│   │   ├── InventoryItem.swift               # Модель предмета инвентаря
│   │   ├── MapLocation.swift                 # Локация на карте (координаты, описание)
│   │   ├── Race.swift                        # Раса персонажа (эльф, человек, etc.)
│   │   └── TarotCard.swift                   # Модель карты Таро
│   │
│   └── Party/                                # Система многопользовательской игры
│       ├── CampaignManager.swift             # Синглтон управления кампаниями (сохранение/загрузка)
│       ├── GameRules.swift                   # Правила игры (лимиты отдыхов, настройки)
│       ├── PartyManager.swift                # Основной синглтон управления партией
│       ├── PartyManager+Connection.swift     # Extension: подключение к Multipeer
│       ├── PartyManager+Messages.swift       # Extension: обработка входящих сообщений
│       ├── PartyManager+Persistence.swift    # Extension: сохранение состояния партии
│       ├── PartyMember.swift                 # Модель участника партии (игрок + персонаж)
│       ├── PartyMessage.swift                # Enum всех типов сообщений между игроками
│       └── RestVotingManager.swift           # Менеджер голосования за отдых
│
├── Theme/                                    # Система тем и стилизация
│   ├── ThemeManager.swift                    # Синглтон управления текущей темой
│   ├── Theme.swift                           # Модель темы (цвета, шрифты)
│   ├── View+CornerRadius.swift               # Extension для скругления углов
│   ├── DSColors.swift                        # Цветовая палитра Dark Souls стиля
│   ├── DSModifiers.swift                     # Кастомные ViewModifiers (.dsCard(), etc.)
│   │
│   └── Components/                           # Переиспользуемые UI компоненты
│       ├── CornerOrnaments.swift             # Декоративные угловые орнаменты
│       ├── DSSectionHeader.swift             # Заголовок секции в стиле DS
│       └── DSdivider.swift                   # Разделитель в стиле Dark Souls
│
├── Views/                                    # Все экраны приложения
│   ├── ContentView.swift                     # Главный контейнер с TabView
│   ├── CharacterInfoView.swift               # Детальная информация о персонаже
│   │
│   ├── CharacterCreation/                    # Создание персонажа (пошаговый мастер)
│   │   ├── CharacterCreationView.swift       # Основной View создания персонажа
│   │   │
│   │   ├── Steps/                            # Отдельные шаги создания
│   │   │   ├── NameStepView.swift            # Шаг: выбор имени
│   │   │   ├── StatsStepView.swift           # Шаг: распределение характеристик
│   │   │   ├── ClassStepView.swift           # Шаг: выбор класса
│   │   │   └── RaceStepView.swift            # Шаг: выбор расы
│   │   │
│   │   └── Components/                       # Компоненты мастера создания
│   │       ├── PointBuyRow.swift             # Строка системы Point Buy
│   │       └── RaceCard.swift                # Карточка расы с описанием
│   │
│   ├── CharacterSheet/                       # Лист персонажа (главный экран игрока)
│   │   ├── CharacterSheetView.swift          # Основной View листа персонажа
│   │   ├── PreviewHelper.swift               # Хелпер для превью в Xcode
│   │   │
│   │   ├── Sections/                         # Секции листа персонажа
│   │   │   ├── TabSection.swift              # Контейнер вкладок (Stats, Skills, etc.)
│   │   │   ├── HPSection.swift               # Секция управления HP
│   │   │   ├── HPHistorySheet.swift          # Модальное окно истории HP
│   │   │   ├── PartyMembersDrawer.swift      # Выдвижная панель участников партии
│   │   │   └── CharacterHeaderSection.swift  # Заголовок с аватаром и именем
│   │   │
│   │   ├── Stats/                            # Вкладка характеристик
│   │   │   ├── StatsTabView.swift            # Контейнер вкладки Stats
│   │   │   ├── DSCombatStatsView.swift       # Боевые характеристики (AC, инициатива)
│   │   │   └── DSStatCard.swift              # Карточка одной характеристики
│   │   │
│   │   ├── Skills/                           # Вкладка навыков
│   │   │   └── SkillsTabView.swift           # Список всех навыков с владениями
│   │   │
│   │   ├── Stress/                           # Система стресса
│   │   │   └── StressTrackerView.swift       # Трекер уровня стресса
│   │   │
│   │   ├── Equipment/                        # Экипировка персонажа
│   │   │   └── EquipmentPanel.swift          # Панель надетой экипировки
│   │   │
│   │   ├── Inventory/                        # Инвентарь предметов
│   │   │   ├── InventoryTabView.swift        # Вкладка инвентаря (список предметов)
│   │   │   ├── InventoryItemRow.swift        # Строка предмета в списке
│   │   │   └── ItemEditorView.swift          # Редактор предмета (создание/изменение)
│   │   │
│   │   ├── InstrumentMods/                   # Модификации музыкальных инструментов
│   │   │   ├── InstrumentModsTabView.swift   # Вкладка модификаций инструментов
│   │   │   ├── InstrumentModHeader.swift     # Заголовок секции модификаций
│   │   │   ├── InstrumentModSlotView.swift   # Слот модификации (пустой/заполненный)
│   │   │   └── InstrumentModPickerView.swift # Выбор модификации из библиотеки
│   │   │
│   │   └── Components/                       # Компоненты листа персонажа
│   │       ├── MilestonePopupView.swift      # Попап повышения уровня (веха)
│   │       └── DemotionPopupView.swift       # Попап понижения уровня
│   │
│   ├── Party/                                # Система партии и лобби
│   │   ├── PartyLobbyView.swift              # Лобби партии (ожидание подключения)
│   │   ├── PartyStatusIndicator.swift        # Индикатор статуса подключения
│   │   ├── DungeonMasterView.swift           # Главный экран мастера (список игроков)
│   │   ├── DungeonMasterDetailView.swift     # Детальный просмотр персонажа игрока (ДМ)
│   │   ├── RestEffectOverlayView.swift       # Оверлей эффекта отдыха (анимация)
│   │   ├── RestVoteOverlayView.swift         # Оверлей голосования за отдых
│   │   │
│   │   ├── LobbyComponents/                  # Компоненты лобби
│   │   │   ├── RoleSelectionView.swift       # Выбор роли (Мастер/Игрок)
│   │   │   ├── PlayerFlowView.swift          # Поток игрока (подключение к ДМ)
│   │   │   ├── SearchingView.swift           # Экран поиска партии
│   │   │   ├── ConnectingView.swift          # Экран подключения к ДМ
│   │   │   ├── ConnectedView.swift           # Экран успешного подключения
│   │   │   ├── HostingView.swift             # Экран хостинга (создание комнаты)
│   │   │   └── RulesConfigurationView.swift  # Настройка правил игры
│   │   │
│   │   └── DMComponents/                     # Компоненты экрана мастера
│   │       ├── GameRulesSection.swift        # Секция отображения/редактирования правил
│   │       ├── CampaignSelectionView.swift   # Выбор кампании из списка
│   │       ├── DMBasicInfoSection.swift      # Базовая информация об игроке (ДМ)
│   │       ├── DMDetailHeader.swift          # Заголовок детального просмотра (ДМ)
│   │       │
│   │       └── DMSections/                   # Секции детального просмотра (ДМ)
│   │           ├── DMInventorySection.swift  # Просмотр инвентаря игрока (ДМ)
│   │           ├── DMSkillsSection.swift     # Просмотр навыков игрока (ДМ)
│   │           └── DMStatsSection.swift      # Просмотр характеристик игрока (ДМ)
│   │
│   ├── Map/                                  # Система карты
│   │   ├── MapView.swift                     # Основной View карты с локациями
│   │   └── ZoomedLocationView.swift          # Детальный просмотр локации
│   │
│   ├── Tarot/                                # Система карт Таро
│   │   ├── TarotTabView.swift                # Вкладка коллекции карт Таро
│   │   ├── TarotCardView.swift               # Отображение одной карты Таро
│   │   └── TarotCardEditorView.swift         # Редактор карты Таро
│   │
│   ├── Settings/                             # Настройки приложения
│   │   ├── SettingsView.swift                # Главный экран настроек
│   │   └── ThemeSettingsView.swift           # Настройки темы оформления
│   │
│   └── Shared/                               # Переиспользуемые компоненты Views
│       ├── IconHelper.swift                  # Хелпер для иконок (SF Symbols mapping)
│       ├── StatRow.swift                     # Строка характеристики (label + value)
│       ├── InfoRow.swift                     # Информационная строка
│       ├── RuleToggle.swift                  # Переключатель правила (toggle + описание)
│       ├── PartyMemberRow.swift              # Строка участника партии
│       ├── SkeletonCharacterRow.swift        # Скелетон-загрузка строки персонажа
│       ├── SkeletonLoader.swift              # Анимация скелетон-загрузки
│       ├── DatabaseRecoveryView.swift        # Экран восстановления БД
│       ├── LockedComponents.swift            # Заблокированные компоненты (для игроков)
│       ├── SparkleEffect.swift               # Анимация блеска (для редких предметов)
│       ├── DSHPButton.swift                  # Кнопка изменения HP в стиле DS
│       ├── DSBadge.swift                     # Бейдж в стиле Dark Souls
│       └── AvatarView.swift                  # Компонент аватара персонажа
│
├── Utils/                                    # Утилиты и хелперы
│   ├── PlatformCompatibility.swift           # Совместимость iOS/macOS (haptics, etc.)
│   └── ImageCompressor.swift                 # Сжатие изображений перед отправкой
│
├── Resources/                                # Ресурсы приложения
│   └── Sounds/                               # Звуковые эффекты
│
└── ForAi/                                    # Документация для AI-ассистентов
    ├── PROJECT_STRUCTURE.md                  # Описание структуры проекта
    └── TODO.md                               # Список задач и планов
