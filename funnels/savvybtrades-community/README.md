# The Payout Room — Savvy B Trades community funnel

Static, zero-build funnel for Brad Scholten's live trading community. Plain HTML, CSS, and
one small script. Deploys to Vercel (or any static host) as-is.

## Pages

| Path | What it is |
|---|---|
| `/` | The landing page: hero, ticker, what's inside, weekly schedule, membership, Brad's bio, FAQ, final CTA |
| `/checkout` | Step 1: opt-in form (first name, email, mobile, SMS consent). Posts to `/api/lead`, then sends people to `checkoutUrl` or `/thanks` |
| `/thanks` | Landing page after opt-in when no payment link is set yet. Also a good success URL for the payment provider |
| `/api/lead` | Vercel serverless function. Validates the form, normalises the phone to E.164, forwards everything to the GoHighLevel inbound webhook |
| `/palettes` | Internal: preview the four colour palettes on the live site |
| `/privacy` | Privacy policy, including the SMS consent clause |
| `/terms` | Terms of service |

## Going live: one env var and one file

**1. GoHighLevel webhook (the only required step).**
In GHL: Automation → Workflows → Create workflow → trigger **Inbound Webhook**. Copy the
webhook URL. In Vercel: Project → Settings → Environment Variables → add
`GHL_WEBHOOK_URL` = that URL (Production). Redeploy once so the function picks it up.

Send a test through the form, then in the GHL trigger click "Map reference" and map:

| Field sent | GHL contact field |
|---|---|
| `first_name`, `last_name` | First name, Last name |
| `email` | Email |
| `phone` | Phone (already E.164, e.g. `+15551234567`) |
| `tags` | Add tags: `payout-room`, `opt-in`, `trial-intent` |
| `source` | Contact source |
| `consent_sms`, `consent_text`, `consent_at` | Custom fields, keep for compliance |
| `utm_*`, `page_url`, `referrer` | Custom fields for attribution |

Then add the follow-up steps after the trigger: send SMS with the Discord invite, send
the welcome email, add to the trial nurture sequence. Until the env var is set, the form still
works and shows `/thanks`, but leads are only logged in the Vercel function logs, not forwarded.

**2. `config.js`** for everything else:

```js
checkoutUrl:   ""   // Step 2. GHL order form or Stripe Payment Link. Empty → /thanks.
videoEmbedUrl: ""   // Optional VSL embed. Replaces the hero chart when set.
instagramUrl:  "https://www.instagram.com/savvybtrades"
discordUrl:    ""   // Free Discord invite, once there is one.
metaPixelId:   ""   // Meta pixel. Fires PageView on every page and Lead on opt-in.
gtmId:         ""   // Google Tag Manager container. Lead pushed to dataLayer.
```

If `checkoutUrl` is a Stripe Payment Link, the email is prefilled automatically.

## Assets still needed from the client

- **Brad's photo.** Drop it at `assets/brad.jpg`, then in `index.html` replace the
  `.portrait-fallback` block with `<img src="assets/brad.jpg" alt="Brad Scholten">`.
- **Testimonials.** The copy promises public results. Once real quotes are supplied, they can be
  added as a section between the membership block and the bio. Nothing has been invented here.
- **OG image.** A 1200×630 share image at `assets/og.jpg`, then add
  `<meta property="og:image" content="/assets/og.jpg">` to each page's head.
- **Legal review.** Privacy and Terms are a sensible starting draft, not lawyer-reviewed.

## Deploying on Vercel

Live project: `savvybtrades-community` (https://savvybtrades-community.vercel.app).
Import the repo, set the **Root Directory** to `funnels/savvybtrades-community`, framework
preset **Other**, no build command. `vercel.json` turns on clean URLs. The `api/` folder is
picked up automatically as Node serverless functions.

## Local check

```
node -e "require('./api/lead.js')"   # syntax
```
The form can be exercised locally with any static server plus a stub for `/api/lead`; the
production function needs Node 18+ (global `fetch`).

## Design notes

- Type: Onest throughout, loaded from Google Fonts. Weights 400–800.
- Colour: four switchable palettes (violet default, royal, emerald, ember) defined at the top of
  `assets/styles.css`. Set `theme` in `config.js`, preview all four at `/palettes` or with
  `?theme=` on any page. Every accent-coloured element derives from `--accent-rgb`.
- Asset URLs carry `?v=N`. Bump N in all pages when CSS or JS changes so browsers refetch.
- The hero chart is drawn by `assets/site.js` from a fixed seed. It illustrates the key levels
  method (levels marked ahead, price reacting) and is labelled as an illustration, not data.
