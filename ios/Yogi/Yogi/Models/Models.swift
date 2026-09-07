import Foundation

// MARK: - Categories (teardown 2.2)

enum SaveCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case recipe, place, film, book, product, workout, software, tvShow, event, article, tutorial, game, note, image

    var id: String { rawValue }

    /// The 12 categories shown in the review picker and library chip row (Albo #104).
    static let browsable: [SaveCategory] = [.recipe, .place, .film, .book, .product, .workout, .software, .tvShow, .event, .article, .tutorial, .game]

    /// The six list types (Albo #108).
    static let listable: [SaveCategory] = [.recipe, .place, .film, .book, .workout, .tvShow]

    var title: String {
        switch self {
        case .recipe: return "Recipe"
        case .place: return "Place"
        case .film: return "Film"
        case .book: return "Book"
        case .product: return "Product"
        case .workout: return "Workout"
        case .software: return "Software"
        case .tvShow: return "TV Show"
        case .event: return "Event"
        case .article: return "Article"
        case .tutorial: return "Tutorial"
        case .game: return "Game"
        case .note: return "Note"
        case .image: return "Image"
        }
    }

    var pluralTitle: String {
        switch self {
        case .recipe: return "Recipes"
        case .place: return "Places"
        case .film: return "Films"
        case .book: return "Books"
        case .product: return "Products"
        case .workout: return "Workouts"
        case .software: return "Software"
        case .tvShow: return "TV Shows"
        case .event: return "Events"
        case .article: return "Articles"
        case .tutorial: return "Tutorials"
        case .game: return "Games"
        case .note: return "Notes"
        case .image: return "Images"
        }
    }

    /// Emoji stand-ins for Albo's 3D icons (Dutch oven, map, VHS, ...).
    var emoji: String {
        switch self {
        case .recipe: return "🍲"
        case .place: return "🗺️"
        case .film: return "📼"
        case .book: return "📚"
        case .product: return "🧺"
        case .workout: return "🏋️"
        case .software: return "🖥️"
        case .tvShow: return "📺"
        case .event: return "🎟️"
        case .article: return "📰"
        case .tutorial: return "📐"
        case .game: return "🎮"
        case .note: return "📝"
        case .image: return "🖼️"
        }
    }

    /// "Made it?", "Visited?" slide-to-confirm label (Albo #69, #137).
    var doneQuestion: String {
        switch self {
        case .recipe: return "Made it?"
        case .place, .event: return "Visited?"
        case .film, .tvShow: return "Watched?"
        case .book, .article, .tutorial: return "Read?"
        case .workout: return "Done it?"
        case .product: return "Bought it?"
        case .game, .software: return "Tried it?"
        case .note, .image: return "Done?"
        }
    }

    /// Category view tabs: All / Want to try / Made (Albo #113).
    var wantTab: String {
        switch self {
        case .place, .event: return "Want to go"
        case .film, .tvShow: return "Want to watch"
        case .book, .article: return "Want to read"
        default: return "Want to try"
        }
    }

    var doneTab: String {
        switch self {
        case .recipe: return "Made"
        case .place, .event: return "Visited"
        case .film, .tvShow: return "Watched"
        case .book, .article, .tutorial: return "Read"
        default: return "Done"
        }
    }

    /// Journal sentence verb: "Cooked Carbonara", "Visited London", "Read Project Hail Mary" (Albo #186, #188).
    var journalVerb: String {
        switch self {
        case .recipe: return "Cooked"
        case .place, .event: return "Visited"
        case .film, .tvShow: return "Watched"
        case .book, .article, .tutorial: return "Read"
        case .workout: return "Did"
        case .product: return "Bought"
        case .game, .software: return "Tried"
        case .note, .image: return "Finished"
        }
    }

    /// "Wants to Try" / "Wants to Go" profile section (Albo #185, #188).
    var wantsSectionTitle: String {
        switch self {
        case .place, .event: return "Wants to Go"
        case .film, .tvShow: return "Wants to Watch"
        case .book, .article: return "Wants to Read"
        default: return "Wants to Try"
        }
    }

    /// Category view subtitle: "All the recipes found in your library".
    var librarySubtitle: String { "All the \(pluralTitle.lowercased()) found in your library" }

    /// Word highlighted in the feature carousel headline (Albo #15).
    var highlightWord: String {
        switch self {
        case .place: return "spot"
        default: return title.lowercased()
        }
    }
}

