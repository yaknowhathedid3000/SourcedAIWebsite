# Connecting Yogi to the outside world

Everything in this repo runs today without a single credential — the app falls back to local
heuristics, the web companion runs in demo mode. This is the list of what to connect to make
it real, in the order that unblocks the most.

Nothing here is optional-but-nice. If a section says the feature is dead without it, it is.

---

## 1. Apple Developer (blocks: running on a device at all)

| What | Value |
|---|---|
| App bundle ID | `com.sourcedai.yogi` |
| Share extension bundle ID | `com.sourcedai.yogi.share` |
| App Group | `group.com.sourcedai.yogi` |
| URL scheme | `yogi://` |

In the Apple Developer portal:

1. Register both bundle IDs.
2. Create the App Group `group.com.sourcedai.yogi` and enable it on **both** identifiers.
   If you only enable it on the app, the share extension writes into a container the app
   cannot read and shared links vanish with no error.
3. Enable **Sign in with Apple** on the app identifier.
4. In Xcode, set your team on both targets (Signing & Capabilities). `CODE_SIGN_STYLE` is
   already `Automatic`.

Changing the bundle prefix means changing it in four places: `project.yml`
(`PRODUCT_BUNDLE_IDENTIFIER` on both targets), `Yogi/Shared/ShareInbox.swift`
(`YogiAppGroup.identifier`), and the entitlements blocks in `project.yml`.

## 2. Supabase (blocks: sync, accounts, AI import, sharing)

1. Create a project. Copy the project URL and the **publishable/anon** key.
2. Put them in `ios/Yogi/Yogi/Resources/Yogi.local.xcconfig` (git-ignored, the parent
   `Yogi.xcconfig` `#include?`s it):

   ```
   SUPABASE_URL = https:/$()/YOUR-REF.supabase.co
   SUPABASE_ANON_KEY = sb_publishable_...
   ```

   The `$()` is not a typo — xcconfig treats a bare `//` as a comment.

3. Run the migrations in order (they create the schema, RLS policies, RPCs, the shared-plan
   read path, and the four storage buckets):

   ```
   supabase link --project-ref YOUR-REF
   supabase db push
   ```

4. Deploy the edge functions:

   ```
   supabase functions deploy extract ask-yogi reminders-cron
   ```

5. Set the function secrets:

   ```
   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
   ```

   `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected by the
   platform — do not set them yourself.

6. Enable **Apple** as an auth provider (Authentication → Providers) with the service ID and
   key from step 1.

Until this is done `ImportService` uses local heuristics: imports still produce saves, but
they are guessed from the URL rather than read.

## 3. Anthropic API key (blocks: real import and Ask Yogi)

Both `extract` and `ask-yogi` call Claude. Get a key at console.anthropic.com and set it as
the `ANTHROPIC_API_KEY` function secret above. This is the only thing standing between
"Yogi guessed this is an article" and "Yogi read the recipe and pulled the ingredients".

## 4. App Store Connect (blocks: subscriptions)

1. Create the app record for `com.sourcedai.yogi`.
2. Create a subscription group and an auto-renewing subscription with product ID
   `com.sourcedai.yogi.pro.yearly` — this exact string is in `PurchaseService.yearlyProductID`
   and in `Yogi/Resources/Yogi.storekit`.
3. Fill in the paid-apps agreement and banking, or StoreKit returns no products and the
   paywall shows an empty state.

Until then the run scheme uses the local `Yogi.storekit` file, so purchases work in the
simulator and do nothing real.

## 5. Reminders cron (optional: local reminders already work)

The app schedules local notifications itself, so reminders fire on-device with nothing
connected. The cron is a backstop for reinstalls and multi-device users:

```sql
select cron.schedule('yogi-reminders', '*/5 * * * *',
  $$ select net.http_post(
       url := 'https://YOUR-REF.supabase.co/functions/v1/reminders-cron',
       headers := '{"Authorization": "Bearer YOUR-SERVICE-ROLE-KEY"}'::jsonb) $$);
```

Actual push delivery needs an APNs key: set `APNS_KEY_ID`, `APNS_TEAM_ID`,
`APNS_PRIVATE_KEY` and `APNS_BUNDLE_ID` as function secrets. The delivery call itself is
still a stub in `reminders-cron/index.ts` — the notification row is written, the push is not
sent.

## 6. Web companion on Vercel (blocks: nothing in the app)

Import the repo with **root directory `web`**, then set:

| Variable | Where it comes from |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | publishable key |
| `SUPABASE_SECRET_KEY` | service role key, server-side only |

Without these the web app runs in demo mode: it renders and navigates, and writes return
`{ ok: true, demo: true }` instead of hitting the database.

---

## What is still a stub after all of this

Honest list, so nothing surprises you in review:

- **APNs push delivery** — the cron writes the notification row and marks the reminder sent,
  but never talks to Apple.
- **Contact sync** on Add Friends — the permission copy and UI are there, the sync is not.
- **QR scanning** — shows a toast; needs a camera session.
- **Home cities picker** in Edit Profile — toasts until there is a places backend.
- **Leaderboard numbers** — sample data, not a query.
