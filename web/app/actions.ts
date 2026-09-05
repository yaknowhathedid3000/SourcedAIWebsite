"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { serverClient } from "@/lib/supabase/server";
import type { SaveCategory, SaveStatus } from "@/lib/types";

/** Persist a status change (Made it / Want to). No-op in demo mode. */
export async function setStatus(saveId: string, status: SaveStatus): Promise<{ ok: boolean; error?: string }> {
  const sb = await serverClient();
  if (!sb) return { ok: true };
  const { error } = await sb.from("saves").update({ status }).eq("id", saveId);
  if (error) return { ok: false, error: error.message };
  revalidatePath(`/saves/${saveId}`);
  revalidatePath("/library");
  return { ok: true };
}

/** Join a shared plan via its invite token (calls the join_collection RPC). */
export async function joinCollection(token: string): Promise<{ ok: boolean; id?: string; error?: string }> {
  const sb = await serverClient();
  if (!sb) return { ok: true, id: "demo" };
  const { data: user } = await sb.auth.getUser();
  if (!user.user) redirect(`/login?next=/c/${token}`);
  const { data, error } = await sb.rpc("join_collection", { p_token: token });
  if (error) return { ok: false, error: error.message };
  revalidatePath("/library");
  return { ok: true, id: data as string };
}

/** Create a save from a pasted link or a typed note. Uses the extract edge function when configured. */
export async function createSave(input: { url?: string; title?: string; category?: SaveCategory; note?: string }): Promise<{ ok: boolean; id?: string; error?: string }> {
  const sb = await serverClient();
  if (!sb) return { ok: true, id: "00000000-0000-0000-0000-000000000001" };
  const { data: user } = await sb.auth.getUser();
  if (!user.user) return { ok: false, error: "Sign in first" };

  let row: Record<string, unknown> = {
    owner_id: user.user.id,
    category: input.category ?? "note",
    title: (input.title ?? input.note ?? input.url ?? "Untitled").slice(0, 300),
    source_url: input.url ?? null,
    source_platform: input.url ? platformFor(input.url) : "note",
    note_body: input.note ?? null,
  };

  if (input.url) {
    const { data, error } = await sb.functions.invoke("extract", { body: { url: input.url } });
    if (!error && data && typeof data === "object") {
      const ex = data as { category?: SaveCategory; title?: string; subtitle?: string; cover_emoji?: string; cover_tint?: number; recipe?: unknown; place?: unknown; event?: unknown; media?: unknown };
      row = { ...row, ...Object.fromEntries(Object.entries(ex).filter(([, v]) => v !== undefined && v !== null)) };
    }
  }

  const { data, error } = await sb.from("saves").insert(row).select("id").single();
  if (error) return { ok: false, error: error.message };
  revalidatePath("/library");
  return { ok: true, id: (data as { id: string }).id };
}

export async function signOut() {
  const sb = await serverClient();
  if (sb) await sb.auth.signOut();
  redirect("/login");
}

function platformFor(url: string): string {
  const h = (() => { try { return new URL(url).hostname; } catch { return ""; } })();
  if (h.includes("instagram")) return "instagram";
  if (h.includes("tiktok")) return "tiktok";
  if (h.includes("youtu")) return "youtube";
  if (h.includes("pinterest")) return "pinterest";
  if (h.includes("threads")) return "threads";
  if (h === "x.com" || h.includes("twitter")) return "x";
  return "safari";
}
