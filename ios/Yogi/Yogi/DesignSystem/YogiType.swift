import SwiftUI

/// Albo pairs Apple's New York (serif) for titles with SF Pro for everything else.
/// See teardown 3.1. `design: .serif` resolves to New York on iOS.
extension Font {
    /// Section and item titles: "Library", "How was it?", "Triple Chocolate Cookies".
    static func yogiDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Italic serif for category tabs and journal lines.
    static func yogiDisplayItalic(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif).italic()
    }

    /// Headlines, body, buttons, chips.
    static func yogiSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

/// Reusable text roles so screens stay consistent.
enum YogiTextStyle {
    case screenTitle       // serif 34 bold ("Library")
    case itemTitle         // serif 28 bold (detail titles)
    case sheetTitle        // serif 30 bold ("How was it?")
    case onboardingHeadline // sans 28 bold ("What brings you to Yogi?")
    case headline          // sans 20 semibold
    case body              // sans 17
    case bodySecondary     // sans 17, secondary color
    case caption           // sans 13, muted
    case label             // sans 12 uppercase tracked
    case tabItalic         // serif italic 20

    var font: Font {
        switch self {
        case .screenTitle: return .yogiDisplay(34)
        case .itemTitle: return .yogiDisplay(28)
        case .sheetTitle: return .yogiDisplay(30)
        case .onboardingHeadline: return .yogiSans(28, weight: .bold)
        case .headline: return .yogiSans(20, weight: .semibold)
        case .body: return .yogiSans(17)
        case .bodySecondary: return .yogiSans(17)
        case .caption: return .yogiSans(13)
        case .label: return .yogiSans(12, weight: .semibold)
        case .tabItalic: return .yogiDisplayItalic(20)
        }
    }

    var color: Color {
        switch self {
        case .bodySecondary: return YogiColor.inkSecondary
        case .caption, .label: return YogiColor.muted
        default: return YogiColor.ink
        }
    }
}

struct YogiTextModifier: ViewModifier {
    let style: YogiTextStyle
    func body(content: Content) -> some View {
        let base = content.font(style.font).foregroundStyle(style.color)
        if style == .label {
            return AnyView(base.textCase(.uppercase).tracking(1.4))
        }
        return AnyView(base)
    }
}

extension View {
    func yogiText(_ style: YogiTextStyle) -> some View {
        modifier(YogiTextModifier(style: style))
    }
}
