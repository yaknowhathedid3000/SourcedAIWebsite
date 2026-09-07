import SwiftUI

// MARK: - Progress header (Albo #4 onward)

/// Back chevron, thin progress track, optional Skip. Sits at the top of every guided flow.
struct ProgressHeader: View {
    let progress: Double
    var showsBack: Bool = true
    var skipTitle: String? = nil
    var onBack: () -> Void = {}
    var onSkip: () -> Void = {}

    var body: some View {
        HStack(spacing: 16) {
            if showsBack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(YogiColor.ink)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(YogiColor.optionFill)
                    Capsule()
                        .fill(YogiColor.ink)
                        .frame(width: max(12, geo.size.width * progress))
                        .animation(.easeInOut(duration: 0.35), value: progress)
                }
            }
            .frame(height: 6)
            if let skipTitle {
                Button(skipTitle, action: onSkip)
                    .font(.yogiSans(17))
                    .foregroundStyle(YogiColor.inkSecondary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Option pill (Albo #5, #14, #19, #21)

/// Light grey fully-rounded option with emoji, label and a filled check when selected.
struct OptionPill: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(emoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.yogiSans(17))
                        .foregroundStyle(YogiColor.ink)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle).font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                    }
                }
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(YogiColor.ink)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(YogiColor.optionFill, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Chips

/// Sentiment chip used on "How was it?" (Albo #80, #83). Inverts to black when selected.
struct SentimentChip: View {
    let sentiment: Sentiment
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(sentiment.emoji)
                Text(sentiment.title)
            }
            .font(.yogiSans(16, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? .white : YogiColor.ink)
            .padding(.horizontal, 18)
            .frame(height: 46)
            .background(isSelected ? YogiColor.ink : YogiColor.optionFill, in: Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Small grey tag chip ("Recipes", "Public").
struct TagChip: View {
    let title: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 4) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 12)) }
            Text(title)
        }
        .font(.yogiSans(14, weight: .medium))
        .foregroundStyle(YogiColor.ink)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(YogiColor.optionFill, in: Capsule())
    }
}

// MARK: - Star rating (Albo #83)

struct StarRating: View {
    @Binding var rating: Int
    var size: CGFloat = 32
    var interactive: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? YogiColor.ink : YogiColor.optionFill)
                    .onTapGesture {
                        guard interactive else { return }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { rating = star }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rating) of 5 stars")
    }
}

/// Small static stars shown on cards and feed (white on images, yellow on social proof).
struct StaticStars: View {
    let rating: Int
    var color: Color = YogiColor.star
    var size: CGFloat = 14
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Slide to confirm (Albo #69 "Made it?", #137 "Visited?")

/// Grey pill track with a dark round knob. Drag to the end to confirm.
struct SlideToConfirm: View {
    let title: String
    let onConfirm: () -> Void

    @State private var offset: CGFloat = 0
    @State private var confirmed = false
    private let knob: CGFloat = 52
    private let height: CGFloat = 60

    var body: some View {
        GeometryReader { geo in
            let travel = max(0, geo.size.width - knob - 8)
            ZStack(alignment: .leading) {
                Capsule().fill(YogiColor.optionFill)
                Text(title)
                    .font(.yogiSans(17))
                    .foregroundStyle(YogiColor.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, knob / 2)
                    .opacity(1 - Double(offset / max(travel, 1)))
                Circle()
                    .fill(YogiColor.ink)
                    .overlay(
                        Image(systemName: confirmed ? "checkmark" : "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .frame(width: knob, height: knob)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .offset(x: 4 + offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !confirmed else { return }
                                offset = min(max(0, value.translation.width), travel)
                            }
                            .onEnded { _ in
                                guard !confirmed else { return }
                                if offset > travel * 0.8 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        offset = travel
                                        confirmed = true
                                    }
                                    Haptics.heavy()
                                    onConfirm()
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { offset = 0 }
                                }
                            }
                    )
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onConfirm() }
    }
}

// MARK: - Toast (Albo #78 "Marked as complete", #194)

struct ToastView: View {
    let message: String
    var systemImage: String = "checkmark"
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage).font(.system(size: 14, weight: .bold))
            Text(message).font(.yogiSans(15, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color.black.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
    }
}

// MARK: - Empty state (Albo #47, #116, #127, #130, #161)

struct EmptyStateView: View {
    var mascot: MascotVariant? = nil
    var systemImage: String? = nil
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 14) {
            if let mascot {
                MascotView(variant: mascot).frame(width: 110, height: 110)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 64))
                    .foregroundStyle(YogiColor.muted.opacity(0.6))
            }
            Text(title)
                .font(.yogiSans(18, weight: .semibold))
                .foregroundStyle(YogiColor.ink)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.yogiSans(15))
                    .foregroundStyle(YogiColor.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            if let actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.yogiSans(16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .frame(height: 50)
                        .background(YogiColor.ink, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 6)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section header ("Recently saved >", "Collections >")

struct SectionHeader: View {
    let title: String
    var showsChevron: Bool = true
    var trailing: AnyView? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            Button(action: { onTap?() }) {
                HStack(spacing: 6) {
                    Text(title).font(.yogiSans(22, weight: .bold)).foregroundStyle(YogiColor.ink)
                    if showsChevron {
                        Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundStyle(YogiColor.ink)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onTap == nil)
            Spacer()
            if let trailing { trailing }
        }
    }
}

// MARK: - Uppercase divider label ("OR MANUALLY SEARCH THESE", Albo #60)

struct DividerLabel: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(YogiColor.hairline).frame(height: 1)
            Text(text).yogiText(.label).fixedSize()
            Rectangle().fill(YogiColor.hairline).frame(height: 1)
        }
    }
}

// MARK: - Card

struct YogiCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .padding(padding)
            .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}

// MARK: - Settings row (Albo #191)

struct SettingsRow: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    var tint: Color = YogiColor.ink
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundStyle(tint)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.yogiSans(18)).foregroundStyle(tint)
                if let subtitle {
                    Text(subtitle).font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                }
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundStyle(YogiColor.ink)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Avatar

struct AvatarView: View {
    let user: UserSummary
    var size: CGFloat = 40
    var body: some View {
        ZStack {
            Circle().fill(YogiColor.optionFill)
            MascotView(variant: user.mascot).padding(size * 0.18)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(YogiColor.hairline, lineWidth: 1))
    }
}

/// Overlapping avatar cluster shown next to "1165 saves".
struct AvatarStack: View {
    let users: [UserSummary]
    var size: CGFloat = 26
    var body: some View {
        HStack(spacing: -size * 0.35) {
            ForEach(Array(users.prefix(3))) { u in
                AvatarView(user: u, size: size)
                    .overlay(Circle().stroke(YogiColor.ground, lineWidth: 2))
            }
        }
    }
}

// MARK: - Category icon (Albo #56 chip row, #60, #104)

/// Emoji stands in for Albo's 3D renders. Swap for image assets when available.
struct CategoryIcon: View {
    let category: SaveCategory
    var size: CGFloat = 56
    var body: some View {
        Text(category.emoji)
            .font(.system(size: size * 0.66))
            .frame(width: size, height: size)
    }
}
