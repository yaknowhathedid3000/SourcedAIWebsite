# Albo web

The desktop companion to the Albo iOS app. It gives the library a big screen, and it is how a plan leaves the group chat: every public collection gets a link (`/c/<token>`) anyone can open, and joining it drops the plan into their own library.

Built with Next.js 15 (App Router), React 19, Tailwind, and Supabase SSR auth. It shares the Postgres schema in `../supabase` with the iOS app, so a save made on the phone shows up here and a status change here syncs back.

## Run it

```bash
npm install
npm run dev        # http://localhost:3000
```

With no environment variables the site runs in **demo mode** on the same sample data as the iOS app (`lib/sample.ts`). Every page renders and every control works locally, nothing persists.

To connect the real backend, copy `.env.example` to `.env.local`:

```
NEXT_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<publishable key>
```

Then in the Supabase dashboard enable the Google and Apple providers and add `https://<your-domain>/auth/callback` (and `http://localhost:3000/auth/callback`) to the redirect allow-list. Sign-in on the web uses the same identity as the app, so a user who signed up with Apple on iOS signs in with Apple here and lands on the same library.

## Deploy

Vercel: import the repo, set the root directory to `web`, add the two environment variables. No other configuration is needed. Any host that runs `next build && next start` works the same way.

## Map

| Route | What it is |
| --- | --- |
| `/login` | The albo.inc sign-in: orbiting platform icons, Google / Apple / QR, and the "Set up your account on the Albo app" sheet with store badges |
| `/library` | Greeting, category chips, Recently saved, Collections |
| `/library/[category]` | All / Want to / Done tabs in the italic serif, list or grid |
| `/saves/[id]` | Item detail: hero, meta line, slide-to-confirm "Made it? / Visited?", recipe checklist with serving multiplier, place map and directions, event with add-to-calendar |
| `/collections/[id]` | Collection with the share link and native share sheet |
| `/c/[token]` | Public shared plan. No account needed to read, one tap to join |
| `/map` | Every saved place grouped by city with directions |
| `/community` | Journal feed |
| `/profile` | Profile card, stats, journal, sign out |
| `/add` | Paste a link (extracted by the `extract` edge function) or write a note |

Design tokens live in `tailwind.config.ts` and mirror `ios/Albo/Albo/DesignSystem`. Serif headings use Source Serif 4 as the web stand-in for New York; the sans is Instrument Sans standing in for SF Pro.

## Layout

- `app/` routes. `(app)/` is the signed-in shell with the permanent sidebar. `c/` is public.
- `components/` UI. Client components are the interactive ones: `StatusControl`, `Checklist`, `LoginPanel`, `AddForm`, `JoinButton`, `CopyButton`, `CategoryTabs`, `AppNav`.
- `lib/data.ts` server-only data access with the demo fallback. `app/actions.ts` server actions (status, join, create save, sign out).
- `middleware.ts` refreshes the Supabase session and redirects signed-out visitors to `/login`. Public paths: `/login`, `/auth`, `/c/`.
