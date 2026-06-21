//
//  TemplateExportDTO.swift
//  Clarity
//
//  Created by KEBAB on 20.06.2026.
//


//
// TemplateExportDTO.swift
// Clarity
//
// Data Transfer Object для экспорта/импорта шаблонов
//

import Foundation

/// DTO для экспорта шаблона в JSON
struct TemplateExportDTO: Codable {
    let version: String
    let exportDate: Date
    let template: TemplateData
    
    struct TemplateData: Codable {
        let name: String
        let templateDescription: String
        let fieldDefinitions: [FieldDefinitionData]
    }
    
    struct FieldDefinitionData: Codable {
        let name: String
        let key: String
        let fieldType: String // rawValue из FieldType
        let defaultValue: String
        let minValue: Int?
        let maxValue: Int?
        let displayColor: String?
        let showOnSheet: Bool
        let isEditableByPlayer: Bool
    }
    
    // MARK: - Конвертация из GameTemplate
    
    init(from template: GameTemplate) {
        self.version = "1.0"
        self.exportDate = Date()
        self.template = TemplateData(
            name: template.name,
            templateDescription: template.templateDescription,
            fieldDefinitions: template.fieldDefinitions.map { field in
                FieldDefinitionData(
                    name: field.name,
                    key: field.key,
                    fieldType: field.fieldType.rawValue,
                    defaultValue: field.defaultValue,
                    minValue: field.minValue,
                    maxValue: field.maxValue,
                    displayColor: field.displayColor,
                    showOnSheet: field.showOnSheet,
                    isEditableByPlayer: field.isEditableByPlayer
                )
            }
        )
    }
    
    // MARK: - Конвертация в GameTemplate
    
    func toGameTemplate() -> GameTemplate? {
        let fieldDefs = template.fieldDefinitions.compactMap { fieldData -> FieldDefinition? in
            guard let fieldType = FieldType(rawValue: fieldData.fieldType) else {
                print("⚠️ Неизвестный тип поля: \(fieldData.fieldType)")
                return nil
            }
            
            return FieldDefinition(
                name: fieldData.name,
                key: fieldData.key,
                fieldType: fieldType,
                defaultValue: fieldData.defaultValue,
                minValue: fieldData.minValue,
                maxValue: fieldData.maxValue,
                displayColor: fieldData.displayColor,
                showOnSheet: fieldData.showOnSheet,
                isEditableByPlayer: fieldData.isEditableByPlayer
            )
        }
        
        return GameTemplate(
            name: template.name,
            templateDescription: template.templateDescription,
            isBuiltIn: false, // Импортированные шаблоны всегда пользовательские
            fieldDefinitions: fieldDefs
        )
    }
}

// MARK: - Результат импорта

enum TemplateImportResult {
    case success(GameTemplate)
    case nameConflict(existingTemplate: GameTemplate)
    case invalidFormat
    case decodingError(Error)
    
    var errorMessage: String {
        switch self {
        case .success:
            return ""
        case .nameConflict(let existing):
            return "Шаблон с именем '\(existing.name)' уже существует. Выберите другое имя или удалите существующий шаблон."
        case .invalidFormat:
            return "Неверный формат файла. Убедитесь, что это файл шаблона Clarity (.clarity-template)."
        case .decodingError(let error):
            return "Ошибка чтения файла: \(error.localizedDescription)"
        }
    }
}