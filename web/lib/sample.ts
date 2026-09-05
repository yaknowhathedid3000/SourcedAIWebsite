// Demo content, the same items as the recording and the iOS sample data.
// Used whenever NEXT_PUBLIC_SUPABASE_URL is not configured, so the site runs out of the box.
import type { Collection, Profile, Review, Save } from "./types";

const ME = "00000000-0000-0000-0000-00000000aaaa";
const d = (y: number, m: number, day: number) => new Date(Date.UTC(y, m - 1, day, 10)).toISOString();

export const sampleProfile: Profile = {
  id: ME, handle: "juliascreens", name: "Julia", bio: "", avatar_mascot: "plain", instagram: "juliascreens", tiktok: "",
  country: "Philippines", is_private: false, entitlement: "free", credits: 20, streak_weeks: 1,
};

export const sampleSaves: Save[] = [
  {
    id: "00000000-0000-0000-0000-000000000001", owner_id: ME, category: "recipe", title: "Triple Chocolate Cookies", subtitle: null,
    cover_url: null, cover_emoji: "🍪", cover_tint: 0xF3E2C6, source_url: null, source_platform: "note", status: "done", private_note: "Lessen sugar", note_body: null,
    recipe: {
      timeLabel: "15 mins", cuisine: "American", course: "Dessert", yieldLabel: "Makes 12 cookies",
      ingredients: [
        { emoji: "🍫", name: "dark chocolate chips", quantity: 1, unit: "cup" }, { emoji: "🍫", name: "milk chocolate chips", quantity: 1, unit: "cup" },
        { emoji: "🍫", name: "white chocolate chips", quantity: 1, unit: "cup" }, { emoji: "🧈", name: "butter", quantity: 0.5, unit: "cup" },
        { emoji: "🥚", name: "egg", quantity: 1, unit: "large" }, { emoji: "🌾", name: "flour", quantity: 2, unit: "cups" }, { emoji: "🍬", name: "sugar", quantity: 1, unit: "cup" },
      ],
      steps: ["Cream together the butter and sugar until smooth.", "Beat in the egg.", "Gradually stir in the flour.", "Fold in the dark, milk, and white chocolate chips.", "Bake at 350°F for 10-12 minutes."],
      stepEmoji: ["🧈", "🥚", "🌾", "🍫", "⏲️"], emoji: "🍪",
    },
    place: null, event: null, media: null, created_at: d(2026, 6, 10),
  },
  {
    id: "00000000-0000-0000-0000-000000000002", owner_id: ME, category: "recipe", title: "Homemade Shoyu Ramen", subtitle: null,
    cover_url: null, cover_emoji: "🍜", cover_tint: 0xF7D9B0, source_url: "https://www.seriouseats.com/shoyu-ramen", source_platform: "safari", status: "saved", private_note: null, note_body: null,
    recipe: { timeLabel: "Multi-day project", cuisine: "Japanese", course: "Dinner", yieldLabel: "Serves 4", ingredients: [{ emoji: "🍜", name: "ramen noodles", quantity: 4, unit: "portions" }, { emoji: "🥚", name: "soft-boiled eggs", quantity: 4, unit: null }], steps: ["Simmer the stock for 6 hours.", "Marinate the eggs overnight.", "Cook noodles and assemble."], stepEmoji: ["🍲", "🥚", "🍜"], emoji: "🍜" },
    place: null, event: null, media: null, created_at: d(2026, 6, 10),
  },
  {
    id: "00000000-0000-0000-0000-000000000003", owner_id: ME, category: "recipe", title: "Carbonara", subtitle: "i tuoi piatti da fuorisede",
    cover_url: null, cover_emoji: "🍝", cover_tint: 0xDCE8C8, source_url: null, source_platform: "tiktok", status: "done", private_note: null, note_body: null,
    recipe: { timeLabel: "30 minutes", cuisine: "Italian", course: null, yieldLabel: "Serves 2", ingredients: [{ emoji: "🍝", name: "Spaghetti", quantity: 200, unit: "g" }, { emoji: "🥓", name: "Guanciale", quantity: 50, unit: "g" }, { emoji: "🥚", name: "Egg Yolks", quantity: 2, unit: null }, { emoji: "🧀", name: "Pecorino Romano", quantity: 50, unit: "g" }], steps: ["Render the guanciale until crisp.", "Whisk yolks with pecorino and pepper.", "Toss hot pasta off the heat with the yolk mixture."], stepEmoji: ["🥓", "🥚", "🍝"], emoji: "🍝" },
    place: null, event: null, media: null, created_at: d(2026, 6, 11),
  },
  {
    id: "00000000-0000-0000-0000-000000000004", owner_id: ME, category: "recipe", title: "Crispy Smashed Potato Salad", subtitle: null,
    cover_url: null, cover_emoji: "🥔", cover_tint: 0xF3E2C6, source_url: null, source_platform: "instagram", status: "wantTo", private_note: null, note_body: null,
    recipe: { timeLabel: "45 mins", cuisine: "American", course: "Side Dish", yieldLabel: "Serves 4-6", ingredients: [{ emoji: "🥔", name: "Potato gems/tater tots", quantity: 400, unit: "g" }, { emoji: "🥣", name: "Mayonnaise", quantity: 0.5, unit: "cup" }, { emoji: "🥛", name: "Greek yogurt", quantity: 0.25, unit: "cup" }, { emoji: "🍋", name: "Lemon juice", quantity: 1, unit: "lemon" }, { emoji: "🧄", name: "Garlic", quantity: 1, unit: "clove" }], steps: ["Bake the tots until very crisp.", "Whisk the dressing.", "Smash, toss and top with dill."], stepEmoji: ["🔥", "🥣", "🌿"], emoji: "🥗" },
    place: null, event: null, media: null, created_at: d(2026, 6, 11),
  },
  {
    id: "00000000-0000-0000-0000-000000000005", owner_id: ME, category: "place", title: "New York City Bar", subtitle: null,
    cover_url: null, cover_emoji: "🏛️", cover_tint: 0xCFD8DC, source_url: null, source_platform: "manual", status: "wantTo", private_note: null, note_body: null,
    recipe: null, place: { latitude: 40.7597, longitude: -73.9776, category: "Association / Organization", rating: 4.2, priceLevel: null, hoursLabel: "Opens Friday at 9 AM to 5 PM", phone: "+1 212-382-6600", website: "https://www.nycbar.org", address: "42 W 44th St, New York, NY 10036", neighborhood: "LENOX HILL", city: "New York", countryFlag: "🇺🇸", emoji: "🏛️", photoEmoji: ["🏛️", "🏢", "👔"], about: "The New York City Bar, located in Midtown Manhattan, is more than just a bar; it's a hub for legal professionals and those interested in law and culture." },
    event: null, media: null, created_at: d(2026, 6, 11),
  },
  {
    id: "00000000-0000-0000-0000-000000000006", owner_id: ME, category: "place", title: "London", subtitle: null,
    cover_url: null, cover_emoji: "🇬🇧", cover_tint: 0xD7E3F4, source_url: null, source_platform: "manual", status: "wantTo", private_note: null, note_body: null,
    recipe: null, place: { latitude: 51.5074, longitude: -0.1278, category: "City", rating: null, priceLevel: null, hoursLabel: null, phone: null, website: "https://visitlondon.com", address: "London, United Kingdom", neighborhood: null, city: "London", countryFlag: "🇬🇧", emoji: "🇬🇧", photoEmoji: ["🕰️", "🌉", "🎡"], about: null },
    event: null, media: null, created_at: d(2026, 6, 11),
  },
  {
    id: "00000000-0000-0000-0000-000000000007", owner_id: ME, category: "book", title: "Project Hail Mary", subtitle: "Andy Weir",
    cover_url: null, cover_emoji: "🚀", cover_tint: 0x1D3557, source_url: null, source_platform: "manual", status: "done", private_note: null, note_body: null,
    recipe: null, place: null, event: null, media: { year: 2021, genre: "Science fiction", pages: 496, rating: 4.5, author: "Andy Weir", runtimeLabel: null, tags: [] }, created_at: d(2026, 6, 11),
  },
  {
    id: "00000000-0000-0000-0000-000000000008", owner_id: ME, category: "event", title: "IVE - Show What I Am Fan Support by aijoowon", subtitle: null,
    cover_url: null, cover_emoji: "🎤", cover_tint: 0x2B2D42, source_url: null, source_platform: "instagram", status: "wantTo", private_note: null, note_body: null,
    recipe: null, place: null, event: { start: d(2026, 7, 13), end: null, venue: "PICKUP COFFEE - MAAX Building Park", address: "Complex, Coral Way, MAAX Parking Bldg, Mall of Asia, Pasay City, Philippines", organizer: "aijoowon", kind: "Community", about: "A fan-led giveaway event in Manila featuring IVE wallet-sized graduation photos, stickers, and prints.", latitude: 14.5353, longitude: 120.9822 },
    media: null, created_at: d(2026, 6, 12),
  },
  {
    id: "00000000-0000-0000-0000-000000000011", owner_id: ME, category: "article", title: "10 of the Best Things to do in St Albans", subtitle: "emilyluxton.co.uk",
    cover_url: null, cover_emoji: "🌳", cover_tint: 0xCDE7C4, source_url: "https://www.emilyluxton.co.uk/st-albans", source_platform: "safari", status: "saved", private_note: null, note_body: null,
    recipe: null, place: null, event: null, media: null, created_at: d(2026, 6, 10),
  },
  {
    id: "00000000-0000-0000-0000-000000000014", owner_id: ME, category: "place", title: "KOH Cafe + Roasters", subtitle: null,
    cover_url: null, cover_emoji: "☕️", cover_tint: 0xE6D5C3, source_url: null, source_platform: "instagram", status: "wantTo", private_note: null, note_body: null,
    recipe: null, place: { latitude: 14.5547, longitude: 121.0244, category: "Coffee shop", rating: 4.6, priceLevel: "$$", hoursLabel: "Open until 10 PM", phone: null, website: null, address: "Makati, Metro Manila", neighborhood: "POBLACION", city: "Makati", countryFlag: "🇵🇭", emoji: "☕️", photoEmoji: ["☕️", "🍰", "🪴"], about: "Specialty roaster with a matcha bar." },
    event: null, media: null, created_at: d(2026, 6, 8),
  },
];

