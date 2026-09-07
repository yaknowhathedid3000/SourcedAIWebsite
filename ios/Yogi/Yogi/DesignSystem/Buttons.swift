import SwiftUI

/// Press feedback shared by every button in the app.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in if pressed { Haptics.tap() } }
    }
}

/// Albo's full-width pill with the hard black offset shadow. Teardown 3.3.
/// Used on every onboarding step ("Continue", "Get Started", "Let's go"),
/// the paywall, sheets ("Submit", "Import") and, in red, "Sign Out".
struct PrimaryButton: View {
    enum Style { case ink, danger, blue }

    let title: String
    var style: Style = .ink
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    private var fill: Color {
        guard isEnabled else { return YogiColor.disabled }
        switch style {
        case .ink: return YogiColor.ink
        case .danger: return YogiColor.danger
        case .blue: return YogiColor.systemBlue
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Hard offset shadow layer (the chunky 3D look).
                Capsule()
                    .fill(style == .danger ? Color(hex: 0x8E1526) : Color.black)
                    .offset(y: isEnabled ? 5 : 0)
                Capsule().fill(fill)
                if isLoading {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().fill(.white).frame(width: 7, height: 7)
                        }
                    }
                } else {
                    Text(title)
                        .font(.yogiSans(18, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 58)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled || isLoading)
        .padding(.bottom, 5)
        .accessibilityLabel(title)
    }
}

/// Light grey pill, used for "Cancel", "Not Now", "Maybe later"-style secondary actions.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.yogiSans(17, weight: .semibold))
                .foregroundStyle(YogiColor.ink)
                .frame(height: 54)
                .frame(maxWidth: .infinity)
                .background(YogiColor.optionFill, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Outlined pill with an optional leading system image, used for "Wanna",
/// "View on map", "Call", "Website", "Edit Profile", "Share".
struct OutlinePill: View {
    let title: String
    var systemImage: String? = nil
    var expands: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.yogiSans(16, weight: .semibold))
            .foregroundStyle(YogiColor.ink)
            .padding(.horizontal, 18)
            .frame(height: 48)
            .frame(maxWidth: expands ? .infinity : nil)
            .background(Capsule().stroke(YogiColor.hairline, lineWidth: 1.5))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Plain text link, "Already have an account? Sign in".
struct TextLinkButton: View {
    let prefix: String
    let action: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(prefix).foregroundStyle(YogiColor.inkSecondary)
                Text(action).fontWeight(.bold).foregroundStyle(YogiColor.ink)
            }
            .font(.yogiSans(17))
        }
        .buttonStyle(.plain)
    }
}

/// Round white floating action button with shadow (Ask Yogi, dice, plus).
struct FloatingButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .frame(width: 60, height: 60)
                .background(YogiColor.card, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
