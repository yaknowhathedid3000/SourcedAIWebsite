import SwiftUI
import UIKit

extension Color {
    /// A color that resolves differently in light and dark mode.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    /// Convenience for the sampled hex values in the teardown (chapter 3.2).
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Albo's palette, sampled from the recorded screens. See teardown 3.2.
enum AlboColor {
    // Grounds
    static let ground = Color.dynamic(light: .white, dark: UIColor(white: 0.07, alpha: 1))
    static let surface = Color.dynamic(light: UIColor(white: 0.957, alpha: 1), dark: UIColor(white: 0.13, alpha: 1))       // #F4F4F4
    static let optionFill = Color.dynamic(light: UIColor(white: 0.937, alpha: 1), dark: UIColor(white: 0.17, alpha: 1))    // #EFEFEF
    static let card = Color.dynamic(light: .white, dark: UIColor(white: 0.12, alpha: 1))
    static let hairline = Color.dynamic(light: UIColor(white: 0.90, alpha: 1), dark: UIColor(white: 0.22, alpha: 1))

    // Ink
    static let ink = Color.dynamic(light: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1), dark: .white)             // #1C1C1E
    static let inkSecondary = Color.dynamic(light: UIColor(white: 0.35, alpha: 1), dark: UIColor(white: 0.78, alpha: 1))
    static let muted = Color.dynamic(light: UIColor(white: 0.55, alpha: 1), dark: UIColor(white: 0.60, alpha: 1))
    static let disabled = Color(hex: 0xC8C8C8)

    // Accents
    static let systemBlue = Color(hex: 0x0A7AFF)
    static let rewardGreen = Color(hex: 0x22C55E)
    static let rewardGreenDeep = Color(hex: 0x16A34A)
    static let danger = Color(hex: 0xD6203A)
    static let brandOrange = Color(hex: 0xF5891F)
    static let ratingFill = Color(hex: 0xFFF4CC)
    static let star = Color(hex: 0xF5B800)
    static let categoryPurple = Color(hex: 0x9B4DFF)
    static let mapNight = Color(hex: 0x0B1B2B)
}
