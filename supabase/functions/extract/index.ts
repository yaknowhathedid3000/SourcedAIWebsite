// Yogi "magic import": a URL, a note, or up to nine screenshots in; typed saves out.
// Powers Albo #25 ("Importing... watching everything at 2x speed"), #61, #68, #96.
//
// POST /functions/v1/extract   (user JWT in Authorization)
// { "kind": "url", "url": "https://..." }
// { "kind": "note", "title": "Cookie recipes", "body": "- ## **Triple Chocolate Cookies**", "note_id": "<uuid>" }
// { "kind": "screenshots", "paths": ["<uid>/abc.jpg", ...] }   // objects in the `imports` bucket
//
// Response: { "saves": [ ...rows inserted into public.saves ] }

import Anthropic from "npm:@anthropic-ai/sdk";
import { zodOutputFormat } from "npm:@anthropic-ai/sdk/helpers/zod";
import { z } from "npm:zod";
import { adminClient, corsHeaders, fetchReadableText, json, requireUser } from "../_shared/supabase.ts";

const Ingredient = z.object({
  emoji: z.string().describe("One emoji that represents the ingredient"),
  name: z.string(),
  quantity: z.number().nullable(),
  unit: z.string().nullable(),
});

const Recipe = z.object({
  timeLabel: z.string().describe("Total time, e.g. '15 mins', '30 minutes', 'Multi-day project'"),
  cuisine: z.string().nullable(),
  course: z.string().nullable().describe("Dessert, Dinner, Side Dish, ..."),
  yieldLabel: z.string().nullable().describe("'Makes 12 cookies', 'Serves 4-6'"),
  ingredients: z.array(Ingredient),
  steps: z.array(z.string()),
  stepEmoji: z.array(z.string()).describe("One emoji per step, same length as steps"),
  emoji: z.string().describe("One emoji for the dish"),
});

const Place = z.object({
  latitude: z.number(),
  longitude: z.number(),
  category: z.string().describe("'Soba noodle shop', 'Association / Organization', 'Coffee shop'"),
  rating: z.number().nullable(),
  priceLevel: z.string().nullable().describe("'$', '$$', '$$$' or null"),
  hoursLabel: z.string().nullable(),
  phone: z.string().nullable(),
  website: z.string().nullable(),
  address: z.string().nullable(),
  neighborhood: z.string().nullable().describe("Uppercase neighbourhood label like 'LENOX HILL'"),
  city: z.string().nullable(),
  countryFlag: z.string().nullable().describe("Flag emoji of the country"),
  emoji: z.string(),
  photoEmoji: z.array(z.string()),
  about: z.string().nullable(),
});

const Event = z.object({
  start: z.string().describe("ISO 8601 date-time"),
  end: z.string().nullable(),
  venue: z.string(),
  address: z.string().nullable(),
  organizer: z.string().nullable(),
  kind: z.string().describe("'Community', 'Concert', 'Market', ..."),
  about: z.string().nullable(),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
});

const Media = z.object({
  year: z.number().nullable(),
  genre: z.string().nullable(),
  pages: z.number().nullable(),
  rating: z.number().nullable(),
  author: z.string().nullable(),
  runtimeLabel: z.string().nullable(),
  tags: z.array(z.string()).describe("For workouts: 'Bodyweight', 'Upper Body', ..."),
});

const Extracted = z.object({
  items: z.array(z.object({
    category: z.enum(["recipe", "place", "film", "book", "product", "workout", "software", "tvShow", "event", "article", "tutorial", "game"]),
    title: z.string(),
    subtitle: z.string().nullable(),
    coverEmoji: z.string().describe("One emoji standing in for the cover image"),
    coverTint: z.string().describe("Hex colour without #, a soft tint that suits the item, e.g. 'F7D9B0'"),
    recipe: Recipe.nullable(),
    place: Place.nullable(),
    event: Event.nullable(),
    media: Media.nullable(),
  })).describe("Every distinct thing worth saving. A travel video listing 12 restaurants yields 12 place items."),
});

const SYSTEM = `You are Albo's extraction engine. Yogi is a save-for-later app: people share a TikTok, Instagram post, web page, note, or screenshot and Yogi turns it into structured saves they can act on later.

Rules:
- Return every distinct actionable thing in the content: each restaurant, each recipe, each film, each product. A "12 best places in Tokyo" post returns 12 place items.
- Fill the details object that matches the category and leave the others null. Recipes always get ingredients with quantities and step-by-step instructions, one emoji per step. Places always get coordinates; estimate from the address or city when only a name is given and say so in 'about'.
- Titles are short and human: 'Triple Chocolate Cookies', 'New York City Bar', not the page's SEO title.
- Never invent ratings, prices, or phone numbers; use null when the content does not say.
- If the content contains nothing worth saving, return an empty items array.`;

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