enum SaveStatus: String, Codable, Hashable {
    case saved, wantTo, done
}

enum SourcePlatform: String, Codable, Hashable, CaseIterable {
    case tiktok, instagram, safari, facebook, youtube, linkedin, pinterest, threads, screenshot, note, manual

    var title: String {
        switch self {
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .safari: return "Safari"
        case .facebook: return "Facebook"
        case .youtube: return "YouTube"
        case .linkedin: return "LinkedIn"
        case .pinterest: return "Pinterest"
        case .threads: return "Threads"
        case .screenshot: return "Images"
        case .note: return "Markdown"
        case .manual: return "Web"
        }
    }

    /// Card eyebrow label in "Recently saved" (Albo #99: "Images", "Markdown", "Web").
    var cardLabel: String {
        switch self {
        case .screenshot: return "Images"
        case .note: return "Markdown"
        case .safari, .manual: return "Web"
        default: return title
        }
    }

    /// The eight platforms offered in the first-import picker (Albo #48).
    static let importable: [SourcePlatform] = [.tiktok, .instagram, .safari, .facebook, .youtube, .linkedin, .pinterest, .threads]

    var emoji: String {
        switch self {
        case .tiktok: return "🎵"
        case .instagram: return "📸"
        case .safari: return "🧭"
        case .facebook: return "📘"
        case .youtube: return "▶️"
        case .linkedin: return "💼"
        case .pinterest: return "📌"
        case .threads: return "🧵"
        case .screenshot: return "🖼️"
        case .note: return "📝"
        case .manual: return "🌐"
        }
    }
}

// MARK: - Save

struct Ingredient: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var emoji: String
    var name: String
    var quantity: Double?
    var unit: String?
    var checked: Bool = false

    init(id: UUID = UUID(), emoji: String, name: String, quantity: Double? = nil, unit: String? = nil, checked: Bool = false) {
        self.id = id; self.emoji = emoji; self.name = name; self.quantity = quantity; self.unit = unit; self.checked = checked
    }

    /// Tolerant decoding: rows extracted server-side carry no `id` or `checked`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "•"
        name = try c.decode(String.self, forKey: .name)
        quantity = try c.decodeIfPresent(Double.self, forKey: .quantity)
        unit = try c.decodeIfPresent(String.self, forKey: .unit)
        checked = try c.decodeIfPresent(Bool.self, forKey: .checked) ?? false
    }

    /// "1 cup", "10 pieces", "1/3 cup" rendered for a multiplier.
    func quantityLabel(multiplier: Int) -> String? {
        guard let quantity else { return nil }
        let q = quantity * Double(multiplier)
        let text: String
        if q == q.rounded() {
            text = String(Int(q))
        } else if abs(q - 0.5) < 0.01 { text = "1/2" }
        else if abs(q - 0.25) < 0.01 { text = "1/4" }
        else if abs(q - 0.75) < 0.01 { text = "3/4" }
        else if abs(q - (1.0 / 3.0)) < 0.01 { text = "1/3" }
        else if abs(q - (2.0 / 3.0)) < 0.01 { text = "2/3" }
        else { text = String(format: "%.1f", q) }
        if let unit, !unit.isEmpty { return "\(text) \(unit)" }
        return text
    }
}

struct RecipeDetails: Codable, Hashable {
    var timeLabel: String          // "15 mins", "Multi-day project"
    var cuisine: String?           // "American"
    var course: String?            // "Dessert"
    var yieldLabel: String?        // "Makes 12 cookies", "Serves 4-6"
    var ingredients: [Ingredient]
    var steps: [String]
    var stepEmoji: [String] = []   // small icon per step (egg, wheat, timer)
    var emoji: String = "🍪"
}

struct PlaceDetails: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var category: String           // "Soba noodle shop", "Association / Organization"
    var rating: Double?
    var priceLevel: String?        // "$$"
    var hoursLabel: String?        // "Opens Friday at 9 AM to 5 PM"
    var phone: String?
    var website: URL?
    var address: String?
    var neighborhood: String?      // "LENOX HILL"
    var city: String?
    var countryFlag: String?       // "🇬🇧"
    var emoji: String = "🏛️"
    var photoEmoji: [String] = []
    var about: String?
}

