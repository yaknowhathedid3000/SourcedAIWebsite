import Foundation

/// Sample content lifted from the recording so the app opens in a realistic state.
/// Names and places match the screens; user handles are the ones visible on them.
enum SampleData {
    // MARK: Users (Albo #158, #180, #196)
    static let me = UserSummary(name: "Julia", handle: "juliascreens", mascot: .plain, countryFlag: "🇵🇭")
    static let kimmy = UserSummary(name: "Kimmy", handle: "kpdubz", mascot: .chef, countryFlag: "🇺🇸", friendsOnYogi: 1)
    static let isaac = UserSummary(name: "Isaac", handle: "isaac", mascot: .rocket, countryFlag: "🇬🇧", friendsOnYogi: 37)
    static let karolina = UserSummary(name: "Karolina @ Yogi", handle: "karosaves", mascot: .reader, countryFlag: "🇬🇧", friendsOnYogi: 14)
    static let jake = UserSummary(name: "Jakee", handle: "jake", mascot: .traveler, countryFlag: "🇬🇧", friendsOnYogi: 11)
    static let antonia = UserSummary(name: "Antonia", handle: "antonia", mascot: .filmFan)
    static let chloe = UserSummary(name: "Chloé Montil", handle: "chloemontil", mascot: .news)
    static let ren = UserSummary(name: "Ren", handle: "ren", mascot: .explorer)
    static let allie = UserSummary(name: "allie", handle: "allie", mascot: .chef)
    static let gabrielle = UserSummary(name: "Gabrielle", handle: "gabrielle", mascot: .traveler)
    static let team: [UserSummary] = [isaac, karolina, jake]

