import Foundation

/// Drains whatever the share extension queued up in the App Group and runs it through the
/// normal import pipeline, so a link shared from Safari lands exactly like one pasted into
/// the Add sheet: Claude reads it when the backend is configured, heuristics when it isn't.
@MainActor
enum ShareInboxImporter {
    /// True while a drain is in flight, so a fast tab switch can't start a second one.
    private static var isDraining = false

    static func drain(into app: AppState) async {
        guard !isDraining else { return }
        let items = ShareInbox.pending()
        guard !items.isEmpty else { return }

        isDraining = true
        defer { isDraining = false }

        var imported = 0
        var failed = 0

        for item in items {
            do {
                let saves = try await build(item)
                guard !saves.isEmpty else {
                    failed += 1
                    continue
                }
                for save in saves { app.add(save) }
                imported += saves.count
                ShareInbox.remove([item.id])
                ShareInbox.discardAttachments(item.attachmentNames)
            } catch is CancellationError {
                // Leave it queued; the next foreground picks it up.
                return
            } catch let error as BackendError {
                switch error {
                case .outOfCredits, .proRequired:
                    // Keep it queued and put the paywall in front of them. It imports the
                    // moment they have credits again.
                    report(imported: imported, failed: failed, in: app)
                    app.showPaywall = true
                    return
                case .notSignedIn, .notConfigured:
                    // Nothing to do until they finish setup; hold the queue.
                    report(imported: imported, failed: failed, in: app)
                    return
                case .server:
                    failed += 1
                    ShareInbox.remove([item.id])
                    ShareInbox.discardAttachments(item.attachmentNames)
                }
            } catch {
                // A dead link or unreadable image: drop it rather than retrying forever,
                // but tell the user something arrived and didn't make it.
                failed += 1
                ShareInbox.remove([item.id])
                ShareInbox.discardAttachments(item.attachmentNames)
            }
        }

        report(imported: imported, failed: failed, in: app)
    }

    // MARK: Building saves

    private static func build(_ item: InboxItem) async throws -> [Save] {
        switch item.kind {
        case .link:
            guard let url = item.url else { return [] }
            var save = try await ImportService.extract(from: url)
            // Respect the category the user picked in the extension sheet.
            if let raw = item.categoryRaw, let picked = SaveCategory(rawValue: raw), picked != save.category {
                save.category = picked
                save.coverEmoji = picked.emoji
            }
            return [save]

        case .text:
            guard let text = item.text, !text.isEmpty else { return [] }
            let title = item.pageTitle ?? String(text.prefix(60))
            return try await ImportService.analyze(note: title, body: text, noteID: nil)

        case .images:
            let blobs = item.attachmentNames.compactMap { ShareInbox.attachmentData($0) }
            guard !blobs.isEmpty else { return [] }
            return try await ImportService.extract(screenshots: blobs)
        }
    }

    // MARK: Feedback

    private static func report(imported: Int, failed: Int, in app: AppState) {
        if imported > 0 {
            let noun = imported == 1 ? "save" : "saves"
            app.showToast(failed == 0
                          ? "Added \(imported) \(noun) you shared"
                          : "Added \(imported) \(noun), \(failed) couldn't be read")
        } else if failed > 0 {
            app.showToast(failed == 1
                          ? "Yogi couldn't read what you shared"
                          : "Yogi couldn't read \(failed) shared items")
        }
    }
}