struct EventDetails: Codable, Hashable {
    var start: Date
    var end: Date?
    var venue: String
    var address: String?
    var organizer: String?
    var kind: String               // "Community"
    var about: String?
    var latitude: Double?
    var longitude: Double?
}

struct MediaDetails: Codable, Hashable {
    var year: Int?
    var genre: String?             // "Science fiction", "Comedy"
    var pages: Int?
    var rating: Double?
    var author: String?
    var runtimeLabel: String?
    var tags: [String] = []        // workouts: "Bodyweight", "Upper Body"
}

struct Reaction: Codable, Hashable, Identifiable {
    var id: String { emoji }
    var emoji: String
    var count: Int
}

struct Save: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var category: SaveCategory
    var title: String
    var subtitle: String?
    var coverEmoji: String?        // stands in for the cover image
    var coverTint: UInt32 = 0xEFEFEF
    var sourceURL: URL?
    var sourcePlatform: SourcePlatform = .manual
    var status: SaveStatus = .saved
    var saveCount: Int = 1
    var createdAt: Date = Date()
    var privateNote: String?
    var noteBody: String?          // markdown for .note saves
    var recipe: RecipeDetails?
    var place: PlaceDetails?
    var event: EventDetails?
    var media: MediaDetails?
    var isImporting: Bool = false
    var savedBy: [UserSummary] = []
    var reactions: [Reaction] = []
    var comments: [Comment] = []
    var mentionedInNoteID: UUID?

    /// Meta line: "15 mins · American · Dessert" or "Association / Organization · 4.2".
    var metaLine: String {
        if let r = recipe {
            return [r.timeLabel, r.cuisine, r.course].compactMap { $0 }.joined(separator: " · ")
        }
        if let p = place {
            var parts = [p.category]
            if let rating = p.rating { parts.append(String(format: "%.1f", rating)) }
            return parts.joined(separator: " · ")
        }
        if let e = event {
            return [Self.shortDate(e.start), e.kind, e.venue].joined(separator: " · ")
        }
        if let m = media {
            var parts: [String] = []
            if let g = m.genre { parts.append(g) }
            if let r = m.rating { parts.append(String(format: "%.1f", r)) }
            if let p = m.pages { parts.append("\(p) pages") }
            if let y = m.year, parts.isEmpty { parts.append(String(y)) }
            if !m.tags.isEmpty { parts.append(contentsOf: m.tags.prefix(2)) }
            return parts.joined(separator: " · ")
        }
        return subtitle ?? sourcePlatform.cardLabel
    }

    var metaEmoji: String {
        if let r = recipe { return r.emoji }
        if let p = place { return p.emoji }
        return category.emoji
    }

    static func shortDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f.string(from: d)
    }
}

struct Comment: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var author: UserSummary
    var text: String
    var createdAt: Date = Date()
    var likes: Int = 0
}

// MARK: - Collections and lists

struct SaveCollection: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var details: String?
    var coverEmoji: String = "📁"
    var coverTint: UInt32 = 0xF5891F
    var isPublic: Bool = true
    var owner: UserSummary
    var collaborators: [UserSummary] = []
    var saveIDs: [UUID] = []
    var inviteURL: URL? = URL(string: "https://join.yogi.app/invite")
}

struct CuratedList: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var category: SaveCategory
    var title: String
    var details: String?
    var isRanked: Bool = false
    var saveIDs: [UUID] = []
    var owner: UserSummary
    var coverEmoji: String = "📼"
}

// MARK: - Reviews (Albo #80 to #83)

enum Sentiment: String, Codable, CaseIterable, Identifiable, Hashable {
    case lovedIt, hiddenGem, itsOkay, meh, overhyped, notForMe, avoid
    var id: String { rawValue }

    var title: String {
        switch self {
        case .lovedIt: return "Loved it"
        case .hiddenGem: return "Hidden gem"
        case .itsOkay: return "It's okay"
        case .meh: return "Meh"
        case .overhyped: return "Overhyped"
        case .notForMe: return "Not for me"
        case .avoid: return "Avoid"
        }
    }

