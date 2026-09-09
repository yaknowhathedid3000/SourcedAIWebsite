import Foundation

// The Supabase-backed data layer. Everything here is behind `canImport(Supabase)`
// so the project also builds before the package is resolved; without it the app
// runs fully local on AppState + sample data.
//
// Package: https://github.com/supabase/supabase-swift (product "Supabase"), declared in project.yml.
// Config: SUPABASE_URL and SUPABASE_ANON_KEY in Resources/Yogi.xcconfig, surfaced through Info.plist.

enum BackendConfig {
    static var url: URL? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String, !s.isEmpty, !s.contains("YOUR-PROJECT") else { return nil }
        return URL(string: s)
    }
    static var anonKey: String? {
        guard let s = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String, !s.isEmpty, !s.hasPrefix("YOUR") else { return nil }
        return s
    }
    static var isConfigured: Bool { url != nil && anonKey != nil }
}

/// Row shapes that match the SQL schema exactly (snake_case via the decoder).
struct SaveRecord: Codable, Identifiable {
    var id: UUID
    var ownerId: UUID
    var category: SaveCategory
    var title: String
    var subtitle: String?
    var coverUrl: String?
    var coverEmoji: String?
    var coverTint: Int
    var sourceUrl: String?
    var sourcePlatform: SourcePlatform
    var status: SaveStatus
    var privateNote: String?
    var noteBody: String?
    var recipe: RecipeDetails?
    var place: PlaceDetails?
    var event: EventDetails?
    var media: MediaDetails?
    var isImporting: Bool
    var mentionedInNoteId: UUID?
    var createdAt: Date

    init(from save: Save, ownerId: UUID) {
        id = save.id; self.ownerId = ownerId; category = save.category; title = save.title; subtitle = save.subtitle
        coverUrl = nil; coverEmoji = save.coverEmoji; coverTint = Int(save.coverTint); sourceUrl = save.sourceURL?.absoluteString
        sourcePlatform = save.sourcePlatform; status = save.status; privateNote = save.privateNote; noteBody = save.noteBody
        recipe = save.recipe; place = save.place; event = save.event; media = save.media; isImporting = save.isImporting
        mentionedInNoteId = save.mentionedInNoteID; createdAt = save.createdAt
    }

    var save: Save {
        Save(id: id, category: category, title: title, subtitle: subtitle, coverEmoji: coverEmoji, coverTint: UInt32(max(0, coverTint)),
             sourceURL: sourceUrl.flatMap(URL.init(string:)), sourcePlatform: sourcePlatform, status: status, saveCount: 1, createdAt: createdAt,
             privateNote: privateNote, noteBody: noteBody, recipe: recipe, place: place, event: event, media: media, isImporting: isImporting,
             mentionedInNoteID: mentionedInNoteId)
    }
}

struct ProfileRow: Codable {
    var id: UUID
    var handle: String
    var name: String
    var bio: String
    var avatarMascot: String
    var instagram: String
    var tiktok: String
    var country: String?
    var isPrivate: Bool
    var entitlement: Entitlement
    var credits: Int
    var streakWeeks: Int
    var lastDoneAt: Date?
}

struct ReviewRow: Codable, Identifiable {
    var id: UUID
    var ownerId: UUID
    var saveId: UUID
    var sentiment: Sentiment
    var title: String?
    var stars: Int?
    var completedOn: String?
    var friendsOnly: Bool
    var createdAt: Date

    var review: Review {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return Review(id: id, saveID: saveId, sentiment: sentiment, title: title, stars: stars, completedOn: completedOn.flatMap { f.date(from: $0) }, friendsOnly: friendsOnly, createdAt: createdAt)
    }
}

struct CollectionRecord: Codable, Identifiable {
    var id: UUID
    var ownerId: UUID
    var name: String
    var details: String?
    var coverEmoji: String
    var coverTint: Int
    var isPublic: Bool
    var inviteToken: String?
}

struct ExtractResponse: Decodable { var saves: [SaveRecord] }
struct AskResponse: Decodable { var answer: String }

enum BackendError: LocalizedError {
    case notConfigured, notSignedIn, outOfCredits, proRequired, server(String)
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Backend is not configured. Add SUPABASE_URL and SUPABASE_ANON_KEY to Yogi.xcconfig."
        case .notSignedIn: return "Sign in to sync your saves."
        case .outOfCredits: return "You're out of imports. Start a free trial for unlimited saves."
        case .proRequired: return "AI chat is a Pro feature."
        case .server(let m): return m
        }
    }
}

