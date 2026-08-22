import AppKit
import SwiftUI

enum MenuBarIconProvider {
    static let pointSize: CGFloat = 15

    static func image(isActive: Bool) -> NSImage {
        let symbolName = isActive ? "bolt.circle.fill" : "bolt.circle"
        let configuration = NSImage.SymbolConfiguration(
            pointSize: pointSize,
            weight: .regular
        )
        let canvasSize = NSSize(width: pointSize, height: pointSize)
        let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: nil
        )?
            .withSymbolConfiguration(configuration)
            ?? NSImage(size: canvasSize)

        image.isTemplate = true
        image.size = canvasSize
        return image
    }
}

struct MenuBarLabel: View {
    let isActive: Bool
    let accessibilityText: String

    var body: some View {
        Image(nsImage: MenuBarIconProvider.image(isActive: isActive))
            .fixedSize()
            .accessibilityLabel(accessibilityText)
    }
}