    var emoji: String {
        switch self {
        case .lovedIt: return "❤️"
        case .hiddenGem: return "💎"
        case .itsOkay: return "🙂"
        case .meh: return "😐"
        case .overhyped: return "🤯"
        case .notForMe: return "🤷"
        case .avoid: return "🚫"
        }
    }

    /// Journal suffix: "Cooked Carbonara, loved it" / "a hidden gem" (Albo #186).
    var journalSuffix: String {
        switch self {
        case .lovedIt: return "loved it"
        case .hiddenGem: return "a hidden gem"
        case .itsOkay: return "it's okay"
        case .meh: return "meh"
        case .overhyped: return "overhyped"
        case .notForMe: return "not for me"
        case .avoid: return "avoid"
        }
    }

    var badgeTitle: String {
        switch self {
        case .hiddenGem: return "Hidden Gem"
        default: return title
        }
    }
}

struct Review: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var saveID: UUID
    var sentiment: Sentiment
    var title: String?
    var stars: Int?
    var completedOn: Date?         // nil == "Don't remember"
    var photoCount: Int = 0
    var taggedFriends: [UserSummary] = []
    var friendsOnly: Bool = false
    var createdAt: Date = Date()
}

// MARK: - Reminders (Albo #92, #203)

enum ReminderSlot: String, Codable, CaseIterable, Identifiable, Hashable {
    case morning, afternoon, evening, beforeBed
    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .beforeBed: return "Before bed"
        }
    }

    var hour: Int {
        switch self {
        case .morning: return 9
        case .afternoon: return 12
        case .evening: return 18
        case .beforeBed: return 22
        }
    }

    var timeLabel: String {
        switch self {
        case .morning: return "9:00 AM"
        case .afternoon: return "12:00 PM"
        case .evening: return "6:00 PM"
        case .beforeBed: return "10:00 PM"
        }
    }

    var menuLabel: String { "\(title) (\(timeLabel))" }
}

struct Reminder: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var saveID: UUID
    var fireAt: Date
    var slot: ReminderSlot
}

struct AppNotification: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var saveID: UUID?
    var createdAt: Date = Date()
}

// MARK: - Gamification (Albo #78, #146 to #149, #183, #196)

struct ChecklistTask: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var subtitle: String
    var emoji: String
    var reward: Int
    var target: Int = 1
    var progress: Int = 0
    var isClaimed: Bool = false
    var isComplete: Bool { progress >= target }
}

struct Stamp: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var subtitle: String
    var goalLabel: String
    var target: Int
    var progress: Int
    var isUnlocked: Bool { progress >= target }
}

struct GamificationState: Codable, Hashable {
    var credits: Int = 0
    var streakWeeks: Int = 0
    var lastDoneAt: Date?
    var checklist: [ChecklistTask]
    var stamps: [Stamp]

    var claimedCount: Int { checklist.filter(\.isClaimed).count }
}

struct LeaderboardEntry: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var rank: Int
    var user: UserSummary
    var count: Int
}

// MARK: - Users

struct UserSummary: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var handle: String
    var mascot: MascotVariant = .plain
    var countryFlag: String? = nil
    var friendsOnYogi: Int = 0
}

struct UserProfile: Codable, Hashable {
    var name: String = ""
    var handle: String = ""
    var email: String = ""
    var bio: String = ""
    var instagram: String = ""
    var tiktok: String = ""
    var country: String = "Philippines"
    var homeCities: [String] = []
    var mascot: MascotVariant = .plain
    var isPrivate: Bool = false
    var followers: Int = 0
    var following: Int = 1
    var joinedAt: Date = Date()

    var summary: UserSummary { UserSummary(name: name.isEmpty ? "You" : name, handle: handle, mascot: mascot) }
}

enum Entitlement: String, Codable, Hashable {
    case free, pro, max

    var title: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .max: return "Max"
        }
    }
}

// MARK: - Onboarding answers (Albo #5, #14, #19, #21)

