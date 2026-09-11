// POST /api/lead
// Receives the opt-in form, normalises it, and forwards it to the
// GoHighLevel inbound webhook set in the GHL_WEBHOOK_URL environment
// variable. Nothing secret ever reaches the browser.
//
// GHL setup: Automation -> Workflows -> new workflow -> trigger
// "Inbound Webhook" -> copy the URL into Vercel as GHL_WEBHOOK_URL.
// Map first_name, last_name, email, phone, tags, source in the trigger.

const MAX_LEN = 200;

function clean(v) {
  return String(v || "").trim().slice(0, MAX_LEN);
}

function normalisePhone(raw) {
  const s = clean(raw);
  if (!s) return "";
  if (s.startsWith("+")) return "+" + s.slice(1).replace(/\D/g, "");
  const d = s.replace(/\D/g, "");
  if (d.length === 10) return "+1" + d;
  if (d.length === 11 && d.startsWith("1")) return "+" + d;
  return d.length >= 8 ? "+" + d : "";
}

function validEmail(e) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(e);
}

module.exports = async function handler(req, res) {
  res.setHeader("Cache-Control", "no-store");

  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ ok: false, error: "Method not allowed" });
  }

  let body = req.body;
  if (typeof body === "string") {
    try { body = JSON.parse(body); } catch { body = {}; }
  }
  body = body || {};

  // Honeypot: real people never fill this in.
  if (clean(body.website)) {
    return res.status(200).json({ ok: true });
  }

  const firstName = clean(body.first_name);
  const lastName = clean(body.last_name);
  const email = clean(body.email).toLowerCase();
  const phone = normalisePhone(body.phone);
  const consent = body.consent_sms === true || body.consent_sms === "true" || body.consent_sms === "on";

  if (!firstName) return res.status(400).json({ ok: false, error: "Add your first name." });
  if (!validEmail(email)) return res.status(400).json({ ok: false, error: "That email doesn't look right." });
  if (!phone) return res.status(400).json({ ok: false, error: "Add a mobile number so we can text your access link." });
  if (!consent) return res.status(400).json({ ok: false, error: "Tick the box so we're allowed to text you." });

  const payload = {
    first_name: firstName,
    last_name: lastName,
    full_name: [firstName, lastName].filter(Boolean).join(" "),
    email,
    phone,
    source: "The Payout Room funnel",
    tags: ["payout-room", "opt-in", "trial-intent"],
    consent_sms: true,
    consent_text: clean(body.consent_text),
    consent_at: new Date().toISOString(),
    page_url: clean(body.page_url),
    referrer: clean(body.referrer),
    utm_source: clean(body.utm_source),
    utm_medium: clean(body.utm_medium),
    utm_campaign: clean(body.utm_campaign),
    utm_content: clean(body.utm_content),
    utm_term: clean(body.utm_term),
    ip: clean((req.headers["x-forwarded-for"] || "").split(",")[0]),
    user_agent: clean(req.headers["user-agent"]),
  };

  const url = process.env.GHL_WEBHOOK_URL;
  if (!url) {
    // Not activated yet. Accept the lead so the funnel keeps working,
    // and say so in the response for anyone debugging.
    console.warn("GHL_WEBHOOK_URL is not set; lead not forwarded:", payload.email);
    return res.status(200).json({ ok: true, forwarded: false });
  }

  try {
    const r = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!r.ok) {
      console.error("GHL webhook responded", r.status, await r.text().catch(() => ""));
      return res.status(502).json({ ok: false, error: "Couldn't save your details. Try again in a moment." });
    }
    return res.status(200).json({ ok: true, forwarded: true });
  } catch (err) {
    console.error("GHL webhook failed", err);
    return res.status(502).json({ ok: false, error: "Couldn't save your details. Try again in a moment." });
  }
};