export const sampleCollections: Collection[] = [
  { id: "00000000-0000-0000-0000-000000000101", owner_id: ME, name: "Recipes", details: null, cover_emoji: "🥦", cover_tint: 0xF3B27A, is_public: true, invite_token: "demo-recipes", created_at: d(2026, 6, 10) },
  { id: "00000000-0000-0000-0000-000000000102", owner_id: ME, name: "Manila weekend", details: "Everything the group chat said we'd actually do.", cover_emoji: "🌴", cover_tint: 0xDDEBF7, is_public: true, invite_token: "demo-manila", created_at: d(2026, 6, 12) },
];

export const sampleCollectionSaves: Record<string, string[]> = {
  "00000000-0000-0000-0000-000000000101": ["00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000003", "00000000-0000-0000-0000-000000000004"],
  "00000000-0000-0000-0000-000000000102": ["00000000-0000-0000-0000-000000000014", "00000000-0000-0000-0000-000000000008"],
};

export const sampleReviews: Review[] = [
  { id: "r1", owner_id: ME, save_id: "00000000-0000-0000-0000-000000000001", sentiment: "hiddenGem", title: "i love the texture!", stars: 5, completed_on: "2026-06-10", friends_only: false, created_at: d(2026, 6, 10) },
  { id: "r2", owner_id: ME, save_id: "00000000-0000-0000-0000-000000000003", sentiment: "lovedIt", title: null, stars: 5, completed_on: "2026-06-11", friends_only: false, created_at: d(2026, 6, 11) },
  { id: "r3", owner_id: ME, save_id: "00000000-0000-0000-0000-000000000007", sentiment: "lovedIt", title: null, stars: 5, completed_on: "2026-06-11", friends_only: false, created_at: d(2026, 6, 11) },
];