enum OnboardingGoal: String, CaseIterable, Identifiable, Codable, Hashable {
    case doThings, onePlace, map, recipes, stopLosing, findEasier
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .doThings: return "💥"
        case .onePlace: return "📓"
        case .map: return "🗺️"
        case .recipes: return "🍳"
        case .stopLosing: return "🪝"
        case .findEasier: return "🔍"
        }
    }

    var title: String {
        switch self {
        case .doThings: return "Actually do the things I save"
        case .onePlace: return "Keep all my saves in one place"
        case .map: return "See all my saves pinned on a map"
        case .recipes: return "See my saved recipes as ingredients and steps"
        case .stopLosing: return "Stop losing things I find online"
        case .findEasier: return "Be able to find my saves much easier"
        }
    }

    /// Reinforcement subline (Albo #6), answer-reactive.
    var reinforcement: String {
        switch self {
        case .doThings: return "Yogi turns every save into something you can actually tick off."
        case .onePlace: return "Yogi pulls saves from TikTok, Instagram, Safari and screenshots into one library."
        case .map: return "Every place you save gets pinned on a map, ready for your next trip."
        case .recipes: return "Yogi pulls ingredients and step-by-step instructions straight out of your TikTok recipes."
        case .stopLosing: return "Share once to Yogi and it's found, filed and searchable forever."
        case .findEasier: return "Search saves by what they are, not where you saw them."
        }
    }
}

enum DiscoverySource: String, CaseIterable, Identifiable, Codable, Hashable {
    case friend, tiktok, instagram, youtube, threads, x, search, linkedin, reddit, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .friend: return "Friend or Family"
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        case .threads: return "Threads"
        case .x: return "X"
        case .search: return "Search Engine"
        case .linkedin: return "LinkedIn"
        case .reddit: return "Reddit"
        case .other: return "Other"
        }
    }
    var emoji: String {
        switch self {
        case .friend: return "👥"
        case .tiktok: return "🎵"
        case .instagram: return "📸"
        case .youtube: return "▶️"
        case .threads: return "🧵"
        case .x: return "✖️"
        case .search: return "🔎"
        case .linkedin: return "💼"
        case .reddit: return "👽"
        case .other: return "✨"
        }
    }
}

enum SavingHabit: String, CaseIterable, Identifiable, Codable, Hashable {
    case socialMedia, websites, notesApp, screenshots
    var id: String { rawValue }
    var title: String {
        switch self {
        case .socialMedia: return "Social Media"
        case .websites: return "Websites"
        case .notesApp: return "My notes app"
        case .screenshots: return "Screenshots"
        }
    }
    var emoji: String {
        switch self {
        case .socialMedia: return "📱"
        case .websites: return "🌐"
        case .notesApp: return "✏️"
        case .screenshots: return "📷"
        }
    }
}

enum ContentInterest: String, CaseIterable, Identifiable, Codable, Hashable {
    case travel, restaurants, recipes, workouts, shopping, books, articles
    var id: String { rawValue }
    var title: String {
        switch self {
        case .travel: return "Travel"
        case .restaurants: return "Restaurants"
        case .recipes: return "Recipes"
        case .workouts: return "Workout routines"
        case .shopping: return "Shopping"
        case .books: return "Books"
        case .articles: return "Articles"
        }
    }
    var emoji: String {
        switch self {
        case .travel: return "✈️"
        case .restaurants: return "🍽️"
        case .recipes: return "🥘"
        case .workouts: return "💪"
        case .shopping: return "🛍️"
        case .books: return "📚"
        case .articles: return "📰"
        }
    }
    /// "Setting up your Yogi for" checklist line (Albo #37).
    var planLine: String {
        switch self {
        case .travel: return "Trips you want to plan"
        case .restaurants: return "Saved places & restaurants"
        case .recipes: return "Recipes to cook"
        case .workouts: return "Workouts to try"
        case .shopping: return "Things to buy"
        case .books: return "Books to read"
        case .articles: return "Articles to read"
        }
    }
}

struct OnboardingAnswers: Codable, Hashable {
    var goals: Set<OnboardingGoal> = []
    var discovery: DiscoverySource? = nil
    var habits: Set<SavingHabit> = []
    var interests: Set<ContentInterest> = []
}

// MARK: - Community

struct FeedPost: Identifiable, Hashable, Codable {
    enum Kind: String, Codable, Hashable { case review, list, place }
    var id: UUID = UUID()
    var author: UserSummary
    var kind: Kind
    var title: String
    var coverEmoji: String
    var coverTint: UInt32
    var stars: Int?
    var saveID: UUID?
    var reactions: [Reaction] = []
    var isNearby: Bool = false
    var aspect: Double = 1.0
}