#if canImport(Supabase)
import Supabase

/// One shared client. Auth state changes are observed by `SyncEngine`.
@MainActor
final class YogiBackend {
    static let shared = YogiBackend()

    let client: SupabaseClient?
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            if let d = iso.date(from: s) ?? isoPlain.date(from: s) { return d }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "bad date \(s)"))
        }
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private init() {
        if let url = BackendConfig.url, let key = BackendConfig.anonKey {
            client = SupabaseClient(supabaseURL: url, supabaseKey: key, options: .init(db: .init(encoder: encoder, decoder: decoder)))
        } else {
            client = nil
        }
    }

    var isConfigured: Bool { client != nil }

    private func db() throws -> SupabaseClient {
        guard let client else { throw BackendError.notConfigured }
        return client
    }

    // MARK: Auth (Albo #45, #46)

    var currentUserID: UUID? {
        get async { try? await client?.auth.session.user.id }
    }

    /// Sends the SMS one-time code. Supabase creates the user on first verify,
    /// so there is no separate sign-up path.
    func sendPhoneCode(_ phone: String) async throws {
        try await db().auth.signInWithOTP(phone: phone)
    }

    func verifyPhoneCode(phone: String, code: String) async throws {
        _ = try await db().auth.verifyOTP(phone: phone, token: code, type: .sms)
    }


    func signOut() async {
        try? await client?.auth.signOut()
    }

    // MARK: Profile

    func fetchProfile() async throws -> ProfileRow {
        let uid = try await requireUser()
        return try await db().from("profiles").select().eq("id", value: uid.uuidString).single().execute().value
    }

    func updateProfile(_ p: UserProfile) async throws {
        let uid = try await requireUser()
        struct Patch: Encodable { var handle: String; var name: String; var bio: String; var avatarMascot: String; var instagram: String; var tiktok: String; var country: String; var isPrivate: Bool }
        let patch = Patch(handle: p.handle, name: p.name, bio: p.bio, avatarMascot: p.mascot.rawValue, instagram: p.instagram, tiktok: p.tiktok, country: p.country, isPrivate: p.isPrivate)
        _ = try await db().from("profiles").update(patch).eq("id", value: uid.uuidString).execute()
    }

    // MARK: Saves

    func fetchSaves() async throws -> [SaveRecord] {
        let uid = try await requireUser()
        return try await db().from("saves").select().eq("owner_id", value: uid.uuidString).order("created_at", ascending: false).execute().value
    }

    func upsert(_ save: Save) async throws {
        let uid = try await requireUser()
        _ = try await db().from("saves").upsert(SaveRecord(from: save, ownerId: uid)).execute()
    }

    func delete(saveID: UUID) async throws {
        _ = try await db().from("saves").delete().eq("id", value: saveID.uuidString).execute()
    }

    func search(_ query: String) async throws -> [SaveRecord] {
        try await db().rpc("search_saves", params: ["p_query": query]).execute().value
    }

    // MARK: Collections

    func fetchCollections() async throws -> [CollectionRecord] {
        try await db().from("collections").select().order("created_at", ascending: false).execute().value
    }

    func fetchCollectionSaveIDs() async throws -> [(UUID, UUID)] {
        struct Row: Decodable { var collectionId: UUID; var saveId: UUID }
        let rows: [Row] = try await db().from("collection_saves").select("collection_id, save_id").execute().value
        return rows.map { ($0.collectionId, $0.saveId) }
    }

    func upsert(_ c: SaveCollection) async throws {
        let uid = try await requireUser()
        struct Row: Encodable { var id: UUID; var ownerId: UUID; var name: String; var details: String?; var coverEmoji: String; var coverTint: Int; var isPublic: Bool }
        _ = try await db().from("collections").upsert(Row(id: c.id, ownerId: uid, name: c.name, details: c.details, coverEmoji: c.coverEmoji, coverTint: Int(c.coverTint), isPublic: c.isPublic)).execute()
    }

    func setMembership(saveID: UUID, collectionID: UUID, isMember: Bool) async throws {
        if isMember {
            struct Row: Encodable { var collectionId: UUID; var saveId: UUID }
            _ = try await db().from("collection_saves").upsert(Row(collectionId: collectionID, saveId: saveID)).execute()
        } else {
            _ = try await db().from("collection_saves").delete().eq("collection_id", value: collectionID.uuidString).eq("save_id", value: saveID.uuidString).execute()
        }
    }

    func joinCollection(token: String) async throws -> UUID {
        try await db().rpc("join_collection", params: ["p_token": token]).execute().value
    }

    // MARK: Reviews (Albo #83 -> submit_review RPC)

    func submit(_ review: Review) async throws -> (reviewID: UUID, streakWeeks: Int) {
        struct Params: Encodable {
            var pSaveId: UUID; var pSentiment: String; var pTitle: String?; var pStars: Int?; var pCompletedOn: String?; var pFriendsOnly: Bool; var pTagged: [UUID]; var pPhotoPaths: [String]
        }
        struct Result: Decodable { var reviewId: UUID; var streakWeeks: Int }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let params = Params(pSaveId: review.saveID, pSentiment: review.sentiment.rawValue, pTitle: review.title, pStars: review.stars,
                            pCompletedOn: review.completedOn.map { f.string(from: $0) }, pFriendsOnly: review.friendsOnly,
                            pTagged: review.taggedFriends.map(\.id), pPhotoPaths: [])
        let rows: [Result] = try await db().rpc("submit_review", params: params).execute().value
        guard let r = rows.first else { throw BackendError.server("submit_review returned nothing") }
        return (r.reviewId, r.streakWeeks)
    }

    func fetchReviews() async throws -> [ReviewRow] {
        let uid = try await requireUser()
        return try await db().from("reviews").select().eq("owner_id", value: uid.uuidString).order("created_at", ascending: false).execute().value
    }

    // MARK: Gamification

    func claim(task id: String) async throws -> Int {
        try await db().rpc("claim_task", params: ["p_task_id": id]).execute().value
    }

    func advance(task id: String) async throws {
        struct P: Encodable { var pTaskId: String; var pAmount: Int }
        _ = try await db().rpc("advance_task", params: P(pTaskId: id, pAmount: 1)).execute()
    }

    func redeemReferral(_ code: String) async throws -> Int {
        try await db().rpc("redeem_referral", params: ["p_code": code]).execute().value
    }

    // MARK: Reminders

    func setReminder(saveID: UUID, fireAt: Date, slot: ReminderSlot) async throws {
        let uid = try await requireUser()
        struct Row: Encodable { var ownerId: UUID; var saveId: UUID; var fireAt: Date; var slot: String }
        _ = try await db().from("reminders").upsert(Row(ownerId: uid, saveId: saveID, fireAt: fireAt, slot: slot.rawValue), onConflict: "owner_id,save_id").execute()
    }

    // MARK: Social

    func follow(_ userID: UUID) async throws {
        let uid = try await requireUser()
        struct Row: Encodable { var followerId: UUID; var followeeId: UUID }
        _ = try await db().from("follows").upsert(Row(followerId: uid, followeeId: userID)).execute()
    }

    func unfollow(_ userID: UUID) async throws {
        let uid = try await requireUser()
        _ = try await db().from("follows").delete().eq("follower_id", value: uid.uuidString).eq("followee_id", value: userID.uuidString).execute()
    }

    // MARK: Edge functions

    /// Request bodies use explicit snake_case keys because the Functions client
    /// encodes with its own JSONEncoder, not the database one above.
    struct ExtractRequest: Encodable {
        var kind: String
        var url: String? = nil
        var title: String? = nil
        var body: String? = nil
        var noteId: String? = nil
        var paths: [String]? = nil
        enum CodingKeys: String, CodingKey { case kind, url, title, body, noteId = "note_id", paths }
    }

    struct AskRequest: Encodable {
        struct Turn: Encodable { var role: String; var content: String }
        var question: String
        var saveId: String?
        var history: [Turn]
        enum CodingKeys: String, CodingKey { case question, saveId = "save_id", history }
    }

    /// Magic import (Albo #25). Throws `.outOfCredits` on 402.
    func extract(url: URL) async throws -> [SaveRecord] {
        try await invokeExtract(ExtractRequest(kind: "url", url: url.absoluteString))
    }

    func extract(noteID: UUID, title: String, body: String) async throws -> [SaveRecord] {
        try await invokeExtract(ExtractRequest(kind: "note", title: title, body: body, noteId: noteID.uuidString))
    }

    func extract(screenshotPaths: [String]) async throws -> [SaveRecord] {
        try await invokeExtract(ExtractRequest(kind: "screenshots", paths: screenshotPaths))
    }

    private func invokeExtract(_ request: ExtractRequest) async throws -> [SaveRecord] {
        do {
            let response: ExtractResponse = try await db().functions.invoke("extract", options: FunctionInvokeOptions(body: request), decoder: decoder)
            return response.saves
        } catch let error as FunctionsError {
            if case .httpError(let code, _) = error, code == 402 { throw BackendError.outOfCredits }
            throw BackendError.server(error.localizedDescription)
        }
    }

    /// Ask Yogi (Albo #57, #93). Throws `.proRequired` on 402.
    func ask(_ question: String, saveID: UUID?, history: [ChatMessage]) async throws -> String {
        let request = AskRequest(question: question, saveId: saveID?.uuidString,
                                 history: history.map { AskRequest.Turn(role: $0.role == .user ? "user" : "assistant", content: $0.text) })
        do {
            let response: AskResponse = try await db().functions.invoke("ask-yogi", options: FunctionInvokeOptions(body: request), decoder: decoder)
            return response.answer
        } catch let error as FunctionsError {
            if case .httpError(let code, _) = error, code == 402 { throw BackendError.proRequired }
            throw BackendError.server(error.localizedDescription)
        }
    }

    // MARK: Storage

    /// Uploads a screenshot into the private `imports` bucket under the user's folder and returns its path.
    func uploadImport(_ data: Data, ext: String = "jpg") async throws -> String {
        let uid = try await requireUser()
        let path = "\(uid.uuidString)/\(UUID().uuidString).\(ext)"
        _ = try await db().storage.from("imports").upload(path, data: data, options: FileOptions(contentType: ext == "png" ? "image/png" : "image/jpeg"))
        return path
    }

    // MARK: Helpers

    private func requireUser() async throws -> UUID {
        guard let uid = await currentUserID else { throw BackendError.notSignedIn }
        return uid
    }
}

