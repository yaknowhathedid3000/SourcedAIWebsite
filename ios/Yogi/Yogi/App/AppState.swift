import Foundation
import Observation
import SwiftUI
import UIKit

enum AppTab: Hashable {
    case library, map, add, community, profile
}

/// Single source of truth for the app. Views read it from the environment.
/// Persistence is UserDefaults-backed JSON for now; swap `Store` for SwiftData
/// in an App Group when the share extension lands (teardown 16.7).
@MainActor
@Observable
final class AppState {
    // Navigation
    var tab: AppTab = .library
    var showAddSheet = false
    var showAskYogi = false
    var showGetStarted = false
    var showPaywall = false
    var pendingDetailID: UUID?

    // Session
    var hasOnboarded: Bool { didSet { store.set(hasOnboarded, for: "hasOnboarded") } }
    var isSignedIn: Bool { didSet { store.set(isSignedIn, for: "isSignedIn") } }
    var entitlement: Entitlement { didSet { store.set(entitlement, for: "entitlement") } }
    var profile: UserProfile { didSet { store.set(profile, for: "profile") } }
    var answers: OnboardingAnswers { didSet { store.set(answers, for: "answers") } }
    var theme: AppTheme { didSet { store.set(theme, for: "theme") } }
    var languageCode: String { didSet { store.set(languageCode, for: "language") } }
    var defaultMap: MapApp { didSet { store.set(defaultMap, for: "defaultMap") } }
    var defaultReminderSlot: ReminderSlot { didSet { store.set(defaultReminderSlot, for: "reminderSlot") } }
    var notificationPrefs: NotificationPrefs { didSet { store.set(notificationPrefs, for: "notificationPrefs") } }
    var hasSeenFirstImportCoach: Bool { didSet { store.set(hasSeenFirstImportCoach, for: "firstImportCoach") } }
    var hasSeenLocationWarmup: Bool { didSet { store.set(hasSeenLocationWarmup, for: "locationWarmup") } }

    // Content
    var saves: [Save] { didSet { store.set(saves, for: "saves") } }
    var collections: [SaveCollection] { didSet { store.set(collections, for: "collections") } }
    var lists: [CuratedList] { didSet { store.set(lists, for: "lists") } }
    var trips: [Trip] { didSet { store.set(trips, for: "trips") } }
    var reviews: [Review] { didSet { store.set(reviews, for: "reviews") } }
    var reminders: [Reminder] { didSet { store.set(reminders, for: "reminders") } }
    var notifications: [AppNotification] { didSet { store.set(notifications, for: "notifications") } }
    var gamification: GamificationState { didSet { store.set(gamification, for: "gamification") } }
    var following: [UserSummary] { didSet { store.set(following, for: "following") } }

    // Transient
    var toast: String?
    var streakToShow: Int?

    @ObservationIgnored private let store = Store()
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init() {
        hasOnboarded = store.get(Bool.self, for: "hasOnboarded") ?? false
        isSignedIn = store.get(Bool.self, for: "isSignedIn") ?? false
        entitlement = store.get(Entitlement.self, for: "entitlement") ?? .free
        profile = store.get(UserProfile.self, for: "profile") ?? UserProfile(name: "Julia", handle: "juliascreens", email: "screensdesigntest@gmail.com", instagram: "juliascreens")
        answers = store.get(OnboardingAnswers.self, for: "answers") ?? OnboardingAnswers()
        theme = store.get(AppTheme.self, for: "theme") ?? .system
        languageCode = store.get(String.self, for: "language") ?? "system"
        defaultMap = store.get(MapApp.self, for: "defaultMap") ?? .apple
        defaultReminderSlot = store.get(ReminderSlot.self, for: "reminderSlot") ?? .morning
        notificationPrefs = store.get(NotificationPrefs.self, for: "notificationPrefs") ?? NotificationPrefs()
        hasSeenFirstImportCoach = store.get(Bool.self, for: "firstImportCoach") ?? false
        hasSeenLocationWarmup = store.get(Bool.self, for: "locationWarmup") ?? false
        saves = store.get([Save].self, for: "saves") ?? SampleData.saves
        collections = store.get([SaveCollection].self, for: "collections") ?? SampleData.collections
        lists = store.get([CuratedList].self, for: "lists") ?? SampleData.lists
        trips = store.get([Trip].self, for: "trips") ?? SampleData.trips
        reviews = store.get([Review].self, for: "reviews") ?? SampleData.reviews
        reminders = store.get([Reminder].self, for: "reminders") ?? []
        notifications = store.get([AppNotification].self, for: "notifications") ?? []
        gamification = store.get(GamificationState.self, for: "gamification") ?? GamificationState(credits: 20, streakWeeks: 0, checklist: SampleData.checklist, stamps: SampleData.stamps)
        following = store.get([UserSummary].self, for: "following") ?? [SampleData.kimmy]
    }

