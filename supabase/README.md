# Yogi backend (Supabase)

Postgres schema, row-level security, RPCs, storage buckets, and three edge
functions that back the iOS app in `ios/Yogi`.

## What is in here

| Path | Purpose | Yogi screens |
|---|---|---|
| `migrations/..._yogi_schema.sql` | Tables, enums, indexes, triggers, storage buckets, new-user bootstrap | teardown chapter 2 |
| `migrations/..._yogi_policies.sql` | Row-level security for every table and bucket | private accounts #176, blocks, friends-only reviews #83 |
| `migrations/..._yogi_functions.sql` | Seed tasks and stamps, RPCs (`submit_review`, `claim_task`, `join_collection`, `redeem_referral`, `spend_import_credit`, `request_account_deletion`, `search_saves`, `nearby_saves`, `common_saves`), views (`feed`, `leaderboard_hoarders`, `leaderboard_yappers`, `profile_stats`, `save_counts`), realtime | #78, #146, #196, #145 |
| `functions/extract` | Magic import: URL, note, or screenshots to typed saves via Claude with structured output | #25, #61, #68, #96 |
| `functions/ask-yogi` | Chat over the user's library, global or per item, Pro-gated | #57, #93 |
| `functions/reminders-cron` | Fires due reminders into `notifications` (and APNs when configured) | #92, #131 |

## Deploy

```bash
brew install supabase/tap/supabase
supabase login
supabase link --project-ref <your-project-ref>

# Schema, policies, functions, seed
supabase db push

# Secrets used by the edge functions
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
# SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are injected automatically.

# Edge functions
supabase functions deploy extract
supabase functions deploy ask-yogi
supabase functions deploy reminders-cron --no-verify-jwt
```

Then in the dashboard:

1. **Auth providers**: enable Apple (Services ID + key) and Google. The app signs in with `signInWithIdToken`, so redirect URLs are not needed for native sign-in.
2. **Cron**: enable the `pg_cron` and `pg_net` extensions and schedule `reminders-cron` every 5 minutes (the SQL is at the top of that function).
3. **Realtime**: already enabled for `saves`, `notifications`, `import_jobs` by the migration.

## Wire the app

Copy the project URL and the publishable (anon) key into
`ios/Yogi/Yogi/Resources/Yogi.xcconfig`:

```
SUPABASE_URL = https:/$()/<ref>.supabase.co
SUPABASE_ANON_KEY = sb_publishable_...
```

The `$()` in the URL is required: xcconfig treats `//` as a comment.

## Data model in one paragraph

`profiles` mirrors `auth.users`. `saves` is the polymorphic core row with
`recipe` / `place` / `event` / `media` as jsonb that decode straight into the
Swift structs; `latitude`, `longitude`, `event_start`, `canonical_key` and a
tsvector are maintained by trigger for the map, the events feed, "1165 saves"
counts and search. Collections are shared through `collection_members` and an
`invite_token` (join.yogi.app/<token>). Reviews carry sentiment, stars, photos,
tagged friends and a friends-only flag; `submit_review` is the single
transaction that marks a save done, stores the review, extends the streak and
advances the checklist. Credits meter free-tier imports in `credit_ledger`;
`spend_import_credit` is called by the extract function before every import.

## Local development

```bash
supabase start
supabase db reset          # applies migrations and seed
supabase functions serve   # runs edge functions with your local .env
```

Create `supabase/functions/.env` with `ANTHROPIC_API_KEY=...` for local runs.
