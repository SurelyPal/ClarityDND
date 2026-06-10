//
//  ImageCompressor.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Кроссплатформенный компрессор изображений для аватаров.
/// Сжимает изображение до квадратного формата с заданным качеством.
enum ImageCompressor {
    
    static let maxDimension: CGFloat = Constants.UI.avatarMaxSize
    static let quality: CGFloat = Constants.UI.avatarCompression
    
    /// Сжимает изображение до максимального размера и JPEG-качества
    static func compress(_ data: Data) -> Data? {
        #if canImport(UIKit)
        return compressUIImage(data)
        #elseif canImport(AppKit)
        return compressNSImage(data)
        #else
        return nil
        #endif
    }
    
    // MARK: - iOS Implementation
    
    #if canImport(UIKit)
    private static func compressUIImage(_ data: Data) -> Data? {
        guard let originalImage = UIImage(data: data) else { return nil }
        
        // Нормализуем ориентацию — перерисовываем изображение
        // чтобы пиксели реально соответствовали правильной ориентации
        let normalizedImage = normalizeOrientation(originalImage)
        
        // Вычисляем квадратный размер сохраняя пропорции
        let side = min(normalizedImage.size.width, normalizedImage.size.height)
        let cropRect = CGRect(
            x: (normalizedImage.size.width - side) / 2,
            y: (normalizedImage.size.height - side) / 2,
            width: side,
            height: side
        )
        
        // Обрезаем до квадрата (чтобы аватар был круглым)
        guard let cgCropped = normalizedImage.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        let croppedImage = UIImage(cgImage: cgCropped)
        
        // Сжимаем до maxDimension
        let targetSize = CGSize(width: maxDimension, height: maxDimension)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resized.jpegData(compressionQuality: quality)
    }
    
    /// Перерисовывает изображение, чтобы ориентация EXIF "запеклась" в пиксели.
    /// Без этого изображения с iPhone могут отображаться повёрнутыми.
    private static func normalizeOrientation(_ image: UIImage) -> UIImage {
        // Если ориентация уже .up (нормальная) — ничего не делаем
        guard image.imageOrientation != .up else { return image }
        
        // Перерисовываем через UIGraphicsImageRenderer —
        // это автоматически применит EXIF-поворот
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
    #endif
    
    // MARK: - macOS Implementation
    
    #if canImport(AppKit)
    private static func compressNSImage(_ data: Data) -> Data? {
        guard let originalImage = NSImage(data: data) else { return nil }
        
        // Получаем CGImage из NSImage
        guard let cgImage = originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // Вычисляем квадратный размер сохраняя пропорции
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)
        
        let cropRect = CGRect(
            x: (width - side) / 2,
            y: (height - side) / 2,
            width: side,
            height: side
        )
        
        // Обрезаем до квадрата
        guard let cgCropped = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        // Сжимаем до maxDimension
        let targetSize = NSSize(width: maxDimension, height: maxDimension)
        let resizedImage = NSImage(cgImage: cgCropped, size: targetSize)
        
        // Конвертируем в JPEG с заданным качеством
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            return nil
        }
        
        return jpegData
    }
    #endif
}
