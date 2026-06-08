//
//  DatabaseRecovery.swift
//  Clarity
//
//  📁 Путь: Core/ или App/
//

import Foundation
import SwiftData

enum DatabaseRecovery {
    
    // 📁 Пути к файлам БД
    private static var databaseFiles: [URL] {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return [] }
        
        return [
            appSupport.appendingPathComponent("default.store"),
            appSupport.appendingPathComponent("default.store.sqlite"),
            appSupport.appendingPathComponent("default.store-wal"),
            appSupport.appendingPathComponent("default.store-shm")
        ]
    }
    
    // 💾 Создание backup с временной меткой
    static func createBackup() -> URL? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return nil }
        
        let backupDir = appSupport.appendingPathComponent("backups")
        
        do {
            // Создаём папку backups если её нет
            try FileManager.default.createDirectory(
                at: backupDir,
                withIntermediateDirectories: true
            )
            
            // Копируем все файлы БД
            var backupMainURL: URL?
            for url in databaseFiles {
                guard FileManager.default.fileExists(atPath: url.path) else { continue }
                
                let fileName = url.lastPathComponent
                let backupURL = backupDir.appendingPathComponent("\(fileName).\(timestamp)")
                
                try FileManager.default.copyItem(at: url, to: backupURL)
                
                if fileName == "default.store" {
                    backupMainURL = backupURL
                }
            }
            
            print("✅ Backup создан: \(backupDir.path)")
            return backupMainURL
            
        } catch {
            print("❌ Ошибка создания backup: \(error)")
            return nil
        }
    }
    
    // 🗑️ Удаление повреждённой БД
    static func deleteCorruptDatabase() {
        for url in databaseFiles {
            do {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Удалён: \(url.lastPathComponent)")
            } catch {
                // Файла может не быть — это нормально
            }
        }
    }
    
    // ♻️ Восстановление из backup
    static func restoreFromBackup(at backupURL: URL) -> Bool {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return false }
        
        let timestamp = backupURL.lastPathComponent
            .replacingOccurrences(of: "default.store.", with: "")
        
        do {
            // Сначала удаляем текущую БД
            deleteCorruptDatabase()
            
            // Восстанавливаем все файлы из backup
            let backupDir = backupURL.deletingLastPathComponent()
            let backupFiles = try FileManager.default.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: nil
            ).filter { $0.lastPathComponent.contains(timestamp) }
            
            for backupFile in backupFiles {
                let originalName = backupFile.lastPathComponent
                    .replacingOccurrences(of: ".\(timestamp)", with: "")
                let targetURL = appSupport.appendingPathComponent(originalName)
                
                try FileManager.default.copyItem(at: backupFile, to: targetURL)
            }
            
            print("♻️ БД восстановлена из backup: \(timestamp)")
            return true
            
        } catch {
            print("❌ Ошибка восстановления: \(error)")
            return false
        }
    }
    
    // 📋 Список всех доступных backup'ов
    static func listBackups() -> [BackupInfo] {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return [] }
        
        let backupDir = appSupport.appendingPathComponent("backups")
        
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return [] }
        
        // Группируем по timestamp
        var backups: [String: BackupInfo] = [:]
        
        for file in files where file.lastPathComponent.contains("default.store") {
            let parts = file.lastPathComponent.split(separator: ".")
            guard parts.count >= 3 else { continue }
            
            let timestamp = String(parts[2])
            let creationDate = (try? file.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
            
            if backups[timestamp] == nil {
                backups[timestamp] = BackupInfo(
                    timestamp: timestamp,
                    date: creationDate,
                    mainURL: file
                )
            }
        }
        
        return backups.values.sorted { $0.date > $1.date }
    }
    // 📤 Экспорт backup в Files (чтобы пользователь мог сохранить на компьютер)
    static func exportBackupToFiles(_ backupURL: URL) -> Bool {
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return false }
        
        let fileName = backupURL.lastPathComponent
        let exportURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            // Удаляем если уже существует
            if FileManager.default.fileExists(atPath: exportURL.path) {
                try FileManager.default.removeItem(at: exportURL)
            }
            
            try FileManager.default.copyItem(at: backupURL, to: exportURL)
            print("📤 Backup экспортирован: \(exportURL.path)")
            return true
            
        } catch {
            print("❌ Ошибка экспорта: \(error)")
            return false
        }
    }
    
    struct BackupInfo: Identifiable {
        let id = UUID()
        let timestamp: String
        let date: Date
        let mainURL: URL
    }
}
