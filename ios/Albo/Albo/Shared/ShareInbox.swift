import Foundation

// MARK: - App Group

/// The container both the app and the share extension write to. Must match the App Group
/// capability on BOTH targets in the Apple Developer portal, or the extension silently
/// writes into a sandbox the app can never read.
enum AlboAppGroup {
    static let identifier = "group.com.sourcedai.albo"

    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    /// Where the extension parks screenshot/photo blobs until the app imports them.
    static var attachments: URL? {
        guard let container else { return nil }
        let dir = container.appendingPathComponent("Inbox", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

// MARK: - Item

enum InboxKind: String, Codable {
    case link, text, images
}

/// One thing handed to Albo from another app's share sheet.
/// Deliberately small and dependency-free: the extension has no idea how a `Save` is built,
/// it just records what the user shared and lets the app run the real import.
struct InboxItem: Codable, Identifiable, Hashable {
    var id: UUID
    var kind: InboxKind
    var url: URL?
    var text: String?
    var pageTitle: String?
    /// Raw value of a `SaveCategory` when the user picked one in the extension sheet.
    var categoryRaw: String?
    /// Filenames inside `AlboAppGroup.attachments`.
    var attachmentNames: [String]
    var createdAt: Date

    init(id: UUID = UUID(),
         kind: InboxKind,
         url: URL? = nil,
         text: String? = nil,
         pageTitle: String? = nil,
         categoryRaw: String? = nil,
         attachmentNames: [String] = [],
         createdAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.url = url
        self.text = text
        self.pageTitle = pageTitle
        self.categoryRaw = categoryRaw
        self.attachmentNames = attachmentNames
        self.createdAt = createdAt
    }
}

// MARK: - Queue

/// A tiny durable queue in the App Group. The extension appends, the app drains on launch
/// and on every return to the foreground.
enum ShareInbox {
    private static let key = "albo.shareInbox"

    static func pending() -> [InboxItem] {
        guard let defaults = AlboAppGroup.defaults,
              let data = defaults.data(forKey: key),
              let items = try? JSONDecoder().decode([InboxItem].self, from: data) else { return [] }
        return items.sorted { $0.createdAt < $1.createdAt }
    }

    static func append(_ item: InboxItem) {
        var items = pending()
        items.append(item)
        write(items)
    }

    static func remove(_ ids: [UUID]) {
        let dropped = Set(ids)
        let remaining = pending().filter { !dropped.contains($0.id) }
        write(remaining)
    }

    static func clear() {
        write([])
        if let dir = AlboAppGroup.attachments {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    private static func write(_ items: [InboxItem]) {
        guard let defaults = AlboAppGroup.defaults,
              let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: key)
    }

    // MARK: Attachments

    /// Writes image data into the shared container and returns the filename to record on the item.
    @discardableResult
    static func storeAttachment(_ data: Data, ext: String = "jpg") -> String? {
        guard let dir = AlboAppGroup.attachments else { return nil }
        let name = "\(UUID().uuidString).\(ext)"
        do {
            try data.write(to: dir.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func attachmentData(_ name: String) -> Data? {
        guard let dir = AlboAppGroup.attachments else { return nil }
        return try? Data(contentsOf: dir.appendingPathComponent(name))
    }

    /// Called once the app has turned an item into real saves.
    static func discardAttachments(_ names: [String]) {
        guard let dir = AlboAppGroup.attachments else { return }
        for name in names {
            try? FileManager.default.removeItem(at: dir.appendingPathComponent(name))
        }
    }
}
