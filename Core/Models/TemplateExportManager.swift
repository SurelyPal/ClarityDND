//
//  TemplateExportManager.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//


//
// TemplateExportManager.swift
// Clarity
//
// Менеджер для экспорта и импорта шаблонов
//

import Foundation
import SwiftData

/// Менеджер для экспорта и импорта шаблонов игр
class TemplateExportManager {
    static let shared = TemplateExportManager()
    
    private init() {}
    
    // MARK: - Экспорт
    
    /// Экспортирует шаблон в JSON файл
    /// - Parameters:
    ///   - template: Шаблон для экспорта
    ///   - completion: Callback с URL временного файла или ошибкой
    func exportTemplate(_ template: GameTemplate, completion: @escaping (Result<URL, Error>) -> Void) {
        let dto = TemplateExportDTO(from: template)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(dto)
            
            // Создаём временный файл
            let fileName = "\(template.name.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970)).clarity-template"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try jsonData.write(to: fileURL)
            
            completion(.success(fileURL))
        } catch {
            print("❌ Ошибка экспорта шаблона: \(error)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Импорт
    
    /// Импортирует шаблон из JSON файла
    /// - Parameters:
    ///   - fileURL: URL файла для импорта
    ///   - context: ModelContext для сохранения
    ///   - forceOverwrite: Если true, перезапишет существующий шаблон с тем же именем
    /// - Returns: Результат импорта
    func importTemplate(
        from fileURL: URL,
        context: ModelContext,
        forceOverwrite: Bool = false
    ) -> TemplateImportResult {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let dto = try decoder.decode(TemplateExportDTO.self, from: jsonData)
            
            // Проверяем версию
            if dto.version != "1.0" {
                print("⚠️ Неподдерживаемая версия формата: \(dto.version)")
            }
            
            // Конвертируем в GameTemplate
            guard let newTemplate = dto.toGameTemplate() else {
                return .invalidFormat
            }
            // 🆕 ИЗВЛЕКАЕМ значение в локальную константу ПЕРЕД #Predicate
            let templateName = newTemplate.name

            // Проверяем, существует ли шаблон с таким именем
            let descriptor = FetchDescriptor<GameTemplate>(
                predicate: #Predicate { $0.name == templateName }  // ✅ РАБОТАЕТ
            )

            if let existingTemplate = try context.fetch(descriptor).first {
                if forceOverwrite {
                    // Удаляем старый шаблон
                    context.delete(existingTemplate)
                    try context.save()
                } else {
                    return .nameConflict(existingTemplate: existingTemplate)
                }
            }
            
            // Сохраняем новый шаблон
            context.insert(newTemplate)
            try context.save()
            
            return .success(newTemplate)
            
        } catch let decodingError as DecodingError {
            print("❌ Ошибка декодирования: \(decodingError)")
            return .decodingError(decodingError)
        } catch {
            print("❌ Ошибка импорта: \(error)")
            return .decodingError(error)
        }
    }
    
    /// Проверяет, является ли файл валидным шаблоном
    func isValidTemplateFile(_ fileURL: URL) -> Bool {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let _ = try decoder.decode(TemplateExportDTO.self, from: jsonData)
            return true
        } catch {
            return false
        }
    }
    
    /// Получает информацию о шаблоне из файла без импорта
    func previewTemplate(from fileURL: URL) -> TemplateExportDTO? {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(TemplateExportDTO.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