async function extract(blocks: Anthropic.Beta.BetaContentBlockParam[]): Promise<z.infer<typeof Extracted>> {
  const response = await anthropic.beta.messages.create({
    model: "claude-opus-5",
    max_tokens: 16000,
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
    thinking: { type: "adaptive" },
    output_config: { effort: "medium", format: zodOutputFormat(Extracted) },
    system: [{ type: "text", text: SYSTEM, cache_control: { type: "ephemeral" } }],
    messages: [{ role: "user", content: blocks }],
  });

  if (response.stop_reason === "refusal") {
    throw new Error(`extraction refused: ${response.stop_details?.explanation ?? "no explanation"}`);
  }
  const text = response.content.find((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text")?.text ?? "";
  return Extracted.parse(JSON.parse(text));
}

function toRow(ownerId: string, item: z.infer<typeof Extracted>["items"][number], extra: Record<string, unknown>) {
  return {
    owner_id: ownerId,
    category: item.category,
    title: item.title,
    subtitle: item.subtitle,
    cover_emoji: item.coverEmoji,
    cover_tint: parseInt(item.coverTint.replace("#", ""), 16) || 0xEFEFEF,
    recipe: item.recipe,
    place: item.place,
    event: item.event,
    media: item.media,
    is_importing: false,
    ...extra,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { id: userId, client } = await requireUser(req);
    const body = await req.json();

    // Free tier is metered in credits; Pro and Max are unlimited (Albo #198).
    const { data: allowed, error: creditError } = await client.rpc("spend_import_credit");
    if (creditError) throw creditError;
    if (allowed === false) return json({ error: "out_of_credits", message: "You're out of imports. Start a free trial for unlimited saves." }, 402);

    const { data: job } = await client.from("import_jobs").insert({ owner_id: userId, kind: body.kind, payload: body, status: "running" }).select("id").single();

    let blocks: Anthropic.Beta.BetaContentBlockParam[] = [];
    let extra: Record<string, unknown> = {};

    if (body.kind === "url") {
      const url = new URL(body.url);
      const page = await fetchReadableText(url.toString());
      const host = url.hostname.toLowerCase();
      const platform = host.includes("tiktok") ? "tiktok" : host.includes("instagram") ? "instagram" : host.includes("youtu") ? "youtube" : host.includes("pinterest") ? "pinterest" : host.includes("facebook") ? "facebook" : "safari";
      extra = { source_url: url.toString(), source_platform: platform, cover_url: page.image };
      blocks = [{ type: "text", text: `Source URL: ${url}\nPage title: ${page.title ?? "unknown"}\n\n${page.text}` }];
    } else if (body.kind === "note") {
      extra = { source_platform: "note", mentioned_in_note_id: body.note_id ?? null };
      blocks = [{ type: "text", text: `Note title: ${body.title}\n\nNote body (markdown):\n${body.body}` }];
    } else if (body.kind === "screenshots") {
      extra = { source_platform: "screenshot" };
      const admin = adminClient();
      const paths: string[] = (body.paths ?? []).slice(0, 9);
      for (const path of paths) {
        if (!path.startsWith(`${userId}/`)) return json({ error: "forbidden_path" }, 403);
        const { data, error } = await admin.storage.from("imports").download(path);
        if (error || !data) throw error ?? new Error("download failed");
        const bytes = new Uint8Array(await data.arrayBuffer());
        let bin = "";
        for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
        const mediaType = path.toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg";
        blocks.push({ type: "image", source: { type: "base64", media_type: mediaType, data: btoa(bin) } });
      }
      blocks.push({ type: "text", text: "These are screenshots the user took: chats about plans, map lists, social posts, trading cards. Extract everything worth saving." });
    } else {
      return json({ error: "unknown_kind" }, 400);
    }

    const result = await extract(blocks);
    const rows = result.items.map((item) => toRow(userId, item, extra));
    let saves: unknown[] = [];
    if (rows.length > 0) {
      const { data, error } = await client.from("saves").insert(rows).select("*");
      if (error) throw error;
      saves = data ?? [];
    }

    if (job?.id) {
      await client.from("import_jobs").update({ status: "done", result_ids: (saves as { id: string }[]).map((s) => s.id), finished_at: new Date().toISOString() }).eq("id", job.id);
    }
    return json({ saves });
  } catch (err) {
    if (err instanceof Response) return err;
    console.error(err);
    const message = err instanceof Anthropic.APIError ? `claude ${err.status}: ${err.message}` : (err as Error).message;
    return json({ error: "extract_failed", message }, 500);
  }
});
