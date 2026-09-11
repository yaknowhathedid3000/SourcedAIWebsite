# The Payout Room — Savvy B Trades community funnel

Static, zero-build funnel for Brad Scholten's live trading community. Plain HTML, CSS, and
one small script. Deploys to Vercel (or any static host) as-is.

## Pages

| Path | What it is |
|---|---|
| `/` | The landing page: hero, ticker, what's inside, weekly schedule, membership, Brad's bio, FAQ, final CTA |
| `/checkout` | Demo checkpoint. Redirects to the live checkout the moment `checkoutUrl` is set |
| `/privacy` | Privacy policy |
| `/terms` | Terms of service |

## Going live: edit one file

Everything that changes between demo and live lives in `config.js`:

```js
checkoutUrl:   ""   // Skool / Whop / Stripe Payment Link. Every "Join" button follows it.
videoEmbedUrl: ""   // Optional VSL embed. Replaces the hero chart when set.
instagramUrl:  "https://www.instagram.com/savvybtrades"
discordUrl:    ""   // Free Discord invite, once there is one.
```

## Assets still needed from the client

- **Brad's photo.** Drop it at `assets/brad.jpg`, then in `index.html` replace the
  `.portrait-fallback` block with `<img src="assets/brad.jpg" alt="Brad Scholten">`.
- **Testimonials.** The copy promises public results. Once real quotes are supplied, they can be
  added as a section between the membership block and the bio. Nothing has been invented here.
- **OG image.** A 1200×630 share image at `assets/og.jpg`, then add
  `<meta property="og:image" content="/assets/og.jpg">` to each page's head.
- **Legal review.** Privacy and Terms are a sensible starting draft, not lawyer-reviewed.

## Deploying on Vercel

Import the repo, set the **Root Directory** to `funnels/savvybtrades-community`, framework
preset **Other**, no build command. `vercel.json` turns on clean URLs so `/checkout`,
`/privacy`, and `/terms` resolve without the trailing slash.

## Design notes

- Type: Archivo (display, set slightly extended), Instrument Sans (body), IBM Plex Mono (numbers,
  labels, tickers). Loaded from Google Fonts.
- Colour: ink-navy ground, brass accent (the colour of a payout). Chart green and red appear only
  in the chart, never as UI accent.
- The hero chart is drawn by `assets/site.js` from a fixed seed. It illustrates the key levels
  method (levels marked ahead, price reacting) and is labelled as an illustration, not data.
