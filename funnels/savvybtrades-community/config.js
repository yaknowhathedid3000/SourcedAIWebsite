// The Payout Room — site configuration.
// This file plus one Vercel environment variable is everything needed to go live.
window.PAYOUT_ROOM_CONFIG = {
  // Where people go AFTER the opt-in form. Paste the payment link
  // (GoHighLevel order form, Stripe Payment Link, etc.). While empty,
  // people land on /thanks after opting in.
  checkoutUrl: "",

  // Optional: a YouTube / Vimeo / Loom / Wistia embed URL. When set, the
  // hero shows the video instead of the key-levels chart.
  videoEmbedUrl: "",

  // Social + community links.
  instagramUrl: "https://www.instagram.com/savvybtrades",
  discordUrl: "",

  // Colour palette: "violet" | "royal" | "emerald" | "ember".
  // Preview all four at /palettes, or add ?theme=emerald to any page.
  theme: "violet",

  // Optional tracking. Leave empty to load nothing.
  metaPixelId: "",
  gtmId: "",
};

// Lead capture: the form on /checkout posts to /api/lead, which forwards to
// the GoHighLevel inbound webhook in the GHL_WEBHOOK_URL environment
// variable (set in the Vercel project, never here).
