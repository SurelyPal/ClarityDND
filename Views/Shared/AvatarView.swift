//
//  AvatarView.swift
//  Clarity
//
//  Created by Refactor on 09.06.2026.
//

import SwiftUI

struct AvatarView: View {
    @Environment(\.theme) private var theme
    let avatarData: Data?
    let race: Race
    var size: CGFloat = 90

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.surface)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(theme.borderBright, lineWidth: 1)
                )

            if let data = avatarData, let image = PlatformImage(data: data) {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size - 8, height: size - 8)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: race.icon)
                    .font(.system(size: size * 0.45))
                    .foregroundColor(theme.primary)
            }
            
            // ❌ УДАЛЕНО: CornerOrnaments больше не отображаются
        }
    }
}

// MARK: - Platform Compatibility

#if os(iOS)
typealias PlatformImage = UIImage

extension Image {
    init(platformImage: UIImage) {
        self.init(uiImage: platformImage)
    }
}
#elseif os(macOS)
typealias PlatformImage = NSImage

extension Image {
    init(platformImage: NSImage) {
        self.init(nsImage: platformImage)
    }
}
#endif
