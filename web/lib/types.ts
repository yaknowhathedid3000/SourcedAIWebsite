// Mirrors ios/Albo/Albo/Models/Models.swift and the Postgres schema.

export type SaveCategory =
  | "recipe" | "place" | "film" | "book" | "product" | "workout" | "software"
  | "tvShow" | "event" | "article" | "tutorial" | "game" | "note" | "image";

export type SaveStatus = "saved" | "wantTo" | "done";

export interface Ingredient { emoji: string; name: string; quantity: number | null; unit: string | null; checked?: boolean }

export interface RecipeDetails {
  timeLabel: string; cuisine: string | null; course: string | null; yieldLabel: string | null;
  ingredients: Ingredient[]; steps: string[]; stepEmoji?: string[]; emoji?: string;
}

export interface PlaceDetails {
  latitude: number; longitude: number; category: string; rating: number | null; priceLevel: string | null;
  hoursLabel: string | null; phone: string | null; website: string | null; address: string | null;
  neighborhood: string | null; city: string | null; countryFlag: string | null; emoji?: string; photoEmoji?: string[]; about: string | null;
}

export interface EventDetails {
  start: string; end: string | null; venue: string; address: string | null; organizer: string | null;
  kind: string; about: string | null; latitude: number | null; longitude: number | null;
}

export interface MediaDetails {
  year: number | null; genre: string | null; pages: number | null; rating: number | null;
  author: string | null; runtimeLabel: string | null; tags: string[];
}

export interface Save {
  id: string;
  owner_id: string;
  category: SaveCategory;
  title: string;
  subtitle: string | null;
  cover_url: string | null;
  cover_emoji: string | null;
  cover_tint: number;
  source_url: string | null;
  source_platform: string;
  status: SaveStatus;
  private_note: string | null;
  note_body: string | null;
  recipe: RecipeDetails | null;
  place: PlaceDetails | null;
  event: EventDetails | null;
  media: MediaDetails | null;
  created_at: string;
}

export interface Collection {
  id: string;
  owner_id: string;
  name: string;
  details: string | null;
  cover_emoji: string;
  cover_tint: number;
  is_public: boolean;
  invite_token: string | null;
  created_at: string;
}

export interface Profile {
  id: string;
  handle: string;
  name: string;
  bio: string;
  avatar_mascot: string;
  instagram: string;
  tiktok: string;
  country: string | null;
  is_private: boolean;
  entitlement: "free" | "pro" | "max";
  credits: number;
  streak_weeks: number;
}

export interface Review {
  id: string;
  owner_id: string;
  save_id: string;
  sentiment: "lovedIt" | "hiddenGem" | "itsOkay" | "meh" | "overhyped" | "notForMe" | "avoid";
  title: string | null;
  stars: number | null;
  completed_on: string | null;
  friends_only: boolean;
  created_at: string;
}

