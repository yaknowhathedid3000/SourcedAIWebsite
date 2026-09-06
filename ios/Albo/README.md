# Albo (SwiftUI rebuild)

A screen-for-screen SwiftUI rebuild of Albo: Save & Organize, built from the
206-screen teardown in `docs/albo/albo-teardown.md`. Every view names the
recorded screen it reproduces (for example `// Albo #41`), so you can open the
frame on ScreensDesign next to the code.

## Open it

Requires Xcode 15.4 or newer and iOS 17.

```
brew install xcodegen
cd ios/Albo
xcodegen generate
open Albo.xcodeproj
```

If you would rather not use XcodeGen: create a new iOS App project named
`Albo` in Xcode (SwiftUI, Swift), delete the generated `ContentView.swift`
and `AlboApp.swift`, drag the `Albo` folder into the project, and paste the
usage-description keys from `project.yml` into the target's Info tab.

## What is here

| Folder | Contents | Albo screens |
|---|---|---|
| `App` | App entry, root tab bar, app state, sample data wiring | #56, #99 |
| `DesignSystem` | Colors, type, primary button with the hard offset shadow, option pills, progress header, slide-to-confirm, star rating, sentiment chips, toast, empty state, mascot, orbiting icons, confetti | #3, #5, #33, #69, #80 |
| `Models` | Save, categories, details, collections, lists, reviews, reminders, gamification, users | chapter 2 of the teardown |
| `Onboarding` | All 25 onboarding steps in one coordinator | #1 to #46 |
| `Library` | Library home, category smart views, save cards | #56, #99, #113 to #127 |
| `Detail` | Save detail (recipe, place, event, generic), action sheet, reminder sheet, add-to-collection, new collection flow, review form, streak modal | #69 to #95, #137, #167 |
| `Add` | Add anything hub, link import, screenshot import, note editor, list editor, category search, bulk import guide, review picker | #60 to #112 |
| `Map` | Globe map, location warm-up, filters, place sheet | #133 to #144 |
| `Community` | Following / Community / Nearby / Events, post detail, Get Started checklist, pin-shortcut tutorial | #145 to #169 |
| `Profile` | Profile, edit profile, calendar, stamps, leaderboard, add friends | #158 to #190 |
| `Settings` | Settings tree, notifications, appearance, language, preferences, manage subscription, delete account | #191 to #206 |
| `Chat` | Ask Albo (global and per item) | #57 to #59, #93 to #95 |
| `Paywall` | Trial timeline paywall and Digital Hoarder's Club welcome | #41 to #44 |
| `Shared` | The App Group inbox the share extension and the app both read | — |
| `../AlboShare` | The "Add to Albo" share extension | share sheet, #54 |

## Sharing into Albo

`AlboShare` is a share extension, so "Add to Albo" appears in every other app's share sheet
the way Albo's own does. It takes a link, some text, or up to ten images.

The extension deliberately does almost nothing: it reads the attachments, lets you confirm
the category it guessed, and writes an `InboxItem` into the App Group
(`group.com.sourcedai.albo`). Extensions get a small memory budget and no access to the
user's session, so the real work happens in the app — `ShareInboxImporter` drains the queue
on launch and on every return to the foreground, runs each item through the same
`ImportService` the Add sheet uses, and toasts what landed.

Consequences worth knowing:

- A shared link becomes a real save the next time you open Albo, not the instant you share it.
- Out of credits, or not signed in, and the queue is held rather than dropped — it imports
  once that is fixed. A dead link is dropped after one attempt so it cannot wedge the queue.
- The App Group must be enabled on **both** target identifiers. Enable it on only one and
  shares disappear silently. See `../../CONNECT.md`.

## Backend

`Backend/AlboBackend.swift` talks to the Supabase project in `../../supabase`
(schema, RLS, RPCs and edge functions). It compiles only when the
`supabase-swift` package resolves (`#if canImport(Supabase)`), so the app
builds and runs on sample data without it.

1. Create a Supabase project and run `supabase db push` from `supabase/`.
2. Deploy the edge functions and set the `ANTHROPIC_API_KEY` secret (see
   `supabase/README.md`).
3. Put the project URL and publishable key in
   `Albo/Resources/Albo.local.xcconfig` (git-ignored):
   ```
   SUPABASE_URL = https:/$()/<project-ref>.supabase.co
   SUPABASE_ANON_KEY = <publishable key>
   ```
4. `SyncEngine` starts after onboarding, pulls the library, and pushes local
   changes. Sign in with Apple, imports (`extract`) and Ask Albo (`ask-albo`)
   go through the same client. The web app in `../../web` shares the database.

## Parity notes

The layout, copy, type ramp, colors and motion follow the 206 recorded
screens in `docs/albo/screens.json` frame by frame. Two things are stand-ins
until the real assets exist, and both are single swap points:

- `SaveCover` and `CategoryIcon` use emoji on tinted grounds where Albo shows
  photos and rendered 3D icons.
- `MascotView` is a vector mascot with emoji costume hats.

No compiler was available where this was written, so build it in Xcode once
before shipping and treat any warning as a bug.

## What is real and what is local

With the backend configured, link, note and screenshot imports go through the
`extract` edge function, Ask Albo goes through `ask-albo` with chat history,
purchases go through StoreKit 2 (`com.sourcedai.albo.pro.yearly`, with
`Resources/Albo.storekit` attached to the run scheme for the simulator), and
the library syncs through `SyncEngine`. Without a backend the same calls fall
back to local heuristics so every screen still demos.

Still sample data until the social endpoints are wired: the community feed,
public profiles, leaderboards and stamps.
