import SwiftUI

// MARK: - What the extension picked up

@MainActor
@Observable
final class SharePayload {
    var url: URL?
    var text: String?
    var imageData: [Data] = []
    var isLoading = true

    func set(url: URL) { self.url = url }
    func set(text: String) { self.text = text }
    func add(image data: Data) { imageData.append(data) }
    func finish() { isLoading = false }

    var host: String? {
        guard let host = url?.host else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// A readable stand-in for the title until the app fetches the real one.
    var headline: String {
        if let url {
            let slug = url.pathComponents
                .filter { $0 != "/" && !$0.isEmpty }
                .last?
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: "_", with: " ")
            if let slug, slug.count > 3, !slug.contains(".") {
                return slug.capitalized
            }
            return host ?? url.absoluteString
        }
        if let text, !text.isEmpty {
            return String(text.prefix(80))
        }
        if !imageData.isEmpty {
            return imageData.count == 1 ? "1 screenshot" : "\(imageData.count) screenshots"
        }
        return "Nothing to save"
    }

    var isEmpty: Bool { url == nil && (text?.isEmpty ?? true) && imageData.isEmpty }

    /// Same host heuristics the in-app importer uses, so the chip starts on the right guess.
    var guessedCategory: SaveCategory {
        guard let url else { return imageData.isEmpty ? .note : .image }
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        if path.contains("recipe") || host.contains("seriouseats") || host.contains("delish") || host.contains("bonappetit") { return .recipe }
        if host.contains("maps.google") || host.contains("maps.apple") || host.contains("tripadvisor") || host.contains("yelp") { return .place }
        if host.contains("imdb") || host.contains("letterboxd") { return .film }
        if host.contains("goodreads") || host.contains("bookshop") { return .book }
        if host.contains("amazon") || host.contains("etsy") { return .product }
        if host.contains("github") || host.contains("producthunt") { return .software }
        if host.contains("eventbrite") || host.contains("dice.fm") { return .event }
        if host.contains("youtube") || host.contains("youtu.be") { return .tutorial }
        return .article
    }

    var platformLabel: String {
        let host = (url?.host ?? "").lowercased()
        if host.contains("tiktok") { return "TikTok" }
        if host.contains("instagram") { return "Instagram" }
        if host.contains("youtube") || host.contains("youtu.be") { return "YouTube" }
        if host.contains("pinterest") { return "Pinterest" }
        return self.host ?? "Shared"
    }
}

// MARK: - Sheet

/// The compact confirm sheet, in the app's own design language: serif headline, grey option
/// pills, black CTA with the hard offset shadow.
struct ShareSheetView: View {
    @Bindable var payload: SharePayload
    let onSave: (InboxItem) -> Void
    let onCancel: () -> Void

    @State private var category: SaveCategory?
    @State private var isSaving = false

    private var resolved: SaveCategory { category ?? payload.guessedCategory }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            card
                .background(AlboColor.ground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom))
        }
        .animation(.easeOut(duration: 0.22), value: payload.isLoading)
    }

    private var card: some View {
        VStack(spacing: 0) {
            Capsule().fill(AlboColor.hairline).frame(width: 42, height: 5).padding(.top, 10)

            HStack {
                Text("Save to Albo").font(.alboDisplay(28)).foregroundStyle(AlboColor.ink)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AlboColor.inkSecondary)
                        .frame(width: 32, height: 32)
                        .background(AlboColor.optionFill, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.top, 14)

            preview.padding(.horizontal, 20).padding(.top, 16)

            if !payload.isLoading && !payload.isEmpty {
                categoryRow.padding(.top, 20)
            }

            PrimaryButton(title: buttonTitle, isEnabled: canSave, isLoading: isSaving) { save() }
                .padding(.horizontal, 20).padding(.top, 22)

            Text("Albo will read it properly when you open the app.")
                .font(.alboSans(13))
                .foregroundStyle(AlboColor.muted)
                .padding(.top, 12).padding(.bottom, 18)
        }
    }

    private var buttonTitle: String {
        if payload.isLoading { return "Reading…" }
        if payload.isEmpty { return "Nothing to save" }
        return "Save"
    }

    private var canSave: Bool { !payload.isLoading && !payload.isEmpty && !isSaving }

    // MARK: Preview row

    private var preview: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AlboColor.optionFill)
                    .frame(width: 56, height: 56)
                Text(resolved.emoji).font(.system(size: 26))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(payload.isLoading ? "Reading what you shared…" : payload.headline)
                    .font(.alboSans(17, weight: .semibold))
                    .foregroundStyle(AlboColor.ink)
                    .lineLimit(2)
                Text(payload.isLoading ? " " : payload.platformLabel)
                    .font(.alboSans(15))
                    .foregroundStyle(AlboColor.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlboColor.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: Category chips

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SaveCategory.browsable) { c in
                    let selected = c == resolved
                    Button {
                        Haptics.selection()
                        category = c
                    } label: {
                        HStack(spacing: 7) {
                            Text(c.emoji).font(.system(size: 15))
                            Text(c.title).font(.alboSans(16, weight: .medium))
                        }
                        .foregroundStyle(selected ? Color.white : AlboColor.ink)
                        .padding(.horizontal, 15)
                        .frame(height: 42)
                        .background(selected ? AlboColor.ink : AlboColor.optionFill, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Commit

    private func save() {
        guard canSave else { return }
        isSaving = true
        Haptics.success()

        var names: [String] = []
        for data in payload.imageData {
            if let name = ShareInbox.storeAttachment(data) { names.append(name) }
        }

        let kind: InboxKind = payload.url != nil ? .link : (names.isEmpty ? .text : .images)
        let item = InboxItem(
            kind: kind,
            url: payload.url,
            text: payload.text,
            pageTitle: payload.url == nil ? nil : payload.headline,
            categoryRaw: resolved.rawValue,
            attachmentNames: names
        )
        onSave(item)
    }
}
