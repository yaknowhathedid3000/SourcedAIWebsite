# Albo, Front to Back

A complete teardown of **Albo: Save & Organize** (The Feel Good Project Ltd), written as a build spec for a SwiftUI rebuild. Every claim below is grounded in the ScreensDesign recording of app version 1.13.4 (build 657P), a 23-minute session of 206 screens captured on an iPhone in June 2026, plus ScreensDesign's market data for the app.

Screen numbers in this document (for example **#41**) refer to the index in the Appendix, where each row links to the recorded screen on ScreensDesign.

---

## 0. Orientation

### 0.1 What the numbers say

| Metric | Value | Source |
|---|---|---|
| Category | Lifestyle | App Store |
| Released | 16 May 2025 | App Store |
| Last updated | 27 Aug 2026 | App Store |
| App Store rating | 4.9 (3K+ ratings shown in-app) | App Store, screen #4 |
| Est. monthly downloads | 150,000 | ScreensDesign |
| Est. monthly revenue | $50k (Jul 2026), up from $20k (May) and $35k (Jun) | ScreensDesign |
| Price | $29.99 / year after a 3-day free trial ("Yearly Hoarder") | Screen #42 |
| Tiers | Pro and Max | Screen #198 |
| Onboarding length | 25 steps, 3m46s to first home screen | Recording |
| Team | Isaac, Karolina and Jake ("Made with love by...") | Screen #204 |

Revenue was zero through April 2026 and hit $50k by July. The app is fifteen months old. The ScreensDesign profile flags it as a "Free Trial, Soft Paywall" app. That growth curve plus a $30/year price point means the onboarding funnel below is doing very heavy lifting. Study it accordingly.

### 0.2 What Albo is

Albo is a universal save-for-later app. You share a TikTok, Instagram reel, web page, or screenshot into it, and Albo extracts structured objects: places with pins on a map, recipes with ingredients and steps, films, books, products, workouts, events. It then nags you (gently) to actually use what you saved, and rewards you with streaks, stamps, credits and a leaderboard when you do.

The tagline on the welcome screen is "A new way to explore a new city". The value proposition on the social-proof screen is sharper: **"Albo helps you actually do the things you save."** The paywall's final framing is a graph from "Endless Doomscrolling" to "Booked & Busy". That is the thesis. Every feature maps back to it.

### 0.3 How to read this

Chapters 1 through 3 give the product, the object model and the design language. Chapters 4 through 15 walk every flow screen by screen. Chapter 16 is the Swift build spec: architecture, data model, frameworks, component inventory and a screen-to-view map. Chapter 17 is a build order. The Appendix indexes all 206 screens.

Each flow section uses three recurring callouts:

- **Pattern** names the reusable UX mechanism.
- **Why it works** explains the behavioral reasoning.
- **Build** gives the SwiftUI implementation note.

---

## 1. Product thesis and business model

### 1.1 The job to be done

People save things on social platforms and never return to them. Albo's job is to move a save from "bookmarked and forgotten" to "done". The onboarding quiz options on screen #5 spell out the six sub-jobs the team has validated:

1. Actually do the things I save
2. Keep all my saves in one place
3. See all my saves pinned on a map
4. See my saved recipes as ingredients and steps
5. Stop losing things I find online
6. Be able to find my saves much easier

These six lines are the product roadmap in user language. The rest of the app is the delivery mechanism for each.

### 1.2 Revenue model

- **Subscription**: "Yearly Hoarder", $29.99/year, 3-day free trial, soft paywall (skippable via the X on screen #41).
- **Tiers** (screen #198): Pro = "Unlimited imports, AI chat & limited bulk import". Max = "Unlimited bulk import, early access to Pro features".
- **Credits**: imports are metered in lightning-bolt credits. The Get Started checklist (screens #146 to #149) unlocks "520 extra imports" for completing seven tasks, and referrals pay "100 credits for every friend who joins". Credits are the free-tier throttle and the growth loop at once.
- **Referral and ambassador program**: Settings has "Redeem Referral Code" and "Ambassador Program" (screen #191), and Edit Profile links to the ambassador program (screen #175).

### 1.3 Platforms

- iOS app (this teardown).
- Web app at albo.inc with a "Bulk Import" section (screen #102).
- Browser extension "Albo Browse" for Chrome and Edge, used to bulk-sync saves from social platforms (screen #102).
- iOS share extension "Add to Albo" (screens #53, #77, #90).
- Invite links at join.albo.inc (screen #77).

---

## 2. Information architecture and object model

### 2.1 Navigation skeleton

A five-item tab bar, visible from screen #56 onward:

| Position | Icon | Screen | Chapter |
|---|---|---|---|
| 1 | Home | Library | 7 |
| 2 | Globe | Map | 12 |
| 3 | Plus (center) | Add anything sheet | 8 |
| 4 | People | Community feed (Following / Community / Nearby / Events) | 13 |
| 5 | Avatar | Profile | 14 |

Every top-level tab also carries a floating action button bottom-right with a bookmark or mascot glyph, which opens Ask Albo (screens #56, #57, #85, #93). Library's header has a bell (Notifications, screen #131) and a share icon.

### 2.2 The object model

Albo has one core noun, the **Save**, which is polymorphic by category. The categories appear in the Library chip row, in the review picker (screen #104) and in the list picker (screen #108):

| Category | Icon on screen #104 | Detail view seen |
|---|---|---|
| Recipe | Dutch oven | #69, #85, #86, #121, #157 |
| Place | Map | #137, #140 |
| Film | VHS tape | store screenshots only |
| Book | Novel | search results #105 |
| Product | Shopping basket | not opened in recording |
| Workout | Kettlebell | search results #110, #111 |
| Software | Vintage computer | not opened |
| TV Show | Retro TV | not opened |
| Event | Ticket | #167 |
| Article | Newspaper | #56 (web link card) |
| Tutorial | Blueprints | not opened |
| Game | Controller | not opened |

Around the Save sit the secondary nouns:

- **Collection**: user-named folder with cover image, description (200 chars), privacy (Public / Private), collaborators via invite link. Every save also lives in the implicit "All My Saves" collection (screen #70).
- **List**: a typed, optionally ranked, ordered set of saves with a title, description and photos (screens #108, #109, #112). Lists appear on profiles under "Lists".
- **Category view** ("Saved Recipes", "Saved Books", and so on): a system-generated smart view per category with tabs All / Want to try / Made (screen #113). Note the verb changes by category: recipes are "Made", places are "Visited".
- **Review** (a "Journal" entry): sentiment tag, title, stars, completion date, photos, tagged friends, friends-only flag (screen #83). Reviews surface on the item, on the profile Journal, on the community feed and in the Calendar.
- **Private note**: free text on an item (screen #88, "Lessen sugar").
- **Comment**: public, threaded, with like / reply / share (screen #88).
- **Reminder**: scheduled local notification on a save (screen #92).
- **Note** (a save type): a markdown document Albo analyzes for entities (screens #67, #68).
- **Social graph**: follow / followers, friends, "common saves" count, tagging friends in reviews.
- **Gamification state**: credits, streak weeks, stamps, leaderboard rank.

### 2.3 Item states

A save moves through these states, visible in the tab bars and toggles:

1. **Saved** (default; appears in All)
2. **Want to try / Want to go / Wanna** (explicit intent, drives map filter "Want to go" and profile "Wants to Try")
3. **Made / Visited / Read / Cooked** (done; unlocks review, streak and stamp progress)

The "Made it?" and "Visited?" controls on detail screens (#69, #137) are slider-style buttons, not toggles, to make completion feel like an act.

---

## 3. Design language

The notes in this chapter were verified against the rendered screens, not only the text transcripts. Where the two disagree, the screen wins.

### 3.1 Typography

Albo runs two families and uses the contrast deliberately:

- **Display serif**, bold, high contrast, used for: the "Library" header, "Add anything", "How was it?", "Saved Recipes", every item title ("Triple Chocolate Cookies", "New York City Bar", "Crispy Smashed Potato Salad"), the profile name ("Julia"), and, in italic, the category tabs ("Want to try", "Made") and journal entries ("Cooked Carbonara, loved it"). The wordmark "Albo" is a heavier, chunkier cut of the same idea with the mascot peeking from the left and "BY THE FEEL GOOD PROJECT" stacked small at top-right.
- **Sans**, for everything else: onboarding headlines ("What brings you to Albo?", "How the trial works"), body, buttons, chips, metadata, settings rows. Onboarding headlines are set in a heavy sans weight; body sans is regular with slightly open letter-spacing.
- **Uppercase labels** with wide tracking and a hairline on each side: "OR MANUALLY SEARCH THESE".

**Font match.** The serif has ball terminals on the y and a, a tall x-height, and a true italic. That is Apple's **New York** (the system serif), which is what an iOS app gets from `.fontDesign(.serif)`. Match it directly rather than licensing anything:

| Role | Albo uses | SwiftUI | Web or design-file stand-in |
|---|---|---|---|
| Display serif (titles, "Library", "How was it?") | New York Bold | `.font(.system(.largeTitle, design: .serif, weight: .bold))` | Source Serif 4 700, or Fraunces 700 for a warmer take |
| Italic serif (tabs, journal lines) | New York Bold Italic | `.fontDesign(.serif).italic()` | Source Serif 4 Italic |
| Sans (headlines, body, buttons) | SF Pro Display / Text | `.fontDesign(.default)` | Instrument Sans or Public Sans |
| Wordmark | custom heavy slab-ish serif | asset | asset |

**Build**: Use `.fontDesign(.serif)` at `.title` or `.largeTitle` with `.bold` for the serif roles and `.fontDesign(.default)` for the rest. Italic serif tabs are `.italic()`. Ship the wordmark as an image asset.

### 3.2 Color

Approximate values sampled from the screens:

| Token | Approx. hex | Where |
|---|---|---|
| Ground | #FFFFFF, with #F4F4F4 for grouped surfaces and sheet scrims | everywhere |
| Ink | #1C1C1E | text, primary button fill |
| Option fill | #EFEFEF | quiz option pills, chips, secondary buttons |
| Disabled button | #C8C8C8 fill, white text | "Show me how!" before the animation finishes, "Submit" before a chip is chosen |
| System blue | #0A7AFF | "Tap here" callouts, blue checkmarks, location warm-up Continue, "Start now", trial progress bar gradient |
| Reward green | #22C55E (gradient to #16A34A) | "Claim! +2" buttons, the trial "Today" unlock icon |
| Danger red | #D6203A | "Sign Out", "Cancel my subscription", "Remove from All My Saves", the trial "Reminder" bell icon, "Endless Doomscrolling" pill |
| Brand orange | #F5891F | app icon square, list-editor timer pill, TIPS card |
| Rating yellow | #FFF4CC fill, #F5B800 stars | the 4.9 card |
| Category purple | #9B4DFF | the word "film" highlighted inside "See a film you love?" (each category gets its own highlight color) |
| Map night | #0B1B2B to black, with stars | globe screen background |

Dark mode is a full theme (#200), not an inversion: surfaces go to dark grey and the serif titles stay.

### 3.3 Shape and depth

- **Primary CTA**: full-width pill, ink fill, white bold label, with a **hard black offset shadow** roughly 4pt below (a chunky, almost 3D look). The red "Sign Out" and "Cancel my subscription" buttons use the same construction in red. This shadow is the single most recognizable detail in the app; do not flatten it.
- **Option pills**: fully rounded, light grey fill, emoji leading, filled black circular check trailing when selected (#5). Sentiment chips invert to black fill with white text when selected (#83).
- **Cards**: white, corner radius around 20pt, very soft drop shadow. Category cards in the Add sheet and the review picker carry a photorealistic 3D object.
- **Sheets**: all secondary flows are bottom sheets with a grab handle, large radius top corners, white on a dimmed background.
- **Slide-to-confirm**: "Made it?" and "Visited?" are not buttons. They are a grey pill track with a dark circular knob and chevron on the left; the user drags to confirm (#69, #137, #157). Completion should feel like an act.
- **Glass**: the location warm-up (#133) is a frosted-glass card over the dark globe, with a white inner note box and a system-blue Continue.
- **Watermark**: recipe detail with no hero image shows a faint repeating fork-and-knife pattern behind the title (#69).
- **Hero fade**: place and recipe heroes fade to white at the bottom, with the serif title overlaid on the fade (#137, #157).

### 3.4 Illustration system

- **The mascot** is a black rounded shape with two curved white eye slits, drawn like a tooth or a friendly ghost. It is the logo, the Ask Albo button, the default avatar, and the alternate app icons. Costume variants seen: chef hat with spatula ("Cooks"), reading a blue book on a stack of books ("Reads"), holding a newspaper ("News"), crown and red ermine robe with scepter ("King", Pro plan), purple robe with lightning bolt (Max plan), safari hat with sunglasses and backpack (traveler), 3D glasses with popcorn (film fan), safari hat reading a map (explorer, location warm-up), at a laptop (bulk import), on a rocket (ambassador). Leaderboard avatars default to these variants.
- **Category objects** are photorealistic 3D renders on white: red Dutch oven (Recipes), folded paper map (Places), stack of VHS tapes (Films), a book ("The Housemaid", Books), green shopping basket (Products), pink exercise ball with blue dumbbells (Workouts), beige Macintosh (Software), vintage TV (TV Show), red ticket stubs (Event), newspaper (Article), rolled blueprints (Tutorial), GameCube controller (Game). Add-sheet actions use the same style: chain links, sticky note, Polaroid camera, cardboard boxes, gold star, mix tape.
- **Emoji as icons** in chips, ingredient rows, quiz options and sentiment chips.
- **Confetti**: thin colored parallelograms scattered over celebratory screens (#26, #31, #44, #147).
- **Tutorial cursor**: a pixel-art white hand with black outline (#6, #22) and a yellow pointing-hand emoji next to a bright blue "Tap here" box.

### 3.5 Navigation chrome

- Tab bar: house, a globe with mascot eyes, plus, two people, the user's avatar (ring when selected). No labels.
- Floating Ask Albo button: the mascot face in a white circle with shadow, bottom-right, on Library and detail screens.
- Category views add two stacked white circular FABs: dice (Decider) and plus.
- Progress header on every guided flow: back chevron left, thin grey track with a black fill, optional "Skip" right.

### 3.6 Component vocabulary

You will build these once and reuse them across the whole app:

| Component | First seen | Used on |
|---|---|---|
| Progress header (back arrow + thin progress bar, optional Skip) | #4 | every onboarding step, import carousel, pin-shortcut tutorial |
| Primary pill button (black) | #3 | everywhere |
| Selectable option card (icon, label, trailing check) | #5 | quizzes, discovery survey, platform picker |
| Social-proof stat cards | #4 | onboarding |
| Testimonial card (avatar, handle, flag, 5 stars, snippet) | #4, #32 | onboarding |
| Feature carousel card with floating metadata chip | #15 | onboarding |
| "Tap here" callout with pointing-hand emoji | #22 | tutorials |
| Bottom sheet action menu (grab handle, header row, two big square buttons, list rows, red destructive row) | #91 | item overflow everywhere |
| Sentiment chip row (emoji + label) | #80 | review |
| Star rating widget | #83 | review, Apple prompt |
| Ingredient row (emoji, name, quantity, checkbox, strike-through when checked) | #31, #69, #132 | recipe detail |
| Serving multiplier (minus, 1x, plus, Convert / Original) | #31, #86 | recipe detail |
| Category chip row (Recipes, Places, Films, Books, Products, Workouts, ...) | #6, #47 | Library, Add sheet |
| Masonry two-column card grid | #145 | community feeds |
| Reaction bar (heart, laugh, wow, sad, fire, thumbs up, plus) | #164 | community cards |
| Reminder date grid (This week / Next week / In 2 weeks / In 3 weeks) | #92 | reminders |
| Get Started task card with credit reward | #146 | community tab overlay |
| Settings row (icon, title, subtitle, chevron or toggle) | #191 | settings tree |
| Toast pill (top, black, icon + text) | #78, #194 | confirmations |
| Empty state (illustration, headline, subline, pill CTA) | #47, #116, #127, #130, #161 | everywhere |

### 3.7 Copy voice

Albo writes in second person, short, playful, slightly self-deprecating. Real strings from the recording, verbatim:

- "Choose wisely. This is how your friends find you." (username)
- "First name, full name, your alter ego, up to you." (name)
- "Add a profile picture please" (note the "please")
- "Helps us make Albo feel like home faster." (quiz subline)
- "Pick anything that catches your eye."
- "Importing... watching everything at 2x speed" (loading state)
- "12 places found in Instagram video. Just like magic!"
- "Don't let a good save go to waste" (notifications)
- "ALBO'S BOX OF UNUSED SAVES" (building your plan)
- "Less scrolling, more doing" / "Endless Doomscrolling" to "Booked & Busy"
- "Welcome to the Digital Hoarder's Club!"
- "Let's send in your first thing!"
- "Nothing to decide yet. Save some recipes first so the Decider has something to pick from."
- "Report bad extract" (an honest name for an AI-failure report)
- "Hoarders" and "Yappers" (leaderboard tabs: most saves, most reviews)
- "Made with love by Isaac, Karolina & Jake, from the feel good project"

Rules to copy: name the user's world, not the system's ("Things Albo found", not "Extracted entities"). Always pair a loading state with a joke. Name the brand's users ("Digital Hoarder") and let them wear it as a badge.

---

## 4. Onboarding, screen by screen (0:00 to 3:46)

Twenty-five steps, one paywall, three quiz questions, two social-proof screens, two feature carousels, one notification warm-up, zero ATT warm-up. ScreensDesign's own rating calls out the magic-import demos as the standout moment (uniqueness 9/10) and the orbiting-icon intro, the "building your plan" box and the post-purchase welcome as distinctive (8, 8 and 7).

### 4.1 Cold ATT prompt (#1, 0:00)

The very first frame is the iOS App Tracking Transparency dialog, with no warm-up screen. Copy: "This allows Albo to provide you with a more personalised experience and measure the effectiveness of our campaigns."

**Pattern**: Cold permission ask.
**Why it works (or does not)**: It gets the ask out of the way before the user has any reason to say no, and Albo relies on paid social acquisition (see the discovery survey). ScreensDesign scores this as friction. If you rebuild, consider a one-screen warm-up; otherwise copy as-is and measure.
**Build**: `ATTrackingManager.requestTrackingAuthorization` on first launch, before any UI. Include `NSUserTrackingUsageDescription` in Info.plist.

### 4.2 Splash (#2, 0:03)

White ground, black blob logo centered, "Albo" wordmark bottom-center with "BY THE FEEL GOOD PROJECT" beside it.

**Build**: A `LaunchScreen` storyboard or SwiftUI splash that matches the first onboarding view so the transition is seamless.

### 4.3 Welcome with orbiting icons (#3, 0:07 to 0:18)

Language chip "EN" top-right. A ring of pastel circular icons (fitness, food, browser, social apps, book, film) orbits the black logo. Tagline "A new way to explore a new city". Black "Get Started" pill, then "Already have an account? Sign in".

**Pattern**: Animated integration carousel replacing static slides.
**Why it works**: Motion signals product quality in the first two seconds and shows breadth (every platform Albo pulls from) without a bullet list.
**Build**: `TimelineView(.animation)` driving a `ForEach` of icon views positioned with `cos`/`sin` around a center; rotate the phase over time. Reuse the same component on the sign-in screen (#45), where it appears again.

### 4.4 Social proof wall (#4, 0:21)

Progress header. Illustration of stylized people cooking, traveling, watching films. Headline **"Albo helps you actually do the things you save"**. Two white stat cards: "148k+ Happy users", "3.9M+ Saves made". A yellow-tinted card: "4.9" with stars and "3K+ App Ratings". Then a testimonial list (avatar, handle, country flag, five stars, one-line review), partly covered by the fixed "Continue" button.

**Pattern**: Stats plus testimonials, before any ask.
**Why it works**: Trust is established before the quiz asks for anything. The fixed CTA overlapping the list signals "there is more" and invites a scroll.
**Build**: `ScrollView` with a `safeAreaInset(edge: .bottom)` containing the button so content scrolls under it.

### 4.5 Quiz 1: "What brings you to Albo?" (#5, 0:31)

Sub-heading "Because I want to...". Six multi-select option cards (listed in 1.1). Selected state: black checkmark at the trailing edge.

**Pattern**: Goal quiz, multi-select.
**Build**: `SelectableOptionCard` with a `Set<Goal>` binding. Persist answers; they drive the "Building your plan" checklist copy later (#37).

### 4.6 Reinforcement mockup (#6, 0:38)

"You came to the right place". Sub-copy: "Albo pulls ingredients and step-by-step instructions straight out of your TikTok recipes." A large mockup of the Library home (search bar, category chips, Recently imported cards, Collections with names like "I'm Totally Coming Back To This Later" and "Brussels Baybeee"). A pixel-art hand cursor points into the mockup. CTA "Let's go".

**Pattern**: Answer-reactive reinforcement. The sub-copy responds to the recipe goal chosen in #5.
**Build**: Map each quiz goal to a headline + subline + mockup asset. Show the one matching the first selected goal.

### 4.7 Profile creation (#7 to #13, 0:53 to 1:10)

Four sub-steps, all under the same progress header:

1. **Username** (#7): field with live availability check (green check + "Available"), "12/20" counter, helper "3-20 characters, letters, numbers, and underscore", and a requirements card with five checkmarks: at least 3, max 20, no spaces, only letters/numbers/underscores, available.
2. **Name** (#8): "What should I call you?" single field.
3. **Profile picture** (#9 to #13): circular plus placeholder above name and @handle. Continue is disabled until a photo exists. Tapping opens a two-option sheet: "Choose from Gallery" / "Take a Photo". Gallery is the iOS limited-photos picker (#11), then a dark "Crop Image" screen with Cancel / rotate-flip / Done (#12), then the filled state (#13).

**Pattern**: Front-loaded identity. Username before any content is unusual and signals the social layer is core.
**Why it works**: The "friends find you" framing makes it feel purposeful. Live validation removes anxiety. ScreensDesign counts this as friction; keep it only if you are building the social layer.
**Build**: `TextField` with a debounced `Task` calling an availability endpoint; `PhotosPicker` from PhotosUI; a crop view via `UIViewControllerRepresentable` wrapping a cropping library or a custom `GeometryReader`-based crop.

### 4.8 Discovery survey (#14, 1:15)

"How did you end up here?" Single-select list: Friend or Family, TikTok, Instagram, YouTube, Threads, X, Search Engine, LinkedIn, Reddit, Other.

**Pattern**: Self-reported attribution.
**Why it works**: With ATT declined by most users, this is the team's channel data. Post to analytics immediately.

### 4.9 Feature carousel (#15 to #18, 1:18 to 1:27)

Four cards, each with the same shape: headline "See a [film / recipe / spot] you love? Save it to Albo in one tap.", a large rounded media card with a floating metadata chip (clapperboard, "Once Upon a Tim...", Comedy, 2019; or ingredient tags "Garlic 1 clove", "Prawns 200g" floating over a cooking video; or emoji food icons over a moody London restaurant photo captioned "VIBEY LONDON RESTAURANTS for 2025"), then a fourth card with a light map and food-emoji pins: "Every place you save gets pinned on a map." CTA on each: "Show me how!"

**Pattern**: Before/after value demo, one object type per card.
**Build**: `TabView(.page)` with a shared `FeatureCard` view; the floating chip is an overlay aligned `.bottomTrailing` with a small offset.

### 4.10 Quiz 2: where do you save now (#19, 1:33)

"Where do you save things at the moment?" / "Helps us make Albo feel like home faster." Four cards: Social Media (row of seven platform icons), Websites (globe, Google, Safari), My notes app, Screenshots. Multi-select.

### 4.11 Reassurance (#20, 1:36)

"No problem! Albo can import anything from Instagram, TikTok, Facebook, Pinterest and YouTube." Phone illustration with floating platform icons. CTA "Show me how".

**Pattern**: Objection handling immediately after the answer that raised it.

### 4.12 Quiz 3: content interests (#21, 1:43)

"What kind of videos, posts or links do you typically save?" / "Pick anything that catches your eye." Cards: Travel, Restaurants, Recipes, Workout routines, Shopping, Books, Articles. Blue checkmarks here (the only quiz with blue rather than black; treat as an inconsistency, pick one).

### 4.13 Magic import demo 1: Instagram (#22 to #26, 1:50 to 2:00)

Header "How to save to Albo" with a row of five platform icons. A phone mockup plays a simulated sequence:

1. An Instagram post "JAPAN FOOD GUIDE" with a blue "Tap here" box and yellow pointing hand over the share icon.
2. The Instagram share sheet, "Tap here" over "Share to...".
3. The iOS share sheet, "Tap here" over the Albo icon.
4. A modal "Importing... watching everything at 2x speed".
5. Result screen (#26): "12 places found in Instagram video. Just like magic!" A white card "Japan Food Guide" with a Japan map, pins, and a list: Suba (Soba noodle shop, 3.7, $$), Yakumo (Ramen, 4.2, $$), Iseya Sohonten (Izakaya, 3.7, $$), Warito... Confetti. Black "Continue".

**Pattern**: Simulated tutorial with a real payoff.
**Why it works**: The user has not installed the share extension yet, but has now watched the entire happy path end to end and seen a concrete, impressive output. This is the "aha" before the paywall.
**Build**: A scripted `TutorialPlayer` view: an array of steps `(mockupImage, calloutRect, calloutText)` advanced by a timer, with a spring-animated callout. The result card is the same `PlaceListCard` used in the real product.

### 4.14 Magic import demo 2: web link (#27 to #31, 2:12 to 2:23)

Same header. A Safari mockup of chewoutloud.com "Easy Jamaican Jerk Chicken Recipe" (378 ratings, 112 comments). Steps: "Tap here" on the browser "..." menu, then Share (blue ring), then the Albo icon, then "Importing...", then result (#31): "1 recipe found in web link. Just like magic!" Card with the dish photo, an Ingredients section with a 1x quantity adjuster and an emoji-prefixed checklist (chicken legs 10 pieces, olive oil 1/3 cup, light brown sugar 2 tbsp, dried thyme, allspice, smoked paprika, cinnamon, ginger, cloves, cayenne, garlic powder). Confetti. Continue.

**Build**: Same `TutorialPlayer`; the result is the real `RecipeIngredientsSection` component.

### 4.15 Team photo and scrolling reviews (#32, 2:32)

A composite photo of three kids (the founders as children) above a horizontally scrolling testimonial carousel. First review by "Mialdonetti": "As a college student, the LAST thing I wanna do is go on to Instagram to find one of the hundr..." Second: "I LOVE IT!"

**Pattern**: Founder humanization. The team-as-kids photo is the single most personal moment in the flow.

### 4.16 Notification warm-up with a rating ask riding along (#33 to #36, 2:46 to 2:50)

Headline "Don't let a good save go to waste". Subline (sic): "Let Albo will remind you about events and limited time offers." Illustration: calendar plus the mascot. Skip is available. CTA "Enable notifications".

Before the system prompt appears, the Apple in-app rating dialog fires (#33: "Enjoying Albo? Tap a star to rate it on the App Store"), followed by "Thanks for your feedback. You can also write a review." (#34). Then the notification system prompt (#36): "Albo needs notification access to send you reminders, updates, and important information."

**Pattern**: Piggybacked rating request at the emotional peak after the magic demos.
**Why it works**: The 4.9 rating with 3K+ ratings is partly manufactured here. Users who just watched "12 places found... just like magic" are primed.
**Build**: `SKStoreReviewController.requestReview(in:)` (or `RequestReviewAction` in SwiftUI) immediately before `UNUserNotificationCenter.requestAuthorization`. Fix the copy typo.

### 4.17 Building your plan (#37, 2:55)

Illustration: a cardboard box labeled "ALBO'S BOX OF UNUSED SAVES" with a game controller, an old TV, a newspaper and a vinyl record flying out. Progress bar "Making Albo yours / Building your watchlist..." at 98%. Checklist "Setting up your Albo for": Trips you want to plan, Saved places & restaurants, Workouts to try, Things to buy, Films & shows to watch (last one spinning).

**Pattern**: Fake progress with personalized checklist items.
**Why it works**: It makes the quiz answers feel used and adds a beat of anticipation before the sell.
**Build**: A `ProgressView` driven by a timer, with checklist rows that flip from spinner to check in sequence. Compose the checklist from quiz answers.

### 4.18 Final value proposition (#38 to #40, 2:59 to 3:04)

1. **Graph** (#38): "Less scrolling, more doing". A curve rising from "Endless Doomscrolling" (Now) to "Booked & Busy" (Your goal). Copy: "You're on your way to turning saved spots into trips you actually take. Never be stuck for somewhere to go again." Continue.
2. **Premium feature mockup** (#39): "Turn recipes into ingredients and steps". Two overlapping phone mockups showing "Saved TV Shows" and "Saved Books" grids. Below: a checkmark and **"No Payment Due Now"**. Continue.
3. **Reminder promise** (#40): calendar + mascot. "You'll get a reminder 1 day before your trial ends." Again "No Payment Due Now". Continue.

**Pattern**: Trial anxiety removal in three beats before the price is shown.
**Why it works**: "No Payment Due Now" appears on three consecutive screens before the paywall and once on it. The reminder promise directly counters the number one reason people refuse trials.

### 4.19 Paywall (#41 to #43, 3:07 to 3:15)

Title "How the trial works". Back arrow and X to close (soft paywall). Vertical timeline with three icons:

- **Today** (green unlock): "Unlock access to all the app's features like unlimited saves & bulk importing saves from other apps."
- **In 2 Days, Reminder** (red bell): "We'll send you a reminder that your trial is ending soon."
- **In 3 Days, Billing Starts** (yellow crown): "You'll be charged on June 14, 2026 unless you cancel anytime before."

Then "No Payment Due Now", the black button **"Start My 3-Day Free Trial"**, and the footer "3 days free, then $29.99 per year". No monthly option is offered. No discount, no timer.

Tapping the button opens the StoreKit sheet (#42): "Yearly Hoarder, Albo: Save & Organise, 3-day free trial, $29.99 per year, No commitment. Cancel anytime in Settings", then the system "You're all set. Your purchase was successful." (#43).

**Pattern**: Trial-timeline paywall (Blinkist-style), single SKU, soft close.
**Why it works**: A single annual plan with a computed billing date is the highest-ARPU configuration for a trial-based app. The timeline restates the reminder promise for the third time.
**Build**: StoreKit 2. One `Product` with an introductory offer of 3 days free. Compute the billing date as `Date() + 3 days` and format with `Date.FormatStyle`. Wire the X to skip; the user continues with the free tier (credits-limited).

### 4.20 Post-subscription welcome (#44, 3:20)

A bottom sheet with a grab handle, presented over the sign-in screen's orbiting icons: the mascot in a crown and red ermine robe holding a scepter, confetti, **"Welcome to the Digital Hoarder's Club!"**, "You've unlocked unlimited bulk imports and premium features. Time to save everything!", black "Get Started".

**Pattern**: Post-purchase celebration and identity naming.
**Build**: Present only on a successful transaction. The crowned mascot is reused as the "King" alternate app icon (#199) and in the Pro/Max plan cards (#198).

### 4.21 Sign in (#45 to #46, 3:27 to 3:29)

The orbiting-icon animation returns. Two buttons: "Continue with Apple", "Continue with Google". Google triggers the ASWebAuthenticationSession consent "Albo Wants to Use accounts.google.com to Sign In".

**Pattern**: Sign-up after payment. The user pays before creating an account, so the purchase is tied to the Apple ID and the account is created after.
**Build**: `SignInWithAppleButton` from AuthenticationServices; Google via `ASWebAuthenticationSession` or the Google Sign-In SDK. On success, link the StoreKit transaction to the new user server-side.

---

## 5. First-run activation (3:48 to 4:36)

### 5.1 Empty Library with a modal (#47)

The Library home behind: header "Library", a chip row (Recipes, Places, Films, Books, Products, Workouts), a "Recently saved" section reading "You have no saves. The content you share to albo will appear here." and a "Get Started" pill with a badge. Over it, a modal: illustration of social icons and a vintage TV, **"Let's send in your first thing!"**, "Try saving from your favorite social media app, we'll show you how.", black "Show me how", "Maybe later".

### 5.2 Platform picker (#48)

"Which platform would you like to send things from?" List: TikTok, Instagram, Safari, Facebook, YouTube, LinkedIn, Pinterest, Threads.

### 5.3 Per-platform instructions (#49)

"How to share from Safari": black "View video instruction & setup" and a text link "I prefer text instructions".

### 5.4 Live guided save (#50 to #54)

The user is sent to Safari with a floating Albo overlay coaching each step: a dark speech bubble "Press More" pointing at the "..." button (#50, #51), then in the share sheet a mockup bubble "Tap Me!!!" pointing at "Edit Actions" and later at "Add to Albo" in the actions list (#52, #53). The share extension UI (#54) is minimal: header with logo, "Saved!", search and plus icons, an "Add note" field and a "Done!" button.

### 5.5 Detection and celebration (#55, #56)

Back in the app, a modal: large check, **"Great job! We detected that you successfully sent an import. You're all set up!"**, blue Continue. The Library now shows the web link card "10 of the Best Things to do..." under Recently saved, and an empty Collections section with "+ New" and "Start creating collections to organize your saves".

**Pattern**: Guided first action with automatic detection.
**Why it works**: The share-extension path is the whole product; a user who completes it once retains. The app detects the extension's write (App Group) and celebrates without the user tapping anything.
**Build**: The share extension writes into a shared App Group container or a shared Core Data / SwiftData store. The main app observes a `firstImportDetected` flag on `scenePhase == .active`. The Safari overlay is a picture-in-picture-style tutorial; on iOS you cannot draw over Safari, so Albo ships this as an in-app video ("View video instruction") and the "Press More" bubble is the video's content. Rebuild it as a short looping video or Lottie asset.

---

## 6. The Add sheet and import modalities

### 6.1 "Add anything" hub (#60)

Opened from the center tab. Title "Add anything" with subline "Search up anything you want to save or you have done!" Six large cards with 3D icons:

| Card | Subline |
|---|---|
| Paste any URL | Articles, blogs, TikTok, Instagram & more |
| Notes | Make a note of anything and we'll analyse it |
| Screenshots | Add from your camera roll |
| Bulk Import | Add everything from TikTok & Insta in one click |
| Review | Rate something you watched, read, or visited |
| List | Build a curated ranked list of items |

Then "OR MANUALLY SEARCH THESE": a chip row of categories each with a search glyph (Recipes, Places, Films, Books, Products, Workouts).

**Build**: A `.sheet` with `presentationDetents([.large])` containing a `LazyVGrid` of two columns.

### 6.2 Import via Link (#61 to #66)

A modal with a four-segment progress indicator and a paste field pinned at the bottom ("Paste your link here" + "Paste" button). The carousel above teaches: "Click on Share, find the share menu" (TikTok mockup) → "Click on More, tap Send to Albo" → "Click on Albo, Detecting Spots." → "Organise into collections, You're all set" → "Find your saves again at any time!" with a map mockup ("Entalula Island"). Tapping Paste triggers the iOS pasteboard permission "Albo would like to paste from Notes" (#65). With a URL in the field, the button becomes "Import" (#66).

**Build**: `UIPasteboard.general.string` triggers the system paste prompt; use `PasteButton` in SwiftUI to avoid it. The carousel is a `TabView(.page)` and is purely educational.

### 6.3 Notes (#67 to #69)

A markdown editor: title "Cookie recipes", body "- ## **Triple Chocolate Cookies***italic*", a toolbar above the keyboard (B, I, H, list, link), Save top-right. After save, a "Saved" state shows **"Things Albo found"**: a card "Triple Chocolate Cookies, 15 mins, American, Dessert, 1 save" plus a "Reanalyze" checkbox. Tapping the card opens the full recipe (#69).

**Pattern**: Free text in, structured objects out.
**Build**: `TextEditor` with a custom `inputAccessoryView` or a SwiftUI toolbar `.keyboard` placement. Send the text to the extraction endpoint on save; render results as `SaveCard`s.

### 6.4 Screenshots (#96 to #98)

"Import via Screenshot": a dashed drop zone "Tap to select from camera roll", an orange TIPS card ("You can import anything from: Conversations about plans, Google Maps lists, TikTok screenshots etc"), "Choose Photos". The limited-photos picker (#97) shows "2 Photos, Locations Included". The staging view (#98) shows "Imports 2/9" thumbnails with remove buttons, "+ Add More Pictures", and a black "Import". The cap is nine per batch.

**Build**: `PhotosPicker(selection:maxSelectionCount: 9, matching: .screenshots)`. Upload as multipart; show per-image progress.

### 6.5 Bulk Import via the browser extension (#100 to #103)

A short branching questionnaire: "Do you have your laptop with you? You would need your laptop to do this" (Yes! / No), then "Do you have Chrome or Edge installed on your laptop?" (Yes! / No, but I can install it / No), then instructions "How to bulk import with Albo Browse": 1. Sign into albo.inc on your laptop, 2. Open the Bulk Import section in the web app, 3. Install the Albo Browse extension on Chrome or Edge when prompted, 4. Select your platforms and watch your saves come in. A black button with a Chrome icon "Get link to Albo web" opens the share sheet with the albo.inc link titled "Save Everything".

**Pattern**: Cross-device handoff with a pre-flight questionnaire.
**Why it works**: The questionnaire stops users who cannot complete the task from starting it. This is the Max tier's headline feature.

### 6.6 Review (#104 to #107)

"What do you want to review? Pick a category to find what you watched, read, or visited." A 12-card grid (see 2.2). Choosing Book opens a search sheet; "project hail mary" returns "Project Hail Mary, Science fiction, 4.5, 496 pages, 763 saves" plus lesser matches (#105). Selecting one opens the review form (chapter 10).

### 6.7 List (#108 to #112)

"Make a list of... Pick what your list is about. You can add items next." Six types: Recipe, Place, Film, Book, Workout, TV Show. The editor (#109) has Cancel, a live timer pill (00:01, then 00:33, 01:11) and Share at the top; "Add photos" dashed box; "Give your list a title"; "Add a description (optional)"; an "Items" card with a count and "Add a workout"; and a "Ranked list" toggle: "Number items by rank, great for top 10 lists." Adding an item opens a search ("Pull-up": results show tags Bodyweight, Strength, Upper Body, Back and save counts with avatars; "lateral raise" similar). The finished list "Home workout" shows items "1. Lateral Raise, 2. Pull-Up" with remove and drag handles.

**Build**: `List` with `.onMove` for reordering and `EditButton`-free custom drag handles; the timer pill is a `TimelineView(.periodic(from:by: 1))`.

### 6.8 Manual search

The category chips at the bottom of the Add sheet open the same typed search used in Review and List. "carbonara" (#120) returns three Carbonara recipes with times (10, 30 min), cuisines (Italian, Italian-American, Roman), save counts and a megaphone "Wanna" glyph per row.

---

## 7. Library (home tab)

The Library (#56, #99) is a vertical scroll:

1. Header "Library" with bell and share icons.
2. Horizontal category chip row with 3D icons.
3. "Recently saved": a horizontal carousel of mixed-type cards (image, markdown note, web link), each with a small type glyph. A "Get Started" pill with a red badge sits at the row's start until the checklist is complete.
4. "Collections": "+ New" trailing; cards show cover, name, Public/Private, owner avatar.
5. Tab bar and the Ask Albo floating button.

Tapping a category chip opens its smart view (chapter 9). The search bar "Search saves..." appears in the onboarding mockup (#6) but not in the recorded home; treat search as a header action.

---

## 8. Item detail anatomy

### 8.1 Recipe (#69, #85, #86, #87, #121, #157)

Top to bottom:

1. Nav: back, share, kebab.
2. Hero image (when present), overlaid source caption ("i tuoi piatti da fuorisede" on the Carbonara).
3. Title, meta chips (15 mins · American · Dessert), "1 save" with avatars, category tag "Recipes", "+ Collections" button.
4. **Status row**: after a review, a badge card ("Hidden Gem" with a diamond and a refresh icon) and a review card ("Reviewed Triple Chocolate Cookies, a hidden gem", 5 stars, thumbnail, "i love the texture!").
5. **Action row**: "Made it?" slider button with a forward arrow, and "Wanna" with a megaphone.
6. Yield ("Makes 12 cookies" / "Serves 4-6").
7. **Ingredients**: copy icon, multiplier (minus, 1x, plus), "Convert" (units) which becomes "Original" after converting, then rows with emoji, name, quantity, and a checkbox that strikes the row through.
8. **Instructions**: numbered steps, each with a small illustrative icon (egg, wheat, chocolate, timer).
9. "Mentioned in": the source note or link card.
10. "Add a note..." field, then a "Private note" card with timestamp.
11. "Comments & Reviews": count, input with send, comments with like / reply / share.
12. Floating Ask Albo button.

### 8.2 Place (#137, #140)

Hero photo, title "New York City Bar", category "Association / Organization", rating 4.2, "4 saves", "Collections". Action row: "Visited?" slider and "Wanna". A four-button row: View on map, Call, Website, More. Hours "Opens Friday at 9 AM to 5 PM". Photo carousel. Description with "Read" link. Map snippet with neighborhood label ("LENOX HILL"). From the map, a compact sheet (#140) shows flag, Directions / Website / More, "No opening times found", photos, "1167 saves" and a like count.

### 8.3 Event (#167)

Hero with gradient, title, organizer, date "13 Jul 2026", category "Community", venue, "1 save", Collections, **"Add to calendar"**, "Wanna", description, "Starts on Jul 13, 2026 at 10:00 AM", address, map snippet. Add to calendar prompts EventKit access (#168) then opens a fully pre-filled native "New Event" form (#169) with title, location, start/end, travel time, repeat, calendar, alerts.

**Build**: `EKEventEditViewController` via `UIViewControllerRepresentable`, pre-populated from the event save.

### 8.4 The overflow sheet (#91, #114, #141)

Identical on every item type. Grab handle; header row with thumbnail, title, meta and a megaphone button; two large square buttons **Share** and **Reminder**; list rows: Add to collection, Change cover image, Add review / Mark as done, Report bad extract; red row "Remove from All My Saves".

**Build**: One `ItemActionsSheet(item:)` with `presentationDetents([.medium, .large])`.

### 8.5 Share

Share uses the system sheet with an albo.inc URL (#90). The same sheet is where users discover "Add to Albo" is present.

---

## 9. Organizing

### 9.1 Collections

- **Add to collection sheet** (#70, #115, #122): "All My Saves" (checked, non-removable), "Add to a collection", "New collection" button, then existing collections with a plus.
- **New Collection** (#71 to #77): Step 1: cover square with a refresh icon (tap opens "Choose cover image": Choose from Photos / Search the web), name field with "7/50" counter, description "What makes this collection special?" with "0/200". Next. Step 2: privacy dropdown "Public, Anyone can see". Done. Step 3: **"Invite Friends"** with "Create & Share Invite" (black) and "Not Now". Creating shows a toast "Invite link created and ready to share" and a system share sheet with a join.albo.inc link.
- **Delete confirmation** (#119): red trash icon, "Remove 1 item", "Are you sure you want to remove this item? They will also be removed from any collections.", Cancel / red Remove.

**Pattern**: Collaboration-first collections. Inviting friends is the last step of creation, not buried in a menu.

### 9.2 Category smart views (#113, #116, #117, #124 to #126)

"Saved Recipes" with subline "All the recipes found in your library". Tabs: All / Want to try / Made. Cards: thumbnail, title, meta, the private note as a chip ("Lessen sugar"), kebab. Header actions: grid/list toggle and "Select". Bottom-right two floating buttons: a dice (the Decider) and a plus.

- **Select mode** (#117, #118): header becomes "1 selected" with kebab and close; rows get checkmarks; a floating bar with four circular buttons (add to collection, add to list, mark done, trash).
- **Empty state under Made** (#116): chef-hat mascot, "You haven't completed any Recipes yet", "Recipes will start to appear here as you share more things to Albo."
- **Decider empty state** (#127): red Dutch oven, "Nothing to decide yet", "Save some recipes first so the Decider has something to pick from.", pill "Find Recipes". The Decider is a random picker from the Want to try set.

**Build**: A generic `CategoryView<Category>` driven by an enum; `EditMode` for selection; a `.confirmationDialog` for delete.

---

## 10. Reviewing and journaling

### 10.1 "How was it?" (#80 to #84, #106, #107, #123)

Two-stage form:

1. **Sentiment**: megaphone icon, "How was it?", seven chips in a flow layout: Loved it (heart), Hidden gem (diamond), It's okay (smile), Meh (neutral), Overhyped (exploding head), Not for me (shrug), Avoid (no-entry). Submit is disabled until one is chosen.
2. **Details**: the chosen chips collapse into a horizontal row; "Title" field with placeholder "What did you love about it?"; five stars; date row "Completed Jun 10" (opens a calendar picker "Select date" with Cancel / OK) and a "Don't remember" button; dashed "Add photos" (Choose from Gallery / Take a Photo; uploaded photos show with a remove badge); "Tag people you did this with" (opens a friend search sheet with an empty state "Add friends to tag them in your reviews"); "Friends only" checkbox; black Submit.

### 10.2 After submit

A top toast "Marked as complete" and a modal **"1 week streak"** surrounded by fire emoji: "Keep marking saves as done to extend your streak." Continue (#78, #79). The item gains a badge and a review card (#85). The review appears on the profile Journal as "Cooked Triple Chocolate Cookies, a hidden gem, 10 Jun" (#186), in the Calendar on its date (#172), and, unless friends-only, on the community feed as a card with stars and the title text (#162).

**Pattern**: One action, five surfaces. A single review feeds the item, the journal, the calendar, the feed and the streak.
**Build**: `Review` is a first-class model. Emit a domain event on create; each surface subscribes.

### 10.3 Journal on the profile (#185 to #190)

Per category tab, the profile shows: a "Recommendations" card ("Recipes rated 4 stars or above"), a "Wants to Try" / "Wants to Go" list, and "Journal" with a sort menu (Timeline / Rating). Entries read like sentences: "Cooked Carbonara, loved it", "Visited London, not for me", "Read Project Hail Mary, loved it". Lists appear under "Lists" on the Workouts tab.

### 10.4 Calendar (#172)

Vertical month grid (M to S). Days with reviews show the item thumbnail (a dish on Jun 10, the Project Hail Mary cover on Jun 11). Future months render faded.

---

## 11. Reminders and notifications

### 11.1 Set a Reminder (#92, #142)

Sheet: "Remind me in the" selector defaulting to "Morning (9:00 AM)"; groups This week / Next week / In 2 weeks / In 3 weeks, each a horizontal row of day cards ("Fri 12 Jun"); a "Custom date & time" button. Sundays are omitted in some rows (Sun 21 and Sun 28 are missing), which looks like a bug; do not copy it.

The default time comes from Preferences (#203): Morning 9:00 AM, Afternoon 12:00 PM, Evening 6:00 PM, Before bed 10:00 PM.

**Build**: `UNCalendarNotificationTrigger`. Store the reminder on the save; render the Notifications list (#131) from delivered notifications plus server-side history: "Reminder: Triple Chocolate Cookies" with the item description and "6 minutes ago". Tapping opens the item (#132).

### 11.2 Location notifications (#193, #194)

A dedicated settings page: toggle "Enable Notifications, Get notified near saved places"; a "How it Works" list: Background Notifications ("even when the app isn't open"), Battery Efficient ("only checks when you move significantly"), Privacy Focused (**"Only monitors the 20 closest saved places. No continuous tracking or data sent to servers."**); a Permissions row showing "When In Use (Upgrade to Always for background)" and a black "Upgrade to Always" button. Enabling shows a toast "Location notifications enabled!"

**Build**: `CLLocationManager` region monitoring is capped at 20 regions per app, which is exactly why the copy says 20. Use significant-change monitoring to re-pick the 20 nearest saved places whenever the user moves.

### 11.3 Notification preferences (#192)

Enable Notifications (master), Location Notifications (chevron), Reminders & To-dos, Friends & Social, Marketing, each with a one-line description.

---

## 12. Ask Albo (AI)

Two entry points, one component:

- **Global** (#57 to #59, #128, #129): from the Library FAB. Header with logo and "Ask Albo", a large mascot circle, "Ask Albo about anything you've saved", input "Ask anything..." with a circular up-arrow send. Empty-library answer: "It looks like your library is currently empty, so I don't have any saved items to recommend as the best thing to do. If you'd like to start building your list, feel free to share some links, recipes, or places..." Each answer has copy and regenerate icons; the header has a refresh that asks "Clear chat? This will delete the messages in this conversation." Cancel / Clear.
- **Per item** (#93 to #95): "Ask Albo about Triple Chocolate Cookies". The recorded answer to "How much sugar is needed?" was "I'm sorry, but the recipe details I have available don't list the specific ingredients", even though the ingredients were on screen. Answers carry copy, regenerate, thumbs up and thumbs down.

**Build**: A `ChatSheet(scope: .library | .item(id))` with a streaming transcript. Send the item's structured fields as context so the per-item chat can answer quantity questions. AI chat is a Pro feature (#198), so gate it behind entitlement.

---

## 13. Map

- **Entry** (#133): a custom warm-up modal over a blurred dark globe: hat-wearing mascot with a map, "Enable Location for Better Experience", three bullets (Show places near you, Calculate distances to saved locations, Provide personalized recommendations), a shield note "Your location data stays private and is never shared", blue Continue.
- **Globe** (#134, #144): a 3D globe on a starry dark background with country labels, saved places as icons (a museum glyph in New York, a flag in the UK) with uppercase labels like "WANT TO GO". Bottom: a filter pill "Show all" with a chevron, a search bar "Search places...", and two floating buttons (a building icon that opens a places list, a crosshair to recenter).
- **Filter menu** (#138): Search in collection..., Want to go, Only my saves, Show all.
- **Zoomed map** (#135, #139, #143): standard map tiles with a blue user marker; a London pin with a UK flag and "WANT TO GO" caption; a bookmark-style pin for "Only my saves".
- **Places list** (#136): a sheet listing places matching "New York City" with thumbnail, name, category, rating, "31 saves" with avatars and a megaphone.
- **Place sheet** (#140, #141) and its overflow are the same components as chapter 8.

**Build**: MapKit with `Map` in SwiftUI (iOS 17), `MapStyle.imagery` or a custom dark style for the globe, `Annotation` views for pins with flag emoji and caption. Filters are a `Menu`.

---

## 14. Community and social

### 14.1 Feed (#145, #161 to #166)

Segmented header: Following / Community / Nearby / Events, search icon right. A "Get Started" banner card "Save content from anywhere to get started" sits above the grid until the checklist completes. The grid is two-column masonry: image, stars, title or review text, author avatar, and a reaction button. Long-press opens a reaction bar: heart, laughing, surprised, sad, fire, thumbs up, plus. Following empty state: "No posts yet. Posts will appear here as people share."

**Events** is a chronological list grouped by date header ("13 July / Monday"): thumbnail, title, time and venue, and a flyer preview. Recorded events were Manila-based (IVE fan support at PICKUP COFFEE, Wave to Earth at SM Mall of Asia Arena, BTS at Philippine Sports Stadium), so Events is location-aware.

### 14.2 Post detail (#156)

Author header ("Kimmy", Follow, share), hero photo, "1m 34s" video length badge, a "Recipes" section with the linked save card ("Crispy Smashed Potato Salad, 45 mins, 1165 saved"), and a comment composer ("Say something...", GIF, count, bookmark).

### 14.3 Public profile (#158 to #160)

Name, handle, avatar, "1 common save" badge, Followers / Following / Saves, a Following button, and category tabs with counts (Collections, Recipes (1), Places (0), Films (0), Books, Events, Articles, Tutorials, Games). The share icon opens a profile card modal (photo, name, "United States", "0 Collections", "7 Saves", "New to Albo on Albo", Copy Link / Share).

### 14.4 Add Friends (#180 to #182)

Search users, a "Find your friends on Albo! Tap to sync your contacts now!" card, "Meet the Albo team!" with Isaac (37 friends on Albo), Karolina @ Albo (14), Jakee (11), each with Follow. A QR icon top-right opens the camera (permission copy: "Albo needs camera access to take profile pictures and scan QR codes") with "Cancel" and "My QR" buttons.

### 14.5 Chat (#130)

Empty state: notepad illustration, "Find Friends" button. Direct messaging exists but was not exercised.

---

## 15. Gamification, growth and settings

### 15.1 Get Started checklist (#146 to #149)

A sheet over the community feed: lightning icon, "Get Started", "Progress 2/7", "Get started with Albo to unlock 520 extra imports." A hero task card rotates through incomplete tasks with a large illustration and a green "Claim! +N" or blue "Start now" button. Tasks and rewards observed:

| Task | Copy | Reward |
|---|---|---|
| Try making a list | | +2 |
| Import a screenshot | Share things you see in videos, or irl. | +2 |
| Import 5 things | Kickstart your collection. (0/5) | +4 shown, +10 listed |
| Pin the Albo shortcut | Import things to Albo even faster. | +2 |
| Invite friends | Earn 100 credits for every friend who joins | +500 |
| Try bulk importing | Add a whole collection of saves at once. | +2 |
| Try reviewing something | Rate and review one of your saves. | +2 |

### 15.2 Pin the Albo shortcut (#150 to #155)

A tutorial sheet: "How to pin the Albo shortcut", a phone mockup of the iOS share sheet (with real-looking apps: AirDrop, WhatsApp, Instagram, Claude, "Find products on Amazon"), captions "Albo doesn't show in your share sheet by default...", "You have to pin it", "Now you can save to Albo in a single tap", a progress bar, and "Let's do it". The final step (#155) is a real share sheet opened on the albo.inc/how-to/pin-to-share URL showing "Edit Actions" so the user can favorite "Add to Albo".

**Build**: Open `UIActivityViewController` on a help URL; the user pins the extension there. Ship the mockup steps as a looping video.

### 15.3 Streaks, stamps, leaderboard

- **Streak** modal after marking done (chapter 10).
- **Stamps** (#183, #184): a grid of badges; "Digital Hoarder" is locked with a progress bar "Import 10 things, 2 / 10" and subtitle "Build up your stash in Albo!"
- **Leaderboard** (#196, #197): segmented "Hoarders" (by saves; #1 Claire with 22,437 saves; the user pinned at top as "#117455, You, 0 saves") and "Yappers" (by reviews; #1 Malak, 186 done; user "#62"). Rank, avatar, name, handle, count.

### 15.4 Settings tree (#191 to #206)

**General**: Notifications (chapter 11), Account Settings (Make Account Private toggle with a confirm dialog "When your account is private, only people you approve can see your profile, collections, and imports"), Leaderboards, Manage Subscription (Pro / Max cards, "Change my plan", red "Cancel my subscription"), Appearance (Theme Light / Dark / System; App Icon grid: Default, Browse, King, Reads, Cooks, News, with the system alert "You have changed the icon for Albo"), Language (System default, English, Español, 中文 简体, 日本語, 한국어, Deutsch, Français, Bahasa Indonesia, and a "Want another language?" button), Preferences (Default Map: Apple Maps / Google Maps; Default Reminder Time; Places: Enabled, Show in profile).

**Resources**: Ambassador Program, Step by Step Guides, Set up Albo shortcut, Albo Web, Redeem Referral Code, QR Code Scanner.

**Footer**: Give us a rating, Our website, FAQs, Request Features, Email us any feedback, Report a bug, Delete Account (sheet: "After you confirm, your account will be deleted within the next 14 days", a "Reason for leaving" dropdown, optional details 0/500, Confirm Deletion disabled until a reason is chosen), Terms of Service, Privacy Policy, red "Sign Out" with a confirm, User ID with copy, "Version 1.13.4 (657P), Release", the team credit, and four social icons (Instagram, Threads, TikTok, X).

### 15.5 Permission map

| Permission | When | Warm-up | Screen |
|---|---|---|---|
| Tracking (ATT) | First frame | None | #1 |
| Photos (limited) | Profile picture, screenshots, review photos | None, system picker | #11, #97 |
| Notifications | Onboarding after demos | Custom screen with Skip | #35, #36 |
| Pasteboard | Import via Link | None | #65 |
| Location (When In Use) | First map open | Custom modal with three benefits and a privacy note | #133 |
| Location (Always) | Location notifications settings | Explanatory page with "Upgrade to Always" | #193 |
| Calendar | Add event to calendar | None | #168 |
| Camera | Take a photo, QR scan | None (usage string explains both) | #181 |
| Contacts | Add Friends sync | Card "Tap to sync your contacts now!" | #180 |

---

## 16. Swift build spec

### 16.1 Architecture

- **Platform**: iOS 17 minimum (SwiftUI `Map`, `NavigationStack`, `PhotosPicker`, `PasteButton`, SwiftData all land cleanly). Swift 5.10+, strict concurrency on.
- **Pattern**: MVVM with `@Observable` view models per screen and a small set of injected services. One `AppState` for session, entitlement and tab selection.
- **Persistence**: SwiftData (or Core Data) in an **App Group** container so the share extension and the main app read the same store. Sync via the backend; treat local as cache.
- **Networking**: `URLSession` + `async/await`; a typed `APIClient` with endpoints for auth, saves, extract, collections, reviews, reminders, social, chat, gamification.
- **Targets**: `Albo` (app), `AlboShare` (share extension: "Add to Albo"), `AlboWidgets` (optional, not in recording), `AlboKit` (shared models, API client, design system as a Swift Package).

### 16.2 Frameworks

| Need | Framework |
|---|---|
| Sign in | AuthenticationServices (Apple), Google Sign-In SDK or ASWebAuthenticationSession |
| Subscriptions | StoreKit 2 (`Product`, `Transaction`, `subscriptionStatus`) |
| Rating prompt | StoreKit `RequestReviewAction` |
| Tracking prompt | AppTrackingTransparency |
| Photos | PhotosUI `PhotosPicker` (limited access mode) |
| Camera / QR | AVFoundation, `DataScannerViewController` (VisionKit) for QR |
| Map / globe | MapKit (`Map`, `Annotation`, `MapStyle`) |
| Location | CoreLocation (region monitoring, significant-change) |
| Reminders | UserNotifications (`UNCalendarNotificationTrigger`) |
| Calendar | EventKit + EventKitUI (`EKEventEditViewController`) |
| Contacts sync | Contacts (`CNContactStore`) |
| Share extension | Social / UIKit `SLComposeServiceViewController` or a SwiftUI-hosted `NSExtensionPrincipalClass` |
| Alternate icons | `UIApplication.setAlternateIconName` (Info.plist `CFBundleIcons`) |
| Markdown notes | AttributedString markdown + custom keyboard toolbar |
| Confetti / motion | SwiftUI `TimelineView`, `Canvas`, or a small particle view |
| Localization | String Catalogs (9 languages listed on #202) |

### 16.3 Data model (Swift)

```swift
enum SaveCategory: String, Codable, CaseIterable {
    case recipe, place, film, book, product, workout, software
    case tvShow, event, article, tutorial, game, note
}

enum SaveStatus: String, Codable { case saved, wantTo, done }

@Model final class Save {
    @Attribute(.unique) var id: UUID
    var category: SaveCategory
    var title: String
    var subtitle: String?            // "Soba noodle shop", "Association / Organization"
    var coverURL: URL?
    var sourceURL: URL?              // instagram.com/..., chewoutloud.com/...
    var sourcePlatform: String?      // tiktok, instagram, safari, screenshot, note
    var status: SaveStatus
    var saveCount: Int               // "1165 saves"
    var createdAt: Date
    var privateNote: String?
    var collections: [Collection]
    var reviews: [Review]
    var reminder: Reminder?
    var recipe: RecipeDetails?       // ingredients, steps, yield, time, cuisine, course
    var place: PlaceDetails?         // coordinate, rating, priceLevel, hours, phone, website, photos
    var event: EventDetails?         // start, end, venue, organizer, address
    var media: MediaDetails?         // year, genre, pages, runtime, author
}

struct Ingredient: Codable, Identifiable {
    var id: UUID
    var emoji: String
    var name: String
    var quantity: Double?
    var unit: String?
    var checked: Bool
}

struct RecipeDetails: Codable {
    var timeLabel: String            // "15 mins", "Multi-day project"
    var cuisine: String?             // "American"
    var course: String?              // "Dessert"
    var yieldLabel: String?          // "Makes 12 cookies"
    var ingredients: [Ingredient]
    var steps: [String]
    var baseMultiplier: Int = 1
}

@Model final class Collection {
    @Attribute(.unique) var id: UUID
    var name: String                 // max 50
    var details: String?             // max 200
    var coverURL: URL?
    var isPublic: Bool
    var owner: UserSummary
    var inviteURL: URL?              // join.albo.inc/...
    var saves: [Save]
}

@Model final class CuratedList {
    var id: UUID
    var category: SaveCategory
    var title: String
    var details: String?
    var photos: [URL]
    var isRanked: Bool
    var items: [Save]                // ordered
}

enum Sentiment: String, Codable, CaseIterable {
    case lovedIt, hiddenGem, itsOkay, meh, overhyped, notForMe, avoid
    var emoji: String { ... }        // heart, diamond, smile, neutral, exploding head, shrug, no entry
}

@Model final class Review {
    var id: UUID
    var save: Save
    var sentiment: Sentiment
    var title: String?
    var stars: Int?                  // 1...5
    var completedOn: Date?           // nil == "Don't remember"
    var photos: [URL]
    var taggedFriends: [UserSummary]
    var friendsOnly: Bool
}

struct Reminder: Codable {
    var fireAt: Date
    var slot: ReminderSlot           // morning 9, afternoon 12, evening 18, beforeBed 22, custom
    var notificationID: String
}

struct GamificationState: Codable {
    var credits: Int
    var streakWeeks: Int
    var checklist: [ChecklistTask]   // 7 tasks with reward and progress
    var stamps: [Stamp]              // "Digital Hoarder": 2/10
    var hoarderRank: Int?
    var yapperRank: Int?
}

enum Entitlement: String, Codable { case free, pro, max }
```

### 16.4 Navigation

```swift
enum Tab { case library, map, add, community, profile }

// Root
TabView(selection: $app.tab) {
    LibraryView()   .tag(Tab.library)
    MapView()       .tag(Tab.map)
    Color.clear     .tag(Tab.add)      // intercept selection, present AddSheet
    CommunityView() .tag(Tab.community)
    ProfileView()   .tag(Tab.profile)
}
.sheet(isPresented: $app.showAdd) { AddAnythingSheet() }
.overlay(alignment: .bottomTrailing) { AskAlboButton() }
```

Each tab owns a `NavigationStack` with a typed `Route` enum: `.save(id)`, `.collection(id)`, `.category(SaveCategory)`, `.profile(userID)`, `.settings`, `.settingsChild(SettingsRoute)`, `.calendar`, `.notifications`, `.stamps`, `.leaderboard`.

Sheets, not pushes, for: Add anything, Import via Link, Import via Screenshot, Review form, New Collection, Add to collection, Item actions, Set a Reminder, Ask Albo, Get Started checklist, Pin shortcut tutorial, Manage Subscription, Delete Account.

Onboarding is a separate `NavigationStack` rooted in `OnboardingCoordinator` with a `[OnboardingStep]` array so steps can be reordered from a remote config.

### 16.5 Design system package (`AlboKit/DesignSystem`)

Tokens:

```swift
enum AlboColor {
    static let ink        = Color("Ink")         // near-black text, primary button
    static let ground     = Color("Ground")      // white / near-black
    static let surface    = Color("Surface")     // light grey / dark grey cards
    static let accentBlue = Color("AccentBlue")  // tutorial callouts, selection
    static let brand      = Color("Brand")       // orange app icon, TIPS card
    static let reward     = Color("Reward")      // green claim buttons
    static let rating     = Color("Rating")      // yellow 4.9 card
    static let danger     = Color("Danger")      // red destructive
}

enum AlboRadius { static let card: CGFloat = 20; static let pill: CGFloat = 999; static let chip: CGFloat = 14 }
```

Components (one file each; names map to section 3.6):

`ProgressHeader`, `PrimaryButton`, `SecondaryButton`, `SelectableOptionCard`, `StatCard`, `TestimonialCard`, `FeatureCard`, `TapHereCallout`, `TutorialPlayer`, `ItemActionsSheet`, `SentimentChip`, `StarRating`, `IngredientRow`, `ServingMultiplier`, `CategoryChipRow`, `SaveCard`, `MasonryGrid`, `ReactionBar`, `ReminderDateGrid`, `ChecklistTaskCard`, `SettingsRow`, `Toast`, `EmptyState`, `Mascot(variant:)`, `Confetti`, `OrbitingIcons`.

### 16.6 Screen-to-view map

| Screens | SwiftUI view | Notes |
|---|---|---|
| #1 | `ATTGate` | Request before root appears |
| #2 | Launch screen | Static |
| #3, #45 | `WelcomeView`, `SignInView` | Share `OrbitingIcons` |
| #4, #32 | `SocialProofView`, `TeamReviewsView` | |
| #5, #19, #21 | `QuizStepView(question:options:multi:)` | Generic |
| #6, #20 | `ReinforcementView` | Answer-driven copy |
| #7 to #13 | `UsernameView`, `NameView`, `AvatarView` | PhotosPicker + crop |
| #14 | `DiscoverySourceView` | Single-select |
| #15 to #18 | `FeatureCarouselView` | `TabView(.page)` |
| #22 to #31 | `TutorialPlayer(script:)` + `ImportResultView` | Reuse real result cards |
| #33 to #36 | `NotificationsWarmupView` | Rating prompt first |
| #37 | `BuildingPlanView` | Timer-driven |
| #38 to #40 | `ValueGraphView`, `PremiumMockupView`, `TrialReminderView` | |
| #41 to #43 | `PaywallView` | StoreKit 2 |
| #44 | `WelcomeClubView` | On purchase only |
| #47 to #56 | `FirstImportCoach` | App Group detection |
| #56, #99 | `LibraryView` | |
| #57 to #59, #93 to #95, #128, #129 | `AskAlboSheet(scope:)` | Streaming |
| #60 | `AddAnythingSheet` | |
| #61 to #66 | `ImportLinkSheet` | `PasteButton` |
| #67, #68 | `NoteEditorView` | Markdown toolbar |
| #69, #85 to #92, #121, #132, #157 | `SaveDetailView` + `RecipeSection` | |
| #70, #115, #122 | `AddToCollectionSheet` | |
| #71 to #77 | `NewCollectionFlow` | 3 steps |
| #78, #79 | `StreakModal` | |
| #80 to #84, #106, #107, #123 | `ReviewFormView` | Two stages |
| #96 to #98 | `ImportScreenshotSheet` | Max 9 |
| #100 to #103 | `BulkImportGuide` | Branching |
| #104, #105, #110, #111, #120, #170 | `CategorySearchSheet(category:)` | Shared |
| #108, #109, #112 | `ListEditorView` | `onMove` |
| #113 to #119, #124 to #127 | `CategoryView(category:)` | Tabs, select mode, Decider |
| #131, #132 | `NotificationsView` | |
| #133 to #144 | `MapView`, `LocationWarmup`, `PlaceSheet`, `PlacesListSheet` | MapKit |
| #145, #161 to #166 | `CommunityFeedView` | 4 segments, masonry |
| #146 to #149 | `GetStartedSheet` | |
| #150 to #155 | `PinShortcutTutorial` | Ends in share sheet |
| #156 | `PostDetailView` | |
| #158 to #160, #171, #178, #179, #185 to #190 | `ProfileView(user:)` | Own vs public |
| #167 to #169 | `EventDetailView` + `EKEventEditView` | |
| #172 | `CalendarView` | |
| #173 to #175 | `EditProfileView`, `AddLinksSheet` | |
| #176, #177, #195 | `AccountSettingsView` | |
| #180 to #182 | `AddFriendsView`, `QRScannerView` | |
| #183, #184 | `StampsView`, `StampDetailView` | |
| #191 to #206 | `SettingsView` and children | |
| #54 | Share extension UI | Separate target |

### 16.7 Share extension contract

The extension receives a URL, text, or image. It writes a `PendingImport` record into the App Group store, posts a Darwin notification, shows "Saved!" with an optional note, and returns. The main app, on becoming active, drains pending imports through the extraction API and shows the "Great job!" modal on the very first one. Do not do network work in the extension beyond a fire-and-forget enqueue; extensions are memory-limited.

### 16.8 Backend surface the app assumes

`POST /extract` (url | text | images) returning typed saves; `GET/POST /saves`; `/collections` with invite tokens; `/lists`; `/reviews`; `/reminders`; `/social` (follow, friends, feed, nearby, events); `/chat` (streaming, scoped to library or item); `/gamification` (credits, checklist, stamps, leaderboard); `/billing/link` to attach a StoreKit transaction to a user. Search endpoints per category backed by third-party catalogs (books show pages and year, places show rating and price level, workouts show muscle-group tags).

---

## 17. Build order

Ship in this order so each milestone is usable:

1. **Foundation**: `AlboKit` package (tokens, components, models), App Group, auth, StoreKit 2, tab shell, Library with mock data.
2. **The core loop**: share extension → extraction → `SaveDetailView` for recipe, place, article. First-import detection and celebration. This alone is the product.
3. **Onboarding**: all 25 steps with the paywall. Instrument every step.
4. **Organize**: collections, category views, select mode, add-to-collection.
5. **Do**: review form, streak, journal, calendar, reminders (local notifications).
6. **Map**: warm-up, globe, filters, place sheet, location notifications.
7. **Grow**: Get Started checklist, credits, stamps, leaderboard, pin-shortcut tutorial, invites, referral codes.
8. **Social**: feed, reactions, post detail, profiles, follow, add friends, chat.
9. **AI**: Ask Albo global and per item, entitlement-gated.
10. **Polish**: alternate icons, dark mode pass, nine languages, Appearance and Preferences, delete account flow.

---

## Appendix: all 206 recorded screens

Timestamps are minutes:seconds into the 23m41s recording. Types are ScreensDesign's classification. Each link opens the screen on ScreensDesign.

| # | Time | Type | Flow | Visible text (sample) | Link |
|---|---|---|---|---|---|
| 1 | 0:00 | permissions | Onboarding & Account Setup | Ask App Not to Track · Allow | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302830) |
| 2 | 0:03 | other | Animated Feature Introduction | Albo · BY THE FEEL GOOD PROJECT | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302831) |
| 3 | 0:07 | onboarding | Animated Feature Introduction | EN · Albo · BY THE FEEL GOOD PROJECT | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302832) |
| 4 | 0:21 | onboarding | Social Proof | 148k+ Happy users · 3.9M+ Saves made · 4.9 | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302833) |
| 5 | 0:31 | onboarding | Personalization Quiz: User Goals | What brings you to Albo? · Because I want to... · Actually do the things I save | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302834) |
| 6 | 0:38 | onboarding | Profile Creation | You came to the right place · Let's go · Library | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302835) |
| 7 | 0:53 | onboarding | Profile Creation | Pick a username · juliascreens · Available | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302836) |
| 8 | 0:58 | onboarding | Profile Creation | What should I call you? · Julia · Continue | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302837) |
| 9 | 1:01 | onboarding | Profile Creation | Add a profile picture please · You can change this later. · Julia | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302838) |
| 10 | 1:02 | onboarding | Profile Creation | Add a profile picture please · You can change this later. · Julia | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302839) |
| 11 | 1:05 | permissions | Profile Creation | Photos · Collections · Private Access to Photos | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302840) |
| 12 | 1:08 | editor | Profile Creation | Crop Image · Cancel · Done | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302841) |
| 13 | 1:10 | onboarding | Profile Creation | Add a profile picture please · You can change this later. · Julia | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302842) |
| 14 | 1:15 | onboarding | Discovery Source Survey | How did you end up here? · Friend or Family · TikTok | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302843) |
| 15 | 1:18 | onboarding | Feature Value Carousel | Quentin Tarantino's · ONCE UPON A TIME IN HOLLYWOOD · Here I come. Here I come. | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302844) |
| 16 | 1:21 | onboarding | Feature Value Carousel | Garlic 1 clove · Him: 'I'll be home in 5' Me: · Prawns 200g | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302845) |
| 17 | 1:23 | onboarding | Feature Value Carousel | VIBEY LONDON RESTAURANTS · for 2025 · Show me how! | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302846) |
| 18 | 1:25 | onboarding | Feature Value Carousel | Show me how! | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302847) |
| 19 | 1:33 | onboarding | Personalization Quiz: Saving Habits | Where do you save things at the moment? · Social Media · Websites | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302848) |
| 20 | 1:36 | onboarding | Onboarding & Account Setup | No problem! · Show me how | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302849) |
| 21 | 1:43 | onboarding | Personalization Quiz: Content Interests | Pick anything that catches your eye. · Travel · Restaurants | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302850) |
| 22 | 1:50 | onboarding | Core Feature Demos | How to save to Albo · Tap here · JAPAN FOOD GUIDE | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302851) |
| 23 | 1:53 | onboarding | Core Feature Demos | How to save to Albo · Search · Fleur 玉潔 | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302852) |
| 24 | 1:54 | onboarding | Core Feature Demos | How to save to Albo · AirDrop · Messeges | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302853) |
| 25 | 1:57 | onboarding | Core Feature Demos | How to save to Albo · Importing... · watching everything at 2x speed | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302854) |
| 26 | 2:00 | other | Core Feature Demos | 12 places found in Instagram video · Just like magic! · Japan Food Guide | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302855) |
| 27 | 2:12 | onboarding | Core Feature Demos | How to save to Albo · Join our Free Recipe Club! · CHEW out loud | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302856) |
| 28 | 2:15 | onboarding | Core Feature Demos | How to save to Albo · Easy Jamaican Jerk Chicken Recipe · Tap here | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302857) |
| 29 | 2:17 | onboarding | Core Feature Demos | How to save to Albo · AirDrop · Messeges | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302858) |
| 30 | 2:20 | onboarding | Core Feature Demos | How to save to Albo · Importing... · watching everything at 2x speed | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302859) |
| 31 | 2:23 | other | Core Feature Demos | 1 recipe found in web link · Just like magic! · Easy Jamaican Jerk Chicken | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302860) |
| 32 | 2:32 | onboarding | Onboarding & Account Setup | Albo · Mialdonetti · Am | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302861) |
| 33 | 2:46 | onboarding | Permissions Warm-up | Skip · Don't let a good save go to waste · Enjoying Albo? | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302862) |
| 34 | 2:47 | onboarding | Permissions Warm-up | Skip · Don't let a good save go to waste · Thanks for your feedback. | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302863) |
| 35 | 2:49 | permissions | Permissions Warm-up | Skip · Don't let a good save go to waste · Enable notifications | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302864) |
| 36 | 2:50 | permissions | Building Your Plan | 11:33 · Skip · Don't let a good save go to waste | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302865) |
| 37 | 2:55 | onboarding | Building Your Plan | ALBO'S BOX OF UNUSED SAVES · Making Albo yours · Building your watchlist... | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302866) |
| 38 | 2:59 | onboarding | Final Value Proposition | Less scrolling, more doing · Booked & Busy · Endless Doomscrolling | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302867) |
| 39 | 3:03 | onboarding | Final Value Proposition | Turn recipes into ingredients and steps · Saved TV Shows · Saved Books | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302868) |
| 40 | 3:04 | paywall | Final Value Proposition | You'll get a reminder · 1 day · before | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302869) |
| 41 | 3:07 | paywall | Paywall | How the trial works · Today · In 2 Days - Reminder | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302870) |
| 42 | 3:10 | checkout | Paywall | How the trial works · Today · Unlock access to all the app's features | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302871) |
| 43 | 3:15 | paywall | Paywall | How the trial works · Today · In 2 Days - Reminder | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302872) |
| 44 | 3:20 | other | Post-Subscription Welcome | Welcome to the Digital Hoarder's Club! · Get Started | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302873) |
| 45 | 3:27 | onboarding | Connect Google Account | Continue with Apple · Continue with Google | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302874) |
| 46 | 3:29 | permissions | Connect Google Account | Cancel · Continue · Continue with Apple | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302875) |
| 47 | 3:48 | empty_state | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302876) |
| 48 | 3:51 | other | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302877) |
| 49 | 3:53 | other | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302878) |
| 50 | 4:02 | content_feed | Saving and Importing Content | Emily Luxton Travels · MENU · England | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302879) |
| 51 | 4:04 | other | Saving and Importing Content | 11:34 · Emily Luxton Travels · MENU | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302880) |
| 52 | 4:15 | other | Saving and Importing Content | MENU · THE BEST THINGS · ST ALBANS - | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302881) |
| 53 | 4:18 | other | Saving and Importing Content | Best Things to do in St... · Messages · Mail | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302882) |
| 54 | 4:29 | other | Saving and Importing Content | Saved! · Add note · Done! | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302883) |
| 55 | 4:33 | other | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302884) |
| 56 | 4:36 | home | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302885) |
| 57 | 4:41 | chat | Using AI Features | Library · Ask Albo · Ask Albo about anything you've saved | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302886) |
| 58 | 4:53 | chat | Using AI Features | Library · Ask Albo · Ask Albo about anything you've saved | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302887) |
| 59 | 4:59 | chat | Using AI Features | Library · Ask Albo · Ask Albo about anything you've saved | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302888) |
| 60 | 5:06 | other | Saving and Importing Content | Library · Add anything · Paste any URL | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302889) |
| 61 | 5:10 | form | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302890) |
| 62 | 5:15 | onboarding | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302891) |
| 63 | 5:19 | onboarding | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302892) |
| 64 | 5:24 | other | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302893) |
| 65 | 5:37 | permissions | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302894) |
| 66 | 5:39 | onboarding | Saving and Importing Content | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302895) |
| 67 | 6:20 | editor | Saving and Importing Content | Cookie recipes · Save | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302896) |
| 68 | 6:34 | editor | Saving and Importing Content | Saved · Cookie recipes · Things Albo found | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302897) |
| 69 | 6:36 | other | Saving and Importing Content | Triple Chocolate Cookies · 15 mins · American | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302898) |
| 70 | 6:41 | other | Organizing and Reviewing Content | Triple Chocolate Cookies · All My Saves · Add to a collection | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302899) |
| 71 | 6:48 | form | Organizing and Reviewing Content | New Collection · Next · Recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302900) |
| 72 | 6:51 | form | Organizing and Reviewing Content | New Collection · Next · Recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302901) |
| 73 | 6:59 | editor | Organizing and Reviewing Content | Crop Image · Cancel · Done | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302902) |
| 74 | 7:03 | form | Organizing and Reviewing Content | New Collection · Next · Recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302903) |
| 75 | 7:05 | form | Organizing and Reviewing Content | New Collection · Done · Public - Anyone can see | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302904) |
| 76 | 7:07 | other | Organizing and Reviewing Content | New Collection · Close · Invite Friends | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302905) |
| 77 | 7:12 | other | Organizing and Reviewing Content | New Collection · Close · Invite link created and ready to share | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302906) |
| 78 | 7:19 | other | Organizing and Reviewing Content | Marked as complete · 1 · week streak | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302907) |
| 79 | 7:21 | other | Organizing and Reviewing Content | 1 · week streak · Continue | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302908) |
| 80 | 7:23 | form | Organizing and Reviewing Content | How was it? · Loved it · Hidden gem | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302909) |
| 81 | 7:39 | form | Organizing and Reviewing Content | How was it? · Title · i lo | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302910) |
| 82 | 7:43 | form | Organizing and Reviewing Content | How was it? · Loved it · Hidden gem | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302911) |
| 83 | 8:04 | form | Organizing and Reviewing Content | How was it? · Hidden gem · Loved it | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302912) |
| 84 | 8:07 | other | Organizing and Reviewing Content | Tag people you did this with · Search friends · Add friends to tag them in your reviews | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302913) |
| 85 | 8:15 | content_feed | Saving and Importing Content | Triple Chocolate Cookies · 15 mins · American | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302914) |
| 86 | 8:29 | content_feed | Saving and Importing Content | Triple Chocolate Cookies · Ingredients · 3x | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302915) |
| 87 | 8:32 | content_feed | Saving and Importing Content | Triple Chocolate Cookies · Beat in the egg. · Gradually stir in the flour. | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302916) |
| 88 | 8:57 | other | Saving and Importing Content | Triple Chocolate Cookies · Mentioned in · Cookie recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302917) |
| 89 | 9:00 | other | Saving and Importing Content | Triple Chocolate Cookies · Mentioned in · Cookie recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302918) |
| 90 | 9:07 | other | Saving and Importing Content | Triple Chocolate Cookies · Mentioned in · Cookie recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302919) |
| 91 | 9:12 | other | Saving and Importing Content | Triple Chocolate Cookies · 15 mins · American | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302920) |
| 92 | 9:15 | form | Saving and Importing Content | Triple Chocolate Cookies · Set a Reminder · Remind me in the | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302921) |
| 93 | 9:26 | chat | Saving and Importing Content | Triple Chocolate Cookies · Ask Albo · Ask Albo about Triple Chocolate Cookies | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302922) |
| 94 | 9:36 | chat | Saving and Importing Content | Triple Chocolate Cookies · Ask Albo · How much sugar is needed? | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302923) |
| 95 | 9:43 | chat | Saving and Importing Content | Triple Chocolate Cookies · Ask Albo · Ask Albo about Triple Chocolate Cookies | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302924) |
| 96 | 10:03 | other | Saving and Importing Content | Import via Screenshot · Tap to select from camera roll · TIPS | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302925) |
| 97 | 10:09 | permissions | Saving and Importing Content | Photos · Collections · Private Access to Photos | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302926) |
| 98 | 10:18 | other | Saving and Importing Content | Import via Screenshot · Imports · 2/9 | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302927) |
| 99 | 10:26 | dashboard | — | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302928) |
| 100 | 10:31 | onboarding | — | Do you have your laptop with you? · You would need your laptop to do this · Yes! | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302929) |
| 101 | 10:36 | onboarding | — | Yes! · No, but I can install it · No | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302930) |
| 102 | 10:43 | other | — | How to bulk import with Albo Browse · Get link to Albo web | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302931) |
| 103 | 10:47 | onboarding | — | How to bulk import with Albo Browse · Save Everything · albo.inc | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302932) |
| 104 | 10:54 | other | — | Library · What do you want to review? · Recipe | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302933) |
| 105 | 11:10 | search | — | Library · project hail mary · Project Hail Mary | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302934) |
| 106 | 11:11 | form | — | How was it? · Loved it · Hidden gem | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302936) |
| 107 | 11:15 | form | — | How was it? · Loved it · Hidden gem | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302938) |
| 108 | 11:21 | home | — | Library · Recipes · Places | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302939) |
| 109 | 11:25 | editor | — | Cancel · 00:01 · Share | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302941) |
| 110 | 11:53 | search | — | Cancel · 00:33 · Share | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302943) |
| 111 | 12:14 | search | — | Cancel · Share · lateral raise | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302945) |
| 112 | 12:31 | editor | — | Cancel · 01:11 · Share | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302946) |
| 113 | 12:47 | content_feed | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302948) |
| 114 | 12:49 | other | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302950) |
| 115 | 12:51 | other | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302952) |
| 116 | 12:59 | empty_state | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302953) |
| 117 | 13:05 | content_feed | — | 1 selected · Saved Recipes · All the recipes found in your library | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302955) |
| 118 | 13:10 | other | — | 1 selected · Saved Recipes · All the recipes found in your library | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302957) |
| 119 | 13:28 | other | — | 1 selected · Saved Recipes · All the recipes found in your library | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302958) |
| 120 | 13:48 | search | — | Select · carbonara · Carbonara | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302960) |
| 121 | 13:53 | content_feed | — | i tuoi piatti da fuorisede · Carbonara · 30 minutes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302961) |
| 122 | 13:57 | other | — | Carbonara · All My Saves · Add to a collection | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302963) |
| 123 | 14:06 | form | — | How was it? · Loved it · Hidden gem | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302965) |
| 124 | 14:15 | content_feed | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302966) |
| 125 | 14:17 | content_feed | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302968) |
| 126 | 14:19 | content_feed | — | Saved Recipes · All the recipes found in your library · All | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302969) |
| 127 | 14:25 | empty_state | — | Nothing to decide yet · Find Recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302971) |
| 128 | 14:34 | chat | Exploring and Managing Settings | Library · Ask Albo · Ask Albo about anything you've saved | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302973) |
| 129 | 14:36 | chat | Exploring and Managing Settings | Library · Ask Albo · Ask Albo about anything you've saved | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302974) |
| 130 | 14:57 | empty_state | Exploring and Managing Settings | Chat · Find Friends | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302976) |
| 131 | 15:01 | other | Exploring and Managing Settings | Notifications · Reminder: Triple Chocolate Cookies · 6 minutes ago | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302978) |
| 132 | 15:04 | content_feed | Exploring and Managing Settings | Triple Chocolate Cookies · 15 mins · American | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302980) |
| 133 | 15:12 | permissions | Exploring and Managing Settings | Enable Location for Better Experience · We use your location to: · Show places near you | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302982) |
| 134 | 15:13 | home | Exploring and Managing Settings | Show all · Search places... · North America | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302984) |
| 135 | 15:20 | home | Exploring and Managing Settings | Bagbaguin · Manatal · Show all | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302986) |
| 136 | 15:43 | content_feed | Exploring and Managing Settings | New York City · New York City Apartments · Apartment rental agency | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302988) |
| 137 | 15:51 | other | Exploring and Managing Settings | New York City Bar · Association / Organization · 4.2 | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302990) |
| 138 | 16:26 | home | Exploring and Managing Settings | Bagbaguin · Manatal · Search in collection... | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302992) |
| 139 | 16:39 | home | Exploring and Managing Settings | Greenland · Svalbard · Iceland | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302994) |
| 140 | 16:43 | home | Exploring and Managing Settings | London · Want to go · Svalbard | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302996) |
| 141 | 16:45 | other | Exploring and Managing Settings | London · Want to go · Share | [view](https://screensdesign.com/apps/albo-save-organise/?vs=302998) |
| 142 | 16:46 | form | Exploring and Managing Settings | Set a Reminder · Remind me in the · Morning (9:00 AM) | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303000) |
| 143 | 17:14 | home | Exploring and Managing Settings | Only my saves · Search places · London | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303002) |
| 144 | 17:22 | home | Exploring and Managing Settings | 11:50 · North America · Greenland | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303004) |
| 145 | 17:34 | content_feed | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303006) |
| 146 | 17:37 | onboarding | Exploring and Managing Settings | Get Started · Progress · 2/7 | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303008) |
| 147 | 17:39 | onboarding | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303010) |
| 148 | 17:44 | onboarding | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303012) |
| 149 | 17:55 | onboarding | Exploring and Managing Settings | Get Started · Progress · 2/7 | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303014) |
| 150 | 18:07 | onboarding | Exploring and Managing Settings | How to pin the Albo shortcut · Reel from ryanresatka · instagram.com | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303016) |
| 151 | 18:10 | onboarding | Exploring and Managing Settings | 11:51 · Following · Community | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303019) |
| 152 | 18:14 | onboarding | Exploring and Managing Settings | How to pin the Albo shortcut · Let's do it · Following | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303021) |
| 153 | 18:26 | onboarding | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303023) |
| 154 | 18:35 | onboarding | Exploring and Managing Settings | Events · Reel from ryanresatka · instagram.com | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303025) |
| 155 | 18:39 | other | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303027) |
| 156 | 18:53 | content_feed | Exploring and Managing Settings | Kimmy · Follow · Recipes | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303029) |
| 157 | 18:58 | content_feed | Exploring and Managing Settings | Crispy Smashed Potato Salad · 45 mins · American | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303031) |
| 158 | 19:05 | profile | Exploring and Managing Settings | Kimmy · kpdubz · 1 common save | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303033) |
| 159 | 19:08 | profile | Exploring and Managing Settings | Kimmy · kpdubz · 1 common save | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303035) |
| 160 | 19:13 | profile | Exploring and Managing Settings | Kimmy · kpdubz · 1 common save | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303036) |
| 161 | 19:23 | empty_state | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303038) |
| 162 | 19:28 | content_feed | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303040) |
| 163 | 19:43 | content_feed | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303042) |
| 164 | 19:45 | content_feed | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303044) |
| 165 | 19:47 | content_feed | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303046) |
| 166 | 19:52 | content_feed | Exploring and Managing Settings | Following · Community · Nearby | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303048) |
| 167 | 19:56 | other | Exploring and Managing Settings | IVE · WORLD TOUR · SHOW WHAT I AM | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303050) |
| 168 | 19:58 | permissions | Exploring and Managing Settings | IVE WORLD TOUR SHOW WHAT I AM · Don't Allow · Allow | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303053) |
| 169 | 20:02 | form | Exploring and Managing Settings | New Event · Complex, Coral Way, MAAX Parking Bld... · All-day | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303055) |
| 170 | 20:26 | search | Exploring and Managing Settings | project hail mary · Cancel · Project Hail Mary | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303058) |
| 171 | 20:35 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303060) |
| 172 | 20:40 | other | Exploring and Managing Settings | Calendar · June 2026 · M | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303063) |
| 173 | 20:52 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303065) |
| 174 | 20:59 | profile | Exploring and Managing Settings | Edit Profile · Account Information · screensdesigntest@gmail.com | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303067) |
| 175 | 21:01 | profile | Exploring and Managing Settings | Edit Profile · Julia · Tell us about yourself... | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303069) |
| 176 | 21:10 | settings | Exploring and Managing Settings | Account Settings · Make Account Private | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303071) |
| 177 | 21:12 | settings | Exploring and Managing Settings | Account Settings · Make Account Private · Make Account Private? | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303073) |
| 178 | 21:25 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303075) |
| 179 | 21:29 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303077) |
| 180 | 21:35 | other | Exploring and Managing Settings | Add Friends · Search users... · Find your friends on Albo! | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303079) |
| 181 | 21:43 | permissions | Exploring and Managing Settings | 11:55 · Albo would like to access the Camera. · Don't Allow | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303081) |
| 182 | 21:48 | other | Exploring and Managing Settings | Back | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303083) |
| 183 | 21:51 | other | Exploring and Managing Settings | Stamps · Locked · Digital Hoarder | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303085) |
| 184 | 21:53 | other | Exploring and Managing Settings | Digital Hoarder · Locked · Build up your stash in Albo! | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303087) |
| 185 | 22:06 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303089) |
| 186 | 22:08 | home | Exploring and Managing Settings | Wants to Try · Crispy Smashed Potato Salad · 45 mins | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303091) |
| 187 | 22:10 | content_feed | Exploring and Managing Settings | Wants to Try · Crispy Smashed Potato Salad · 45 mins | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303093) |
| 188 | 22:15 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303095) |
| 189 | 22:21 | profile | Exploring and Managing Settings | Julia · juliascreens · 1 wk | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303097) |
| 190 | 22:25 | profile | Exploring and Managing Settings | Julia · juliascreens · Add links | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303098) |
| 191 | 22:35 | settings | Exploring and Managing Settings | Settings · General · Notifications | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303100) |
| 192 | 22:38 | settings | Exploring and Managing Settings | Notification Preferences · Enable Notifications · Location Notifications | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303102) |
| 193 | 22:41 | permissions | Exploring and Managing Settings | Location Notifications · Notifications · Enable Notifications | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303104) |
| 194 | 22:48 | settings | Exploring and Managing Settings | Location Notifications · Location notifications enabled! · Enable Notifications | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303106) |
| 195 | 22:53 | settings | Exploring and Managing Settings | Account Settings · Make Account Private | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303108) |
| 196 | 22:57 | other | Exploring and Managing Settings | Leaderboard · Hoarders · Yappers | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303110) |
| 197 | 23:00 | other | Exploring and Managing Settings | Leaderboard · Hoarders · Yappers | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303112) |
| 198 | 23:04 | settings | Exploring and Managing Settings | Settings · General · Notifications | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303115) |
| 199 | 23:06 | settings | Exploring and Managing Settings | Appearance · Theme · Light | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303117) |
| 200 | 23:09 | settings | Exploring and Managing Settings | Appearance · Theme · Light | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303119) |
| 201 | 23:11 | settings | Exploring and Managing Settings | Appearance · Theme · Light | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303120) |
| 202 | 23:16 | settings | Exploring and Managing Settings | Language · Change app language · System default | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303121) |
| 203 | 23:21 | settings | Exploring and Managing Settings | Preferences · Default Map for Directions · Apple Maps | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303122) |
| 204 | 23:34 | settings | Exploring and Managing Settings | Settings · Give us a rating · Our website | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303123) |
| 205 | 23:36 | settings | Exploring and Managing Settings | Settings · Give us a rating · Our website | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303124) |
| 206 | 23:41 | settings | Exploring and Managing Settings | Settings · Give us a rating · Our website | [view](https://screensdesign.com/apps/albo-save-organise/?vs=303125) |
