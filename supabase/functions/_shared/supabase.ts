import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

/** Client acting as the calling user, so RLS applies exactly as it does in the app. */
export function userClient(req: Request): SupabaseClient {
  const auth = req.headers.get("Authorization") ?? "";
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } }, auth: { persistSession: false } },
  );
}

/** Service-role client for work the user must not be able to do directly (ledger writes, storage reads). */
export function adminClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

export async function requireUser(req: Request): Promise<{ id: string; client: SupabaseClient }> {
  const client = userClient(req);
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) {
    throw new Response(JSON.stringify({ error: "unauthorized" }), { status: 401, headers: { ...corsHeaders, "content-type": "application/json" } });
  }
  return { id: data.user.id, client };
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "content-type": "application/json" } });
}

/** Strip a web page down to readable text so the model sees content, not markup. */
export async function fetchReadableText(url: string, maxChars = 60_000): Promise<{ text: string; title: string | null; image: string | null }> {
  const res = await fetch(url, {
    headers: { "user-agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) YogiBot/1.0", accept: "text/html,*/*" },
    redirect: "follow",
  });
  const html = await res.text();
  const title = html.match(/<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']/i)?.[1]
    ?? html.match(/<title[^>]*>([^<]+)<\/title>/i)?.[1] ?? null;
  const image = html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)?.[1] ?? null;
  // Recipe sites often embed schema.org JSON-LD; keep it, it is the best signal.
  const jsonLd = [...html.matchAll(/<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi)].map((m) => m[1]).join("\n");
  const text = html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ")
    .trim();
  const combined = (jsonLd ? `JSON-LD:\n${jsonLd}\n\nPAGE TEXT:\n` : "") + text;
  return { text: combined.slice(0, maxChars), title, image };
}
