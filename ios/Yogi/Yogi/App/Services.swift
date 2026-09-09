import EventKit
import Foundation
import StoreKit
import UserNotifications

// MARK: - Import (Albo #25 "Importing... watching everything at 2x speed")

/// Turns a URL, note or screenshot batch into saves.
/// When the Supabase backend is configured this calls the `extract` edge function (Claude does the
/// reading); otherwise it falls back to local heuristics so the app still demos offline.
enum ImportService {
    static var usesBackend: Bool {
        #if canImport(Supabase)
        return YogiBackend.shared.isConfigured
        #else
        return false
        #endif
    }

    static func extract(from url: URL) async throws -> Save {
        #if canImport(Supabase)
        if YogiBackend.shared.isConfigured {
            let records = try await YogiBackend.shared.extract(url: url)
            guard let first = records.first else { throw BackendError.server("Yogi couldn't read anything at that link.") }
            return first.save
        }
        #endif
        return await localExtract(from: url)
    }

    static func analyze(note title: String, body: String, noteID: UUID?) async throws -> [Save] {
        #if canImport(Supabase)
        if YogiBackend.shared.isConfigured {
            return try await YogiBackend.shared.extract(noteID: noteID ?? UUID(), title: title, body: body).map(\.save)
        }
        #endif
        return await localAnalyze(note: title, body: body)
    }

    /// Uploads each screenshot to the private imports bucket, then asks the backend to read them.
    static func extract(screenshots images: [Data]) async throws -> [Save] {
        #if canImport(Supabase)
        if YogiBackend.shared.isConfigured {
            var paths: [String] = []
            for data in images { paths.append(try await YogiBackend.shared.uploadImport(data)) }
            return try await YogiBackend.shared.extract(screenshotPaths: paths).map(\.save)
        }
        #endif
        return await localScreenshots(count: images.count)
    }

    // MARK: Local fallback (demo mode)

    private static func localExtract(from url: URL) async -> Save {
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

    private static func localAnalyze(note title: String, body: String) async -> [Save] {
        try? await Task.sleep(for: .seconds(1.2))
        // Pull "## Heading" lines out of the markdown as things Yogi found.
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

    private static func localScreenshots(count: Int) async -> [Save] {
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

// MARK: - Ask Yogi (Albo #57 to #59, #93 to #95)

/// Ask Yogi. With the backend configured this is the `ask-yogi` edge function (Claude over the
/// user's library, with chat history); offline it answers from the local library.
enum AskYogiService {
    static func answer(_ question: String, saves: [Save], scope: Save?, history: [ChatMessage] = []) async throws -> String {
        #if canImport(Supabase)
        if YogiBackend.shared.isConfigured {
            return try await YogiBackend.shared.ask(question, saveID: scope?.id, history: history)
        }
        #endif
        return await localAnswer(question, saves: saves, scope: scope)
    }

    private static func localAnswer(_ question: String, saves: [Save], scope: Save?) async -> String {
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

/// StoreKit 2. Product IDs match `Resources/Yogi.storekit` (local testing) and App Store Connect.
/// Prices shown in the paywall come from the store once products load; the literal is the fallback.
enum PurchaseService {
    static let yearlyProductID = "com.sourcedai.yogi.pro.yearly"
    static let trialDays = 3
    static var yearlyPrice = "$29.99"

    static var billingDate: Date {
        Calendar.current.date(byAdding: .day, value: trialDays, to: Date()) ?? Date()
    }

    /// Loads the yearly product and refreshes the displayed price. Safe to call repeatedly.
    static func loadProducts() async {
        guard let product = try? await Product.products(for: [yearlyProductID]).first else { return }
        yearlyPrice = product.displayPrice
    }

    /// Runs the purchase sheet. Returns true when the transaction is verified and finished.
    static func purchaseYearly() async -> Bool {
        do {
            guard let product = try await Product.products(for: [yearlyProductID]).first else { return false }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                await transaction.finish()
                return true
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            return false
        }
    }

    /// True when the App Store reports an active yearly entitlement.
    static func hasActiveSubscription() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == yearlyProductID, t.revocationDate == nil { return true }
        }
        return false
    }

    static func restore() async -> Bool {
        try? await AppStore.sync()
        return await hasActiveSubscription()
    }
}

// MARK: - Notifications (Albo #36, #92, #131)

enum NotificationService {
    private static let store = EKEventStore()

    /// Writes an event into the user's default calendar. Uses write-only access,
    /// which is the narrowest scope that does the job and the one Info.plist asks
    /// for, so Yogi never gains the ability to read what else is in there.
    static func addEventToCalendar(title: String,
                                   start: Date,
                                   end: Date?,
                                   location: String?,
                                   completion: @escaping (Bool) -> Void) {
        let write: (Bool) -> Void = { granted in
            guard granted else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let event = EKEvent(eventStore: store)
            event.title = title
            event.startDate = start
            event.endDate = end ?? start.addingTimeInterval(2 * 60 * 60)
            event.location = location
            event.calendar = store.defaultCalendarForNewEvents
            let ok = (try? store.save(event, span: .thisEvent)) != nil
            DispatchQueue.main.async { completion(ok) }
        }
        if #available(iOS 17.0, *) {
            store.requestWriteOnlyAccessToEvents { granted, _ in write(granted) }
        } else {
            store.requestAccess(to: .event) { granted, _ in write(granted) }
        }
    }

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

// MARK: - Auth (phone only)

/// Phone is the only way in. No password to reset, no third-party button, and
/// because there is no third-party login at all, App Store rule 4.8 (offer Sign
/// in with Apple alongside Google/Facebook) does not apply to us.
enum AuthService {
    static func sendCode(to phone: String) async throws {
        #if canImport(Supabase)
        if YogiBackend.shared.isConfigured {
            try await YogiBackend.shared.sendPhoneCode(phone)
            return
        }
        #endif
        // Demo mode: pretend, and accept any six digits at the next step.
        try await Task.sleep(for: .seconds(0.8))
    }

    static func verify(phone: String, code: String) async throws {
        #if canImport(Supabase)
        if YogiBackend.shared.isConfigured {
            try await YogiBackend.shared.verifyPhoneCode(phone: phone, code: code)
            return
        }
        #endif
        try await Task.sleep(for: .seconds(0.6))
        guard code.count == 6 else { throw BackendError.server("Enter the six digit code.") }
    }
}
