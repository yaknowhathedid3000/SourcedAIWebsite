// Ask Albo: chat over the user's own library, globally or scoped to one save.
// Powers Albo #57 to #59 (global) and #93 to #95 (per item).
//
// POST /functions/v1/ask-albo   (user JWT in Authorization)
// { "question": "What is the top 1 best thing to do?", "save_id": "<uuid>|null",
//   "history": [{ "role": "user"|"assistant", "content": "..." }] }
//
// Response: { "answer": "..." }

import Anthropic from "npm:@anthropic-ai/sdk";
import { corsHeaders, json, requireUser } from "../_shared/supabase.ts";

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

const SYSTEM = `You are Albo, a friendly assistant inside a save-for-later app. You only know what the user has saved, which is provided as JSON. Answer briefly and concretely, in the user's own terms: recommend specific saves by title, quote ingredient quantities and steps when asked, give opening hours and addresses for places, and say plainly when the library does not contain the answer. Never invent saves. Keep answers under 120 words unless the user asks for a list.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { id: userId, client } = await requireUser(req);
    const { question, save_id: saveId, history = [] } = await req.json();
    if (typeof question !== "string" || !question.trim()) return json({ error: "empty_question" }, 400);

    // Pro / Max only (Albo #198: "Unlimited imports, AI chat & limited bulk import").
    const { data: profile } = await client.from("profiles").select("entitlement").eq("id", userId).single();
    if (!profile || profile.entitlement === "free") return json({ error: "pro_required", message: "AI chat is a Pro feature." }, 402);

    let context: unknown;
    if (saveId) {
      const { data } = await client.from("saves").select("id,category,title,subtitle,status,private_note,recipe,place,event,media,source_url").eq("id", saveId).single();
      context = data;
    } else {
      const { data } = await client.from("saves")
        .select("id,category,title,subtitle,status,private_note,source_platform,created_at,recipe->timeLabel,recipe->cuisine,place->category,place->city,place->hoursLabel,media->genre,media->tags")
        .eq("owner_id", userId).order("created_at", { ascending: false }).limit(200);
      context = data;
    }

    const messages: Anthropic.Beta.BetaMessageParam[] = [
      ...(history as Anthropic.Beta.BetaMessageParam[]).slice(-12),
      { role: "user", content: question },
    ];

    const response = await anthropic.beta.messages.create({
      model: "claude-opus-5",
      max_tokens: 2000,
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      thinking: { type: "adaptive" },
      output_config: { effort: "low" },
      system: [
        { type: "text", text: SYSTEM, cache_control: { type: "ephemeral" } },
        { type: "text", text: `The user's saved items as JSON:\n${JSON.stringify(context ?? [])}` },
      ],
      messages,
    });

    if (response.stop_reason === "refusal") {
      return json({ answer: "I can't help with that one, but ask me anything about your saves." });
    }
    const answer = response.content.filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text").map((b) => b.text).join("\n").trim();
    return json({ answer });
  } catch (err) {
    if (err instanceof Response) return err;
    console.error(err);
    const message = err instanceof Anthropic.APIError ? `claude ${err.status}: ${err.message}` : (err as Error).message;
    return json({ error: "ask_failed", message }, 500);
  }
});
