//
//  DatabaseRecoveryView.swift
//  Clarity
//
//  📁 Путь: Views/Components/ или Views/
//

import SwiftUI

struct DatabaseRecoveryView: View {
    let state: RecoveryState
    @Environment(\.dismiss) var dismiss
    @State private var isRestoring = false
    @State private var restoreResult: RestoreResult?
    
    enum RestoreResult {
        case success
        case failure(String)
    }
    
    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    statusCard
                    actionButtons
                    backupListSection
                    Spacer()
                }
                .padding(20)
            }
        }
        .overlay {
            if isRestoring {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.dsGold))
                            .scaleEffect(1.5)
                        
                        Text("Восстановление...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.dsGold)
                        
                        Text("Пожалуйста, подождите")
                            .font(.system(size: 12))
                            .foregroundColor(Color.dsTextDim)
                    }
                    .padding(30)
                    .background(Color.dsSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dsGold.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }        .alert(
            restoreResult == nil ? "" : "Результат",
            isPresented: .constant(restoreResult != nil)
        ) {
            Button("OK") { restoreResult = nil }
        } message: {
            switch restoreResult {
            case .success:
                Text("✅ БД успешно восстановлена. Перезапустите приложение.")
            case .failure(let error):
                Text("❌ Ошибка: \(error)")
            case .none:
                EmptyView()
            }
        }
        // 🆕 Подтверждение восстановления
        .alert("Подтвердите восстановление", isPresented: $showRestoreConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Восстановить", role: .destructive) {
                performRestore()
            }
        } message: {
            Text("Текущая база данных будет заменена данными из backup. Это действие нельзя отменить.")
        }

        // 🆕 Успешный экспорт
        .alert("Backup экспортирован", isPresented: $showExportSuccess) {
            Button("OK") { }
        } message: {
            Text("Backup сохранён в папку Files → Clarity. Вы можете скопировать его на компьютер через iCloud.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: iconForState)
                .font(.system(size: 48))
                .foregroundColor(colorForState)
            
            Text(titleForState)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Color.dsGold)
            
            Text(subtitleForState)
                .font(.system(size: 13))
                .foregroundColor(Color.dsTextDim)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color.dsGold)
                Text("Что произошло")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsGold)
            }
            
            Text(descriptionForState)
                .font(.system(size: 12))
                .foregroundColor(Color.dsText)
                .lineSpacing(4)
            
            if case .recoveredFromBackup(let url) = state {
                HStack(spacing: 8) {
                    Image(systemName: "externaldrive.fill")
                        .foregroundColor(Color.dsGoldDim)
                    Text("Backup: \(url.lastPathComponent)")
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsTextDim)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dsSurface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colorForState.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Action Buttons
    
    // 🆕 Состояния для алертов
    @State private var showRestoreConfirmation = false
    @State private var showExportSuccess = false
    @State private var selectedBackupForExport: DatabaseRecovery.BackupInfo? = nil

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 🆕 Кнопка восстановления с подтверждением
            if case .recoveredFromBackup(let backupURL) = state {
                Button {
                    showRestoreConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Восстановить из backup")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.dsBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.dsGold)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                // 🆕 Кнопка экспорта backup
                Button {
                    let success = DatabaseRecovery.exportBackupToFiles(backupURL)
                    if success {
                        showExportSuccess = true
                    } else {
                        restoreResult = .failure("Не удалось экспортировать backup")
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                        Text("Экспортировать backup в Files")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.dsGold.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            // Кнопка "Начать заново"
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.circle.fill")
                    Text("Начать заново")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.dsRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dsRed.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            
            // Кнопка "Продолжить" (для in-memory fallback)
            if case .inMemoryFallback = state {
                Button {
                    dismiss()
                } label: {
                    Text("Продолжить (данные не сохраняются)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.dsTextDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    // MARK: - Backup List
    
    private var backupListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(Color.dsGold)
                Text("История backup'ов")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.dsGold)
            }
            
            let backups = DatabaseRecovery.listBackups()
            
            if backups.isEmpty {
                Text("Нет доступных backup'ов")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsTextDim)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(backups) { backup in
                        BackupRow(
                            backup: backup,
                            onRestore: {
                                performRestore(from: backup.mainURL)
                            },
                            onExport: {
                                selectedBackupForExport = backup
                                let success = DatabaseRecovery.exportBackupToFiles(backup.mainURL)
                                if success {
                                    showExportSuccess = true
                                } else {
                                    restoreResult = .failure("Не удалось экспортировать backup")
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.dsSurface)
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private func performRestore(from url: URL? = nil) {
        isRestoring = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let targetURL: URL?
            
            if let url = url {
                targetURL = url
            } else if case .recoveredFromBackup(let backupURL) = state {
                targetURL = backupURL
            } else {
                targetURL = nil
            }
            
            guard let restoreURL = targetURL else {
                DispatchQueue.main.async {
                    isRestoring = false
                    restoreResult = .failure("Не найден backup для восстановления")
                }
                return
            }
            
            let success = DatabaseRecovery.restoreFromBackup(at: restoreURL)
            
            DispatchQueue.main.async {
                isRestoring = false
                if success {
                    restoreResult = .success
                } else {
                    restoreResult = .failure("Не удалось восстановить БД")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var iconForState: String {
        switch state {
        case .healthy:
            return "checkmark.circle.fill"
        case .recoveredFromBackup:
            return "externaldrive.fill.badge.checkmark"
        case .inMemoryFallback:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var colorForState: Color {
        switch state {
        case .healthy:
            return Color.dsGold
        case .recoveredFromBackup:
            return .orange
        case .inMemoryFallback:
            return Color.dsRed
        case .failed:
            return Color.dsRed
        }
    }
    
    private var titleForState: String {
        switch state {
        case .healthy:
            return "Всё в порядке"
        case .recoveredFromBackup:
            return "БД повреждена"
        case .inMemoryFallback:
            return "Критическая ошибка"
        case .failed:
            return "Ошибка восстановления"
        }
    }
    
    private var subtitleForState: String {
        switch state {
        case .healthy:
            return "База данных работает нормально"
        case .recoveredFromBackup:
            return "Мы создали backup и новую БД"
        case .inMemoryFallback:
            return "Работаем в режиме без сохранения"
        case .failed:
            return "Не удалось создать backup"
        }
    }
    
    private var descriptionForState: String {
        switch state {
        case .healthy:
            return "База данных загружена успешно."
        case .recoveredFromBackup:
            return """
            При загрузке произошла ошибка, и мы не смогли открыть вашу базу данных.
            
            ✅ Мы автоматически создали backup старой БД перед удалением.
            ✅ Создана новая пустая БД.
            
            Вы можете восстановить данные из backup или начать заново.
            """
        case .inMemoryFallback:
            return """
            Критическая ошибка: не удалось создать даже новую БД.
            
            Приложение работает в режиме "только для просмотра" — \
            все изменения будут потеряны при выходе.
            
            Попробуйте восстановить данные из backup.
            """
        case .failed(let error):
            return "Ошибка: \(error)"
        }
    }
}

// MARK: - Backup Row

struct BackupRow: View {
    let backup: DatabaseRecovery.BackupInfo
    let onRestore: () -> Void
    let onExport: () -> Void  // 🆕 Добавили callback для экспорта
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "externaldrive.fill")
                .foregroundColor(Color.dsGold)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(backup.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.dsText)
                
                Text(backup.timestamp)
                    .font(.system(size: 10))
                    .foregroundColor(Color.dsTextDim)
            }
            
            Spacer()
            
            // 🆕 Кнопка экспорта
            Button {
                onExport()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(Color.dsGold)
                    .padding(8)
                    .background(Color.dsGold.opacity(0.1))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
            
            // Кнопка восстановления
            Button {
                onRestore()
            } label: {
                Text("Восстановить")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.dsBackground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.dsGold)
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.dsSurfaceAlt)
        .cornerRadius(6)
    }
}