/// Pulls the user's library after sign-in and pushes local mutations. Wire it by
/// calling `SyncEngine.shared.start(app:)` from `YogiApp` once the package is added.
@MainActor
final class SyncEngine {
    static let shared = SyncEngine()
    private var task: Task<Void, Never>?

    func start(app: AppState) {
        guard YogiBackend.shared.isConfigured else { return }
        task?.cancel()
        task = Task {
            await pull(into: app)
        }
    }

    func pull(into app: AppState) async {
        do {
            let backend = YogiBackend.shared
            let profile = try await backend.fetchProfile()
            var p = app.profile
            p.name = profile.name; p.handle = profile.handle; p.bio = profile.bio; p.instagram = profile.instagram; p.tiktok = profile.tiktok
            p.country = profile.country ?? p.country; p.isPrivate = profile.isPrivate; p.mascot = MascotVariant(rawValue: profile.avatarMascot) ?? .plain
            app.profile = p
            app.entitlement = profile.entitlement
            app.gamification.credits = profile.credits
            app.gamification.streakWeeks = profile.streakWeeks

            let saves = try await backend.fetchSaves()
            if !saves.isEmpty { app.saves = saves.map(\.save) }

            let collections = try await backend.fetchCollections()
            let membership = try await backend.fetchCollectionSaveIDs()
            if !collections.isEmpty {
                app.collections = collections.map { c in
                    SaveCollection(id: c.id, name: c.name, details: c.details, coverEmoji: c.coverEmoji, coverTint: UInt32(max(0, c.coverTint)), isPublic: c.isPublic,
                                   owner: app.me, saveIDs: membership.filter { $0.0 == c.id }.map(\.1), inviteURL: c.inviteToken.flatMap { URL(string: "https://join.yogi.app/\($0)") })
                }
            }
            let reviews = try await backend.fetchReviews()
            if !reviews.isEmpty { app.reviews = reviews.map(\.review) }
        } catch {
            app.showToast(error.localizedDescription)
        }
    }

    func push(_ save: Save) {
        guard YogiBackend.shared.isConfigured else { return }
        Task { try? await YogiBackend.shared.upsert(save) }
    }
}
#endif
