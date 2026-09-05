import SwiftUI

extension String {
    /// Glues the last two words with a non-breaking space so a headline never ends
    /// with a single orphaned word on its own line.
    var noOrphans: String {
        guard let lastSpace = lastIndex(of: " ") else { return self }
        // Only glue when there are at least three words; two-word strings wrap fine.
        let words = split(separator: " ")
        guard words.count >= 3 else { return self }
        var s = self
        s.replaceSubrange(lastSpace...lastSpace, with: "\u{00A0}")
        return s
    }
}

extension Text {
    /// `Text` that never leaves a lonely last word.
    init(orphanSafe string: String) {
        self.init(string.noOrphans)
    }
}

/// Section title with a trailing copy icon ("Ingredients ⧉", Albo #86).
struct CopyableHeading: View {
    let title: String
    let payload: String
    @State private var copied = false
    var body: some View {
        HStack(spacing: 10) {
            Text(title).font(.alboSans(24, weight: .bold)).foregroundStyle(AlboColor.ink)
            Button {
                UIPasteboard.general.string = payload
                copied = true
                Task { try? await Task.sleep(for: .seconds(1.5)); copied = false }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 16)).foregroundStyle(AlboColor.inkSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Copy \(title.lowercased())")
        }
    }
}

/// Grey rounded text field with a leading icon (Edit Profile, Albo #174).
struct IconField: View {
    let systemImage: String
    let placeholder: String
    @Binding var text: String
    var disabled: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage).font(.system(size: 20)).foregroundStyle(disabled ? AlboColor.muted : AlboColor.inkSecondary).frame(width: 26)
            TextField(placeholder, text: $text)
                .font(.alboSans(18))
                .foregroundStyle(disabled ? AlboColor.muted : AlboColor.ink)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(disabled)
        }
        .padding(.horizontal, 18).frame(height: 60)
        .background(disabled ? AlboColor.surface : AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Grey rounded multi-line field with a character counter beneath (New Collection, Edit Profile).
struct CountedTextArea: View {
    let placeholder: String
    @Binding var text: String
    let limit: Int
    var minHeight: CGFloat = 110

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder).font(.alboSans(18)).foregroundStyle(AlboColor.muted).padding(.horizontal, 18).padding(.top, 16)
                }
                TextEditor(text: $text)
                    .font(.alboSans(18))
                    .foregroundStyle(AlboColor.ink)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 13).padding(.top, 8)
                    .frame(minHeight: minHeight)
                    .onChange(of: text) { _, new in if new.count > limit { text = String(new.prefix(limit)) } }
            }
            .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text("\(text.count)/\(limit)").font(.alboSans(14)).foregroundStyle(AlboColor.muted).monospacedDigit()
        }
    }
}

/// Single-line grey field with a counter (collection name "7/50").
struct CountedTextField: View {
    let placeholder: String
    @Binding var text: String
    let limit: Int
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField(placeholder, text: $text)
                .font(.alboSans(18))
                .padding(.horizontal, 18).frame(height: 60)
                .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onChange(of: text) { _, new in if new.count > limit { text = String(new.prefix(limit)) } }
            Text("\(text.count)/\(limit)").font(.alboSans(14)).foregroundStyle(AlboColor.muted).monospacedDigit()
        }
    }
}

/// Sheet chrome: grab handle plus optional back chevron and centered serif title (Import via Link, Albo #61).
struct SheetHeader: View {
    var title: String? = nil
    var onBack: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            if let title {
                ZStack {
                    Text(title).font(.alboDisplay(26)).foregroundStyle(AlboColor.ink)
                    if let onBack {
                        HStack {
                            Button(action: onBack) { Image(systemName: "chevron.left").font(.system(size: 22, weight: .semibold)).foregroundStyle(AlboColor.ink).frame(width: 40, height: 40) }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Back")
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
        }
    }
}

/// Grey search pill with a magnifying glass (Search users..., Search friends, Search places...).
struct SearchPill: View {
    let placeholder: String
    @Binding var text: String
    var leadingEmoji: String? = nil
    var onClear: (() -> Void)? = nil
    var body: some View {
        HStack(spacing: 12) {
            if let leadingEmoji { Text(leadingEmoji) } else { Image(systemName: "magnifyingglass").font(.system(size: 20)).foregroundStyle(AlboColor.inkSecondary) }
            TextField(placeholder, text: $text).font(.alboSans(18)).foregroundStyle(AlboColor.ink)
            if !text.isEmpty {
                Button { text = ""; onClear?() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(AlboColor.inkSecondary) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20).frame(height: 60)
        .background(AlboColor.optionFill, in: Capsule())
    }
}

/// Small grey chip with icon and label (Directions, Website, More on the place sheet, Albo #140).
struct ActionChip: View {
    let systemImage: String
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage).font(.system(size: 16))
                Text(title).font(.alboSans(17, weight: .medium))
            }
            .foregroundStyle(AlboColor.ink)
            .padding(.horizontal, 18).frame(height: 52)
            .background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Black pill "Follow" / "Following" outlined (Albo #158, #180).
struct FollowButton: View {
    let isFollowing: Bool
    var expands: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.alboSans(18, weight: .semibold))
                .foregroundStyle(isFollowing ? AlboColor.ink : .white)
                .padding(.horizontal, 24).frame(height: 52)
                .frame(maxWidth: expands ? .infinity : nil)
                .background {
                    if isFollowing {
                        RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AlboColor.hairline, lineWidth: 1.5)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.black).offset(y: 4)
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AlboColor.ink)
                        }
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