    // MARK: Stable IDs so collections, reviews and posts can reference saves.
    static let cookiesID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let ramenID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let carbonaraID = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let potatoSaladID = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let nycBarID = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    static let londonID = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    static let hailMaryID = UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
    static let iveEventID = UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    static let pullUpID = UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
    static let lateralRaiseID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    static let stAlbansID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    static let cookieNoteID = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!
    static let onceUponID = UUID(uuidString: "00000000-0000-0000-0000-000000000013")!
    static let kohCafeID = UUID(uuidString: "00000000-0000-0000-0000-000000000014")!
    static let deliID = UUID(uuidString: "00000000-0000-0000-0000-000000000015")!
    static let recipesCollectionID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    static let homeWorkoutListID = UUID(uuidString: "00000000-0000-0000-0000-000000000201")!

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 10) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h
        return Calendar.current.date(from: c) ?? Date()
    }

    // MARK: Saves (Albo #69, #85, #113, #121, #137, #140, #157, #167, #110, #111, #56, #68)
    static let saves: [Save] = {
        let s1 = Save(id: cookiesID, category: .recipe, title: "Triple Chocolate Cookies", coverEmoji: nil,
             sourcePlatform: .note, status: .saved, saveCount: 1, createdAt: date(2026, 6, 10, 9),
             privateNote: "Lessen sugar",
             recipe: RecipeDetails(timeLabel: "15 mins", cuisine: "American", course: "Dessert", yieldLabel: "Makes 12 cookies",
                                   ingredients: [
                                    Ingredient(emoji: "🍫", name: "dark chocolate chips", quantity: 1, unit: "cup"),
                                    Ingredient(emoji: "🍫", name: "milk chocolate chips", quantity: 1, unit: "cup"),
                                    Ingredient(emoji: "🍫", name: "white chocolate chips", quantity: 1, unit: "cup"),
                                    Ingredient(emoji: "🧈", name: "butter", quantity: 0.5, unit: "cup"),
                                    Ingredient(emoji: "🥚", name: "egg", quantity: 1, unit: "large"),
                                    Ingredient(emoji: "🌾", name: "flour", quantity: 2, unit: "cups"),
                                    Ingredient(emoji: "🍬", name: "sugar", quantity: 1, unit: "cup"),
                                   ],
                                   steps: ["Cream together the butter and sugar until smooth.",
                                           "Beat in the egg.",
                                           "Gradually stir in the flour.",
                                           "Fold in the dark, milk, and white chocolate chips.",
                                           "Bake at 350°F for 10-12 minutes."],
                                   stepEmoji: ["🧈", "🥚", "🌾", "🍫", "⏲️"], emoji: "🍪"),
             savedBy: [me], mentionedInNoteID: cookieNoteID)
        let s2 = Save(id: ramenID, category: .recipe, title: "Homemade Shoyu Ramen", coverEmoji: "🍜", coverTint: 0xF7D9B0,
             sourceURL: URL(string: "https://www.seriouseats.com/shoyu-ramen"), sourcePlatform: .safari, status: .saved,
             saveCount: 1, createdAt: date(2026, 6, 10, 12),
             recipe: RecipeDetails(timeLabel: "Multi-day project", cuisine: "Japanese", course: "Dinner", yieldLabel: "Serves 4",
                                   ingredients: [
                                    Ingredient(emoji: "🍜", name: "ramen noodles", quantity: 4, unit: "portions"),
                                    Ingredient(emoji: "🍗", name: "chicken carcasses", quantity: 2, unit: nil),
                                    Ingredient(emoji: "🫘", name: "shoyu tare", quantity: 0.5, unit: "cup"),
                                    Ingredient(emoji: "🥚", name: "soft-boiled eggs", quantity: 4, unit: nil),
                                    Ingredient(emoji: "🧅", name: "scallions", quantity: 3, unit: nil),
                                   ],
                                   steps: ["Simmer the stock for 6 hours.", "Marinate the eggs overnight.", "Cook noodles and assemble."],
                                   stepEmoji: ["🍲", "🥚", "🍜"], emoji: "🍜"),
             savedBy: [me])
        let s3 = Save(id: carbonaraID, category: .recipe, title: "Carbonara", subtitle: "i tuoi piatti da fuorisede", coverEmoji: "🍝", coverTint: 0xDCE8C8,
             sourcePlatform: .tiktok, status: .done, saveCount: 1, createdAt: date(2026, 6, 11, 8),
             recipe: RecipeDetails(timeLabel: "30 minutes", cuisine: "Italian", course: nil, yieldLabel: "Serves 2",
                                   ingredients: [
                                    Ingredient(emoji: "🍝", name: "Spaghetti", quantity: 200, unit: "g"),
                                    Ingredient(emoji: "🥓", name: "Guanciale", quantity: 50, unit: "g"),
                                    Ingredient(emoji: "🥚", name: "Egg Yolks", quantity: 2, unit: nil),
                                    Ingredient(emoji: "🧀", name: "Pecorino Romano", quantity: 50, unit: "g"),
                                   ],
                                   steps: ["Render the guanciale until crisp.", "Whisk yolks with pecorino and pepper.", "Toss hot pasta off the heat with the yolk mixture and pasta water."],
                                   stepEmoji: ["🥓", "🥚", "🍝"], emoji: "🍝"),
             savedBy: [me])
        let s4 = Save(id: potatoSaladID, category: .recipe, title: "Crispy Smashed Potato Salad", coverEmoji: "🥔", coverTint: 0xF3E2C6,
             sourcePlatform: .instagram, status: .wantTo, saveCount: 1165, createdAt: date(2026, 6, 11, 14),
             recipe: RecipeDetails(timeLabel: "45 mins", cuisine: "American", course: "Side Dish", yieldLabel: "Serves 4-6",
                                   ingredients: [
                                    Ingredient(emoji: "🥔", name: "Potato gems/tater tots", quantity: 400, unit: "g"),
                                    Ingredient(emoji: "🥣", name: "Mayonnaise", quantity: 0.5, unit: "cup"),
                                    Ingredient(emoji: "🥛", name: "Greek yogurt", quantity: 0.25, unit: "cup"),
                                    Ingredient(emoji: "🍋", name: "Lemon juice", quantity: 1, unit: "lemon"),
                                    Ingredient(emoji: "🍯", name: "Dijon mustard", quantity: 1, unit: "tsp"),
                                    Ingredient(emoji: "🌾", name: "Wholegrain mustard", quantity: 1, unit: "tsp"),
                                    Ingredient(emoji: "🧄", name: "Garlic", quantity: 1, unit: "clove"),
                                    Ingredient(emoji: "🌿", name: "Fresh dill", quantity: 0.25, unit: "cup"),
                                   ],
                                   steps: ["Bake the tots until very crisp.", "Whisk the dressing.", "Smash, toss and top with dill."],
                                   stepEmoji: ["🔥", "🥣", "🌿"], emoji: "🥗"),
             savedBy: [kimmy, me], reactions: [Reaction(emoji: "❤️", count: 1), Reaction(emoji: "💎", count: 1), Reaction(emoji: "👌", count: 1)])
        let s5 = Save(id: nycBarID, category: .place, title: "New York City Bar", coverEmoji: "🏛️", coverTint: 0xCFD8DC,
             sourcePlatform: .manual, status: .wantTo, saveCount: 4, createdAt: date(2026, 6, 11, 15),
             place: PlaceDetails(latitude: 40.7597, longitude: -73.9776, category: "Association / Organization", rating: 4.2, priceLevel: nil,
                                 hoursLabel: "Opens Friday at 9 AM to 5 PM", phone: "+1 212-382-6600", website: URL(string: "https://www.nycbar.org"),
                                 address: "42 W 44th St, New York, NY 10036", neighborhood: "LENOX HILL", city: "New York", countryFlag: "🇺🇸",
                                 emoji: "🏛️", photoEmoji: ["🏛️", "🏢", "👔"],
                                 about: "The New York City Bar, located in Midtown Manhattan, is more than just a bar; it's a hub for legal professionals and those interested in law and culture."),
             savedBy: [isaac, jake])
        let s6 = Save(id: londonID, category: .place, title: "London", coverEmoji: "🇬🇧", coverTint: 0xD7E3F4,
             sourcePlatform: .manual, status: .wantTo, saveCount: 1167, createdAt: date(2026, 6, 11, 16),
             place: PlaceDetails(latitude: 51.5074, longitude: -0.1278, category: "City", rating: nil, priceLevel: nil,
                                 hoursLabel: nil, phone: nil, website: URL(string: "https://visitlondon.com"),
                                 address: "London, United Kingdom", neighborhood: nil, city: "London", countryFlag: "🇬🇧",
                                 emoji: "🇬🇧", photoEmoji: ["🕰️", "🌉", "🎡"], about: nil),
             savedBy: [isaac, karolina, jake], reactions: [Reaction(emoji: "❤️", count: 3)])
        let s7 = Save(id: hailMaryID, category: .book, title: "Project Hail Mary", subtitle: "Andy Weir", coverEmoji: "🚀", coverTint: 0x1D3557,
             sourcePlatform: .manual, status: .done, saveCount: 763, createdAt: date(2026, 6, 11, 17),
             media: MediaDetails(year: 2021, genre: "Science fiction", pages: 496, rating: 4.5, author: "Andy Weir"),
             savedBy: [karolina, me])
        let s8 = Save(id: onceUponID, category: .film, title: "Once Upon a Time in Hollywood", coverEmoji: "🎬", coverTint: 0xF4D35E,
             sourcePlatform: .instagram, status: .wantTo, saveCount: 812, createdAt: date(2026, 6, 9, 20),
             media: MediaDetails(year: 2019, genre: "Comedy", runtimeLabel: "2h 41m"),
             savedBy: [antonia])
        let s9 = Save(id: iveEventID, category: .event, title: "IVE - Show What I Am Fan Support by aijoowon", coverEmoji: "🎤", coverTint: 0x2B2D42,
             sourcePlatform: .instagram, status: .wantTo, saveCount: 1, createdAt: date(2026, 6, 12, 9),
             event: EventDetails(start: date(2026, 7, 13, 10), end: date(2026, 7, 13, 11), venue: "PICKUP COFFEE - MAAX Building Park",
                                 address: "Complex, Coral Way, MAAX Parking Bldg, Mall of Asia, Pasay City, Philippines", organizer: "aijoowon", kind: "Community",
                                 about: "A fan-led giveaway event in Manila featuring IVE wallet-sized graduation photos, stickers, and prints.",
                                 latitude: 14.5353, longitude: 120.9822),
             savedBy: [me])
        let s10 = Save(id: pullUpID, category: .workout, title: "Pull-Up", coverEmoji: "🏋️", coverTint: 0xE0F2F1,
             sourcePlatform: .manual, status: .saved, saveCount: 4, createdAt: date(2026, 6, 12, 10),
             media: MediaDetails(tags: ["Bodyweight", "Strength", "Upper Body", "Back"]), savedBy: [isaac, jake])
        let s11 = Save(id: lateralRaiseID, category: .workout, title: "Lateral Raise", coverEmoji: "💪", coverTint: 0xE8EAF6,
             sourcePlatform: .manual, status: .saved, saveCount: 1, createdAt: date(2026, 6, 12, 10),
             media: MediaDetails(tags: ["Strength", "Upper Body", "Shoulders"]), savedBy: [me])
        let s12 = Save(id: stAlbansID, category: .article, title: "10 of the Best Things to do in St Albans", subtitle: "emilyluxton.co.uk", coverEmoji: "🌳", coverTint: 0xCDE7C4,
             sourceURL: URL(string: "https://www.emilyluxton.co.uk/st-albans"), sourcePlatform: .safari, status: .saved, saveCount: 1,
             createdAt: date(2026, 6, 10, 8), savedBy: [me])
        let s13 = Save(id: cookieNoteID, category: .note, title: "Cookie recipes", coverEmoji: nil, coverTint: 0xF4F4F4,
             sourcePlatform: .note, status: .saved, saveCount: 1, createdAt: date(2026, 6, 10, 9),
             noteBody: "- ## **Triple Chocolate Cookies** *italic*", savedBy: [me])
        let s14 = Save(id: kohCafeID, category: .place, title: "KOH Cafe + Roasters", coverEmoji: "☕️", coverTint: 0xE6D5C3,
             sourcePlatform: .instagram, status: .wantTo, saveCount: 22, createdAt: date(2026, 6, 8),
             place: PlaceDetails(latitude: 14.5547, longitude: 121.0244, category: "Coffee shop", rating: 4.6, priceLevel: "$$", hoursLabel: "Open until 10 PM",
                                 phone: nil, website: nil, address: "Makati, Metro Manila", neighborhood: "POBLACION", city: "Makati", countryFlag: "🇵🇭",
                                 emoji: "☕️", photoEmoji: ["☕️", "🍰", "🪴"], about: "Specialty roaster with a matcha bar."),
             savedBy: [ren, allie])
        let s15 = Save(id: deliID, category: .place, title: "717 DELI", coverEmoji: "🥪", coverTint: 0xF9E4B7,
             sourcePlatform: .tiktok, status: .wantTo, saveCount: 9, createdAt: date(2026, 6, 7),
             place: PlaceDetails(latitude: 14.5648, longitude: 121.0290, category: "Deli", rating: 4.4, priceLevel: "$", hoursLabel: "Open until 9 PM",
                                 phone: nil, website: nil, address: "Makati, Metro Manila", neighborhood: "SALCEDO", city: "Makati", countryFlag: "🇵🇭",
                                 emoji: "🥪", photoEmoji: ["🥪", "🥤"], about: nil),
             savedBy: [gabrielle])
        return [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15]
    }()

    // MARK: Collections and lists (Albo #99, #112, #171)
    static let collections: [SaveCollection] = {
        [SaveCollection(id: recipesCollectionID, name: "Recipes", details: nil, coverEmoji: "🥦", coverTint: 0xF3B27A, isPublic: true, owner: me, saveIDs: [cookiesID, carbonaraID])]
    }()

    static let lists: [CuratedList] = {
        [CuratedList(id: homeWorkoutListID, category: .workout, title: "Home workout", isRanked: true, saveIDs: [lateralRaiseID, pullUpID], owner: me, coverEmoji: "🏠")]
    }()

    // MARK: Reviews (Albo #85, #186, #188, #189)
    static let reviews: [Review] = {
        [
            Review(saveID: cookiesID, sentiment: .hiddenGem, title: "i love the texture!", stars: 5, completedOn: date(2026, 6, 10), photoCount: 1, createdAt: date(2026, 6, 10, 18)),
            Review(saveID: carbonaraID, sentiment: .lovedIt, title: nil, stars: 5, completedOn: date(2026, 6, 11), createdAt: date(2026, 6, 11, 20)),
            Review(saveID: hailMaryID, sentiment: .lovedIt, title: nil, stars: 5, completedOn: date(2026, 6, 11), createdAt: date(2026, 6, 11, 21)),
        ]
    }()

    // MARK: Gamification (Albo #146 to #149, #184)
    static let checklist: [ChecklistTask] = {
        [
            ChecklistTask(id: "list", title: "Try making a list", subtitle: "Rank your favourites.", emoji: "📼", reward: 2, progress: 1, isClaimed: false),
            ChecklistTask(id: "screenshot", title: "Import a screenshot", subtitle: "Share things you see in videos, or irl.", emoji: "📷", reward: 2, progress: 1, isClaimed: false),
            ChecklistTask(id: "import5", title: "Import 5 things", subtitle: "Kickstart your collection.", emoji: "📦", reward: 10, target: 5, progress: 0),
            ChecklistTask(id: "pin", title: "Pin the Yogi shortcut", subtitle: "Import things to Yogi even faster.", emoji: "📌", reward: 2),
            ChecklistTask(id: "invite", title: "Invite friends", subtitle: "Earn 100 credits for every friend who joins.", emoji: "🖼️", reward: 500),
            ChecklistTask(id: "bulk", title: "Try bulk importing", subtitle: "Add a whole collection of saves at once.", emoji: "📦", reward: 2),
            ChecklistTask(id: "review", title: "Try reviewing something", subtitle: "Rate and review one of your saves.", emoji: "⭐️", reward: 2, progress: 1, isClaimed: true),
        ]
    }()

    static let stamps: [Stamp] = {
        [Stamp(id: "hoarder", title: "Digital Hoarder", subtitle: "Build up your stash in Yogi!", goalLabel: "Import 10 things", target: 10, progress: 2)]
    }()

    // MARK: Leaderboards (Albo #196, #197)
    static let hoarders: [LeaderboardEntry] = {
        let rows: [(String, String, MascotVariant, Int)] = [
            ("Claire", "cmzerbib", .reader, 22437), ("LL", "LLLOOPS", .reader, 19809), ("Jennifer Huynh", "Phobunny", .reader, 19218),
            ("Nora Mina-Lorenzetti", "noraminalo", .traveler, 16601), ("Sammy", "Samwalkedintoabarr__", .chef, 16531), ("Veed", "veed", .reader, 16119),
            ("J", "JM8", .traveler, 15201), ("Maite Urdangarin", "BlahBlahmachine", .explorer, 13973), ("meep", "meep04", .reader, 13913),
            ("Margaret Gardner", "margaret", .filmFan, 13669), ("Omar", "omard", .explorer, 13198),
        ]
        return rows.enumerated().map { i, r in LeaderboardEntry(rank: i + 1, user: UserSummary(name: r.0, handle: r.1, mascot: r.2), count: r.3) }
    }()

    static let yappers: [LeaderboardEntry] = {
        let rows: [(String, String, MascotVariant, Int)] = [
            ("Malak", "malak", .news, 186), ("Christy", "christy", .chef, 116), ("zehra", "zehra", .reader, 104), ("Joana", "joana", .traveler, 99),
            ("Akihala", "akihala", .filmFan, 99), ("Madeline", "madeline", .reader, 94), ("Thư Nguyễn", "thu", .chef, 90), ("Senanga", "senanga", .explorer, 82),
            ("Hajar Yassein", "hajar", .news, 81), ("pattgue", "pattgue", .reader, 75), ("Isaac", "isaac", .rocket, 73),
        ]
        return rows.enumerated().map { i, r in LeaderboardEntry(rank: i + 1, user: UserSummary(name: r.0, handle: r.1, mascot: r.2), count: r.3) }
    }()

    // MARK: Community feed (Albo #145, #163, #166)
    static let feed: [FeedPost] = {
        [
            FeedPost(author: kimmy, kind: .list, title: "Recipes", coverEmoji: "🍲", coverTint: 0xF3E2C6, stars: nil, saveID: potatoSaladID, aspect: 1.05),
            FeedPost(author: me, kind: .review, title: "i love the texture!", coverEmoji: "🥦", coverTint: 0xF3B27A, stars: 5, saveID: cookiesID, aspect: 0.9),
            FeedPost(author: antonia, kind: .review, title: "very aesthetic and good music; perfect for a date", coverEmoji: "🍷", coverTint: 0x3A3A2E, stars: 4, aspect: 1.1),
            FeedPost(author: chloe, kind: .review, title: "OMG IT WAS DELICIOUS", coverEmoji: "🍛", coverTint: 0xD9B99B, stars: 5, aspect: 0.95),
            FeedPost(author: ren, kind: .place, title: "KOH Cafe + Roasters", coverEmoji: "☕️", coverTint: 0xE6D5C3, stars: 5, saveID: kohCafeID, reactions: [Reaction(emoji: "🔥", count: 2)], isNearby: true, aspect: 1.0),
            FeedPost(author: allie, kind: .review, title: "i just was not a fan of using vanilla for the syrup", coverEmoji: "🍵", coverTint: 0xD5E8D4, stars: 2, isNearby: true, aspect: 1.2),
            FeedPost(author: gabrielle, kind: .place, title: "717 DELI", coverEmoji: "🥪", coverTint: 0xF9E4B7, stars: 4, saveID: deliID, isNearby: true, aspect: 0.85),
        ]
    }()

    static let events: [Save] = { saves.filter { $0.category == .event } + [
        Save(category: .event, title: "IVE - Show What I Am Fan Support (B)", coverEmoji: "🎤", coverTint: 0x2B2D42, sourcePlatform: .instagram, status: .saved, saveCount: 3,
             event: EventDetails(start: date(2026, 7, 13, 22), venue: "Chagee NU Mall of Asia", kind: "Community", latitude: 14.5353, longitude: 120.9822)),
        Save(category: .event, title: "Wave to Earth - The () pieces tour", coverEmoji: "🌊", coverTint: 0x8ECAE6, sourcePlatform: .instagram, status: .saved, saveCount: 41,
             event: EventDetails(start: date(2026, 11, 15, 19), venue: "SM Mall of Asia Arena", kind: "Concert", latitude: 14.5324, longitude: 120.9830)),
        Save(category: .event, title: "BTS - World Tour 'Arirang' (Bulacan)", coverEmoji: "💜", coverTint: 0x5E548E, sourcePlatform: .tiktok, status: .saved, saveCount: 990,
             event: EventDetails(start: date(2027, 3, 13, 18), venue: "Philippine Sports Stadium", kind: "Concert", latitude: 14.8386, longitude: 120.8210)),
    ] }()

    // MARK: Search catalog for "manual search" (Albo #105, #110, #120)
    static let catalog: [Save] = {
        saves + [
            Save(category: .book, title: "Project Hail Mary / Artemis / The Martian", subtitle: "Andy Weir", coverEmoji: "📚", coverTint: 0x457B9D, saveCount: 12, media: MediaDetails(year: 2022, author: "Andy Weir")),
            Save(category: .book, title: "Project Hail Mary: A Novel", coverEmoji: "📕", coverTint: 0xE63946, saveCount: 3, media: MediaDetails(year: 2021)),
            Save(category: .recipe, title: "Carbonara", coverEmoji: "🍝", coverTint: 0xFFE8D6, saveCount: 1, recipe: RecipeDetails(timeLabel: "10 minutes", cuisine: "Italian-American", course: nil, yieldLabel: nil, ingredients: [], steps: [])),
            Save(category: .recipe, title: "Carbonara", coverEmoji: "🍝", coverTint: 0xF1FAEE, saveCount: 1, recipe: RecipeDetails(timeLabel: "30 minutes", cuisine: "Roman", course: nil, yieldLabel: nil, ingredients: [], steps: [])),
            Save(category: .workout, title: "Pull-Up Timing", coverEmoji: "⏱️", coverTint: 0xE0F2F1, saveCount: 2, media: MediaDetails(tags: ["Strength", "Back"])),
            Save(category: .film, title: "Once Upon a Time in the West", coverEmoji: "🤠", coverTint: 0xD4A373, saveCount: 44, media: MediaDetails(year: 1968, genre: "Western")),
            Save(category: .place, title: "New York City Hall", coverEmoji: "🏛️", coverTint: 0xE9ECEF, saveCount: 22, place: PlaceDetails(latitude: 40.7128, longitude: -74.0060, category: "City Hall", rating: 4.3, city: "New York", countryFlag: "🇺🇸")),
            Save(category: .place, title: "New York City Ballet", coverEmoji: "🩰", coverTint: 0xFFE5EC, saveCount: 3, place: PlaceDetails(latitude: 40.7725, longitude: -73.9835, category: "Ballet theater", rating: 4.8, city: "New York", countryFlag: "🇺🇸")),
        ]
    }()

    // MARK: Testimonials (Albo #4, #32)
    struct Testimonial: Identifiable { let id = UUID(); let handle: String; let flag: String; let text: String; let mascot: MascotVariant }
    static let testimonials: [Testimonial] = [
        Testimonial(handle: "falseid0ls", flag: "🇵🇭", text: "Don't know how I could live without this app now!!!", mascot: .traveler),
        Testimonial(handle: "artwal95", flag: "🇵🇭", text: "It's like a local guide but based on what I watch and save.", mascot: .explorer),
        Testimonial(handle: "Valentina_HC", flag: "🇵🇭", text: "Finally my TikTok recipes have ingredients I can shop from.", mascot: .chef),
        Testimonial(handle: "Mialdonetti", flag: "🇺🇸", text: "As a college student, the LAST thing I wanna do is go on to Instagram to find one of the hundreds of things I saved.", mascot: .reader),
        Testimonial(handle: "Am", flag: "🇬🇧", text: "I LOVE IT!", mascot: .filmFan),
    ]
}
