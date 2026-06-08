//
//  ImageCompressor.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import UIKit

enum ImageCompressor {
    static let maxDimension: CGFloat = Constants.UI.avatarMaxSize
    static let quality: CGFloat = Constants.UI.avatarCompression
    
    /// Сжимает изображение до максимального размера и JPEG-качества
    static func compress(_ data: Data) -> Data? {
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
}
