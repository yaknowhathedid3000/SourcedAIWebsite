import Foundation
import UserNotifications

// MARK: - Import (Albo #25 "Importing... watching everything at 2x speed")

/// Turns a URL, note or screenshot batch into saves. Local placeholder until the
/// extract endpoint exists; keeps the same async shape so the UI does not change.
enum ImportService {
    static func extract(from url: URL) async -> Save {
        try? await Task.sleep(for: .seconds(1.6))
        let host = url.host ?? "web"
        let platform: SourcePlatform
        if host.contains("tiktok") { platform = .tiktok }
        else if host.contains("instagram") { platform = .instagram }
        else if host.contains("youtube") || host.contains("youtu.be") { platform = .youtube }
        else if host.contains("pinterest") { platform = .pinterest }
        else { platform = .safari }

        // Heuristic categorisation so demos feel alive.
        let path = url.path.lowercased()
        if path.contains("recipe") || host.contains("delish") || host.contains("seriouseats") {
            return Save(category: .recipe, title: Self.title(from: url, fallback: "Imported recipe"), subtitle: host, coverEmoji: "🥘", coverTint: 0xF7D9B0,
                        sourceURL: url, sourcePlatform: platform,
                        recipe: RecipeDetails(timeLabel: "30 mins", cuisine: nil, course: nil, yieldLabel: "Serves 2", ingredients: [], steps: [], emoji: "🥘"))
        }
        return Save(category: .article, title: Self.title(from: url, fallback: host), subtitle: host, coverEmoji: "🌐", coverTint: 0xDCE9FF, sourceURL: url, sourcePlatform: platform)
    }

    static func analyze(note title: String, body: String) async -> [Save] {
        try? await Task.sleep(for: .seconds(1.2))
        // Pull "## Heading" lines out of the markdown as things Albo found.
        let headings = body.split(separator: "\n").compactMap { line -> String? in
            let t = line.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("#") else { return nil }
            let cleaned = t.replacingOccurrences(of: "#", with: "").replacingOccurrences(of: "*", with: "").trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? nil : cleaned
        }
        return headings.map { name in
            Save(category: .recipe, title: name, coverEmoji: nil, sourcePlatform: .note, saveCount: 1,
                 recipe: RecipeDetails(timeLabel: "15 mins", cuisine: "American", course: "Dessert", yieldLabel: nil, ingredients: [], steps: [], emoji: "🍪"))
        }
    }

    static func extract(screenshots count: Int) async -> [Save] {
        try? await Task.sleep(for: .seconds(1.8))
        return (0..<count).map { i in
            Save(category: .image, title: "Untitled", coverEmoji: "🖼️", coverTint: 0xE0E0E0, sourcePlatform: .screenshot, saveCount: 1, createdAt: Date().addingTimeInterval(Double(-i)))
        }
    }

    private static func title(from url: URL, fallback: String) -> String {
        let last = url.lastPathComponent.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
        let cleaned = last.replacingOccurrences(of: ".html", with: "").trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty || cleaned == "/" ? fallback : cleaned.capitalized
    }
}

// MARK: - Ask Albo (Albo #57 to #59, #93 to #95)

/// Local answerer over the user's library. Swap for a streaming chat endpoint.
enum AskAlboService {
    static func answer(_ question: String, saves: [Save], scope: Save?) async -> String {
        try? await Task.sleep(for: .seconds(0.9))
        let q = question.lowercased()

        if let scope {
            if let r = scope.recipe {
                if q.contains("sugar") || q.contains("how much") || q.contains("ingredient") {
                    let matches = r.ingredients.filter { ing in q.split(separator: " ").contains { ing.name.lowercased().contains($0) } }
                    if !matches.isEmpty {
                        let lines = matches.map { "\($0.emoji) \($0.name): \($0.quantityLabel(multiplier: 1) ?? "to taste")" }
                        return "From the recipe:\n" + lines.joined(separator: "\n")
                    }
                    if r.ingredients.isEmpty {
                        return "I'm sorry, but the recipe details I have available don't list the specific ingredients or measurements yet. Try \"Reanalyze\" on the source note."
                    }
                    return "This recipe has \(r.ingredients.count) ingredients: " + r.ingredients.map(\.name).joined(separator: ", ") + "."
                }
                if q.contains("long") || q.contains("time") { return "\(scope.title) takes about \(r.timeLabel)." }
                if q.contains("step") || q.contains("how do") { return r.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n") }
            }
            if let p = scope.place {
                if q.contains("open") || q.contains("hour") { return p.hoursLabel ?? "No opening times found for \(scope.title)." }
                if q.contains("where") || q.contains("address") { return p.address ?? "I don't have an address for \(scope.title) yet." }
            }
            return "Here's what I know about \(scope.title): \(scope.metaLine). Ask me about ingredients, steps, opening hours or where it is."
        }

        guard !saves.isEmpty else {
            return "It looks like your library is currently empty, so I don't have any saved items to recommend. Share some links, recipes, or places you're interested in and I can help you organize them!"
        }
        if q.contains("best") || q.contains("recommend") || q.contains("what should") {
            let wants = saves.filter { $0.status == .wantTo }
            let pick = wants.first ?? saves[0]
            return "Top pick from your saves: \(pick.title) (\(pick.metaLine)). You saved it from \(pick.sourcePlatform.title) and haven't done it yet."
        }
        let stop: Set<String> = ["what", "which", "where", "when", "does", "have", "this", "that", "with", "from", "about"]
        let words = q.split(separator: " ").map(String.init).filter { $0.count > 3 && !stop.contains($0) }
        let hits = saves.filter { s in
            let t = s.title.lowercased()
            return t.contains(q) || words.contains { t.contains($0) }
        }
        if !hits.isEmpty {
            return "Found \(hits.count) in your library:\n" + hits.prefix(5).map { "• \($0.title), \($0.metaLine)" }.joined(separator: "\n")
        }
        let byCategory = Dictionary(grouping: saves, by: \.category)
        let summary = byCategory.map { "\($0.value.count) \($0.key.pluralTitle.lowercased())" }.sorted().joined(separator: ", ")
        return "You have \(saves.count) saves: \(summary). Ask me for the best thing to do, or about a specific save."
    }
}

// MARK: - Purchases (Albo #41 to #43)

/// Stand-in for StoreKit 2. `purchase` resolves after a short delay.
enum PurchaseService {
    static let yearlyPrice = "$29.99"
    static let trialDays = 3

    static var billingDate: Date {
        Calendar.current.date(byAdding: .day, value: trialDays, to: Date()) ?? Date()
    }

    static func purchaseYearly() async -> Bool {
        try? await Task.sleep(for: .seconds(1.2))
        return true
    }
}

// MARK: - Notifications (Albo #36, #92, #131)

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func schedule(reminder: Reminder, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(reminderID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID.uuidString])
    }
}