export const CATEGORY: Record<SaveCategory, { title: string; plural: string; emoji: string; doneQuestion: string; wantTab: string; doneTab: string; journalVerb: string }> = {
  recipe:   { title: "Recipe",   plural: "Recipes",   emoji: "🍲", doneQuestion: "Made it?",   wantTab: "Want to try",   doneTab: "Made",    journalVerb: "Cooked" },
  place:    { title: "Place",    plural: "Places",    emoji: "🗺️", doneQuestion: "Visited?",   wantTab: "Want to go",    doneTab: "Visited", journalVerb: "Visited" },
  film:     { title: "Film",     plural: "Films",     emoji: "📼", doneQuestion: "Watched?",   wantTab: "Want to watch", doneTab: "Watched", journalVerb: "Watched" },
  book:     { title: "Book",     plural: "Books",     emoji: "📚", doneQuestion: "Read?",      wantTab: "Want to read",  doneTab: "Read",    journalVerb: "Read" },
  product:  { title: "Product",  plural: "Products",  emoji: "🧺", doneQuestion: "Bought it?", wantTab: "Want to try",   doneTab: "Done",    journalVerb: "Bought" },
  workout:  { title: "Workout",  plural: "Workouts",  emoji: "🏋️", doneQuestion: "Done it?",   wantTab: "Want to try",   doneTab: "Done",    journalVerb: "Did" },
  software: { title: "Software", plural: "Software",  emoji: "🖥️", doneQuestion: "Tried it?",  wantTab: "Want to try",   doneTab: "Done",    journalVerb: "Tried" },
  tvShow:   { title: "TV Show",  plural: "TV Shows",  emoji: "📺", doneQuestion: "Watched?",   wantTab: "Want to watch", doneTab: "Watched", journalVerb: "Watched" },
  event:    { title: "Event",    plural: "Events",    emoji: "🎟️", doneQuestion: "Visited?",   wantTab: "Want to go",    doneTab: "Visited", journalVerb: "Visited" },
  article:  { title: "Article",  plural: "Articles",  emoji: "📰", doneQuestion: "Read?",      wantTab: "Want to read",  doneTab: "Read",    journalVerb: "Read" },
  tutorial: { title: "Tutorial", plural: "Tutorials", emoji: "📐", doneQuestion: "Read?",      wantTab: "Want to try",   doneTab: "Read",    journalVerb: "Read" },
  game:     { title: "Game",     plural: "Games",     emoji: "🎮", doneQuestion: "Tried it?",  wantTab: "Want to try",   doneTab: "Done",    journalVerb: "Tried" },
  note:     { title: "Note",     plural: "Notes",     emoji: "📝", doneQuestion: "Done?",      wantTab: "Want to try",   doneTab: "Done",    journalVerb: "Finished" },
  image:    { title: "Image",    plural: "Images",    emoji: "🖼️", doneQuestion: "Done?",      wantTab: "Want to try",   doneTab: "Done",    journalVerb: "Finished" },
};

export const BROWSABLE: SaveCategory[] = ["recipe", "place", "film", "book", "product", "workout", "software", "tvShow", "event", "article", "tutorial", "game"];

export const SENTIMENT: Record<Review["sentiment"], { title: string; emoji: string; suffix: string }> = {
  lovedIt:  { title: "Loved it",   emoji: "❤️", suffix: "loved it" },
  hiddenGem:{ title: "Hidden gem", emoji: "💎", suffix: "a hidden gem" },
  itsOkay:  { title: "It's okay",  emoji: "🙂", suffix: "it's okay" },
  meh:      { title: "Meh",        emoji: "😐", suffix: "meh" },
  overhyped:{ title: "Overhyped",  emoji: "🤯", suffix: "overhyped" },
  notForMe: { title: "Not for me", emoji: "🤷", suffix: "not for me" },
  avoid:    { title: "Avoid",      emoji: "🚫", suffix: "avoid" },
};

export function metaLine(s: Save): string {
  if (s.recipe) return [s.recipe.timeLabel, s.recipe.cuisine, s.recipe.course].filter(Boolean).join(" · ");
  if (s.place) return [s.place.category, s.place.rating?.toFixed(1)].filter(Boolean).join(" · ");
  if (s.event) return [new Date(s.event.start).toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" }), s.event.kind, s.event.venue].join(" · ");
  if (s.media) {
    const parts: string[] = [];
    if (s.media.genre) parts.push(s.media.genre);
    if (s.media.rating) parts.push(s.media.rating.toFixed(1));
    if (s.media.pages) parts.push(`${s.media.pages} pages`);
    if (parts.length === 0 && s.media.year) parts.push(String(s.media.year));
    parts.push(...(s.media.tags ?? []).slice(0, 2));
    return parts.join(" · ");
  }
  return s.subtitle ?? s.source_platform;
}

export function tint(n: number): string {
  return "#" + Math.max(0, n).toString(16).padStart(6, "0");
}