    // MARK: Lookups

    var me: UserSummary { profile.summary }

    func save(_ id: UUID) -> Save? { saves.first { $0.id == id } }

    func binding(for id: UUID) -> Binding<Save>? {
        guard let index = saves.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.saves[index] },
            set: { self.saves[index] = $0 }
        )
    }

    func saves(in category: SaveCategory) -> [Save] {
        saves.filter { $0.category == category }.sorted { $0.createdAt > $1.createdAt }
    }

    var recentSaves: [Save] { saves.sorted { $0.createdAt > $1.createdAt } }

    func reviews(for id: UUID) -> [Review] { reviews.filter { $0.saveID == id }.sorted { $0.createdAt > $1.createdAt } }

    func latestReview(for id: UUID) -> Review? { reviews(for: id).first }

    func collections(containing id: UUID) -> [SaveCollection] { collections.filter { $0.saveIDs.contains(id) } }

    func reminder(for id: UUID) -> Reminder? { reminders.first { $0.saveID == id } }

    var journal: [Review] { reviews.sorted { $0.createdAt > $1.createdAt } }

    func journal(for category: SaveCategory) -> [Review] {
        journal.filter { save($0.saveID)?.category == category }
    }

    // MARK: Mutations

    func update(_ save: Save) {
        guard let i = saves.firstIndex(where: { $0.id == save.id }) else { return }
        saves[i] = save
    }

    func add(_ save: Save) {
        saves.insert(save, at: 0)
        advance(task: "import5")
        var s = gamification.stamps
        if let i = s.firstIndex(where: { $0.id == "hoarder" }) { s[i].progress = min(s[i].target, s[i].progress + 1) }
        gamification.stamps = s
    }

    /// Writes an event save into the system calendar. EventKit access is
    /// requested lazily, so declining just leaves the save where it was.
    func addToCalendar(_ save: Save) {
        guard let event = save.event else { return }
        NotificationService.addEventToCalendar(title: save.title,
                                               start: event.start,
                                               end: event.end,
                                               location: event.address ?? event.venue) { [weak self] ok in
            self?.showToast(ok ? "Added to your calendar" : "Calendar access is off in Settings")
        }
    }

    /// The places in a trip, in the order they were added.
    func places(in trip: Trip) -> [Save] {
        trip.saveIDs.compactMap { id in saves.first { $0.id == id } }
    }

    func remove(_ id: UUID) {
        saves.removeAll { $0.id == id }
        for i in collections.indices { collections[i].saveIDs.removeAll { $0 == id } }
        for i in lists.indices { lists[i].saveIDs.removeAll { $0 == id } }
        reviews.removeAll { $0.saveID == id }
        reminders.removeAll { $0.saveID == id }
    }

    func setWant(_ id: UUID) {
        guard var s = save(id) else { return }
        s.status = s.status == .wantTo ? .saved : .wantTo
        update(s)
        showToast(s.status == .wantTo ? "Added to \(s.category.wantsSectionTitle)" : "Removed from \(s.category.wantsSectionTitle)")
    }

    /// Submitting "How was it?" marks the save done, stores the review, and extends the streak (Albo #78, #85).
    func submit(_ review: Review) {
        guard var s = save(review.saveID) else { return }
        s.status = .done
        update(s)
        reviews.insert(review, at: 0)
        extendStreak()
        advance(task: "review")
        Haptics.success()
        showToast("Marked as complete")
    }

    private func extendStreak() {
        let cal = Calendar.current
        if let last = gamification.lastDoneAt, cal.isDate(last, equalTo: Date(), toGranularity: .weekOfYear) {
            // Same week, streak unchanged.
        } else if let last = gamification.lastDoneAt, let nextWeek = cal.date(byAdding: .weekOfYear, value: 1, to: last), cal.isDate(nextWeek, equalTo: Date(), toGranularity: .weekOfYear) {
            gamification.streakWeeks += 1
        } else {
            gamification.streakWeeks = 1
        }
        gamification.lastDoneAt = Date()
        streakToShow = gamification.streakWeeks
    }

    func setPrivateNote(_ text: String, for id: UUID) {
        guard var s = save(id) else { return }
        s.privateNote = text.isEmpty ? nil : text
        update(s)
    }

    func deleteComment(_ commentID: UUID, from saveID: UUID) {
        guard var s = save(saveID) else { return }
        s.comments.removeAll { $0.id == commentID }
        update(s)
    }

    func addComment(_ text: String, to id: UUID) {
        guard var s = save(id), !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        s.comments.append(Comment(author: me, text: text))
        update(s)
    }

    // Collections
    @discardableResult
    func createCollection(name: String, details: String?, coverEmoji: String, isPublic: Bool, firstSave: UUID?) -> SaveCollection {
        var c = SaveCollection(name: name, details: details, coverEmoji: coverEmoji, isPublic: isPublic, owner: me)
        if let firstSave { c.saveIDs = [firstSave] }
        collections.insert(c, at: 0)
        return c
    }

    func toggle(_ saveID: UUID, in collectionID: UUID) {
        guard let i = collections.firstIndex(where: { $0.id == collectionID }) else { return }
        if collections[i].saveIDs.contains(saveID) {
            collections[i].saveIDs.removeAll { $0 == saveID }
        } else {
            collections[i].saveIDs.append(saveID)
        }
    }

    // Lists
    func upsert(_ list: CuratedList) {
        if let i = lists.firstIndex(where: { $0.id == list.id }) { lists[i] = list } else { lists.insert(list, at: 0); advance(task: "list") }
    }

    // Reminders
    func setReminder(for id: UUID, at date: Date, slot: ReminderSlot) {
        reminders.removeAll { $0.saveID == id }
        let r = Reminder(saveID: id, fireAt: date, slot: slot)
        reminders.append(r)
        if let s = save(id) {
            NotificationService.schedule(reminder: r, title: "Reminder: \(s.title)", body: s.metaLine)
            notifications.insert(AppNotification(title: "Reminder: \(s.title)", body: s.metaLine, saveID: id), at: 0)
        }
        let f = DateFormatter(); f.dateFormat = "EEE d MMM"
        showToast("Reminder set for \(f.string(from: date))")
    }

    // Gamification
    func advance(task id: String, by amount: Int = 1) {
        guard let i = gamification.checklist.firstIndex(where: { $0.id == id }) else { return }
        gamification.checklist[i].progress = min(gamification.checklist[i].target, gamification.checklist[i].progress + amount)
    }

    func claim(task id: String) {
        guard let i = gamification.checklist.firstIndex(where: { $0.id == id }), gamification.checklist[i].isComplete, !gamification.checklist[i].isClaimed else { return }
        gamification.checklist[i].isClaimed = true
        gamification.credits += gamification.checklist[i].reward
        Haptics.success()
        showToast("+\(gamification.checklist[i].reward) credits")
    }

    // Social
    func toggleFollow(_ user: UserSummary) {
        if following.contains(where: { $0.handle == user.handle }) {
            following.removeAll { $0.handle == user.handle }
        } else {
            following.append(user)
        }
    }

    func isFollowing(_ user: UserSummary) -> Bool { following.contains { $0.handle == user.handle } }

    // Session
    func signOut() {
        isSignedIn = false
        hasOnboarded = false
    }

    func resetForDeletion() {
        store.clear()
        saves = SampleData.saves
        collections = SampleData.collections
        lists = SampleData.lists
        reviews = SampleData.reviews
        reminders = []
        notifications = []
        gamification = GamificationState(credits: 20, streakWeeks: 0, checklist: SampleData.checklist, stamps: SampleData.stamps)
        entitlement = .free
        isSignedIn = false
        hasOnboarded = false
    }

    // Toast
    func showToast(_ message: String) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = message }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) { self?.toast = nil }
            }
        }
    }
}

// MARK: - Settings enums

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    var systemImage: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "iphone"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum MapApp: String, Codable, CaseIterable, Identifiable {
    case apple, google
    var id: String { rawValue }
    var title: String { self == .apple ? "Apple Maps" : "Google Maps" }
}

struct NotificationPrefs: Codable, Hashable {
    var enabled = true
    var location = false
    var reminders = true
    var social = true
    var marketing = false
}

// MARK: - Tiny JSON store

/// UserDefaults-backed JSON persistence. Good enough until SwiftData in an App Group.
final class Store {
    private let defaults = UserDefaults.standard
    private let prefix = "yogi."

    func set<T: Encodable>(_ value: T, for key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: prefix + key)
        }
    }

    func get<T: Decodable>(_ type: T.Type, for key: String) -> T? {
        guard let data = defaults.data(forKey: prefix + key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func clear() {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
