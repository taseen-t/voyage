import SwiftUI
import UIKit

// MARK: - Palette

/// Every colour is declared as a **light/dark pair on one line**, because the
/// two themes in the design are the same interface with the values swapped —
/// keeping them adjacent is what stops one being updated without the other.
///
/// Raw `UInt32` hex is the stored form rather than `Color`, so the same numbers
/// can be handed to `CGColor` when the app mark is rendered into the icon.
enum Palette {
    /// The page itself.
    static let surface = Pair(light: 0xF4F4F5, dark: 0x0F1011)
    /// Cards, sheets and anything that sits above the page.
    static let surfaceElevated = Pair(light: 0xFFFFFF, dark: 0x1A1B1D)
    /// Inputs, segmented tracks, icon chips.
    static let fieldFill = Pair(light: 0xEDEDEF, dark: 0x1C1D20)
    static let hairline = Pair(light: 0xE3E3E6, dark: 0x2A2B2F)

    // Text, in three weights of presence.
    static let ink = Pair(light: 0x0D0E10, dark: 0xF6F6F7)
    static let inkMuted = Pair(light: 0x6B6F76, dark: 0x9BA0A8)
    static let inkFaint = Pair(light: 0xA3A7AE, dark: 0x6C7076)

    /// The primary control is always the **inverse of the page** — a near-black
    /// button on the light theme, a near-white one on the dark. `control` and
    /// `surface` are therefore deliberately each other's opposites, and
    /// `controlLabel` follows `control` rather than `ink`.
    static let control = Pair(light: 0x1D1E21, dark: 0xF6F6F7)
    static let controlLabel = Pair(light: 0xFFFFFF, dark: 0x0D0E10)

    /// Price. The one saturated colour in the app, so it is never spent on
    /// anything a traveller is not deciding with.
    static let accent = Pair(light: 0xEF3E23, dark: 0xFF6A4D)

    /// The mark's ribbon, which sits on its own dark tile in both themes.
    static let markTile: UInt32 = 0x1D1E21
    static let markRibbon: UInt32 = 0x6E7378
    static let markNeedle: UInt32 = 0xFFFFFF

    struct Pair {
        let light: UInt32
        let dark: UInt32

        /// Resolves per trait collection, so a theme change repaints without
        /// the view hierarchy being rebuilt.
        var color: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(rgb: dark)
                : UIColor(rgb: light) })
        }
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(rgb: UInt32) { self.init(UIColor(rgb: rgb)) }

    static let surface = Palette.surface.color
    static let surfaceElevated = Palette.surfaceElevated.color
    static let fieldFill = Palette.fieldFill.color
    static let hairline = Palette.hairline.color

    static let ink = Palette.ink.color
    static let inkMuted = Palette.inkMuted.color
    static let inkFaint = Palette.inkFaint.color

    static let control = Palette.control.color
    static let controlLabel = Palette.controlLabel.color
    static let accent = Palette.accent.color
}

// MARK: - Metrics

enum Metrics {
    static let gutter: CGFloat = 26
    static let buttonHeight: CGFloat = 52
    static let buttonRadius: CGFloat = 15
    static let fieldRadius: CGFloat = 13
    static let cardRadius: CGFloat = 26
    /// Photo tiles in the onboarding illustrations.
    static let tileRadius: CGFloat = 13
    static let iconTile: CGFloat = 78
}
