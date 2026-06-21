//
// UTType+Clarity.swift
// Clarity
//
// Кастомный тип файла для шаблонов Clarity
//

import UniformTypeIdentifiers

extension UTType {
    static let clarityTemplate = UTType(
        exportedAs: "com.clarity.template",
        conformingTo: .json
    )
}
