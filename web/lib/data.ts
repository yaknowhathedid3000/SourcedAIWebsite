import "server-only";
import { serverClient } from "./supabase/server";
import { sampleCollectionSaves, sampleCollections, sampleProfile, sampleReviews, sampleSaves } from "./sample";
import type { Collection, Profile, Review, Save } from "./types";

/** Data access with a demo fallback so every page renders without a backend. */

export async function currentUser(): Promise<{ id: string; demo: boolean } | null> {
  const sb = await serverClient();
  if (!sb) return { id: sampleProfile.id, demo: true };
  const { data } = await sb.auth.getUser();
  return data.user ? { id: data.user.id, demo: false } : null;
}

export async function getProfile(userId?: string): Promise<Profile | null> {
  const sb = await serverClient();
  if (!sb) return sampleProfile;
  const id = userId ?? (await sb.auth.getUser()).data.user?.id;
  if (!id) return null;
  const { data } = await sb.from("profiles").select("*").eq("id", id).single();
  return (data as Profile) ?? null;
}

export async function getSaves(): Promise<Save[]> {
  const sb = await serverClient();
  if (!sb) return sampleSaves;
  const { data } = await sb.from("saves").select("*").order("created_at", { ascending: false });
  return (data as Save[]) ?? [];
}

export async function getSave(id: string): Promise<Save | null> {
  const sb = await serverClient();
  if (!sb) return sampleSaves.find((s) => s.id === id) ?? null;
  const { data } = await sb.from("saves").select("*").eq("id", id).single();
  return (data as Save) ?? null;
}

export async function getCollections(): Promise<Collection[]> {
  const sb = await serverClient();
  if (!sb) return sampleCollections;
  const { data } = await sb.from("collections").select("*").order("created_at", { ascending: false });
  return (data as Collection[]) ?? [];
}

export async function getCollection(id: string): Promise<{ collection: Collection; saves: Save[] } | null> {
  const sb = await serverClient();
  if (!sb) {
    const c = sampleCollections.find((x) => x.id === id);
    if (!c) return null;
    const ids = sampleCollectionSaves[id] ?? [];
    return { collection: c, saves: sampleSaves.filter((s) => ids.includes(s.id)) };
  }
  const { data: c } = await sb.from("collections").select("*").eq("id", id).single();
  if (!c) return null;
  const { data: links } = await sb.from("collection_saves").select("save_id").eq("collection_id", id);
  const ids = (links ?? []).map((l: { save_id: string }) => l.save_id);
  const { data: saves } = ids.length ? await sb.from("saves").select("*").in("id", ids) : { data: [] };
  return { collection: c as Collection, saves: (saves as Save[]) ?? [] };
}

export async function getCollectionByToken(token: string): Promise<{ collection: Collection; saves: Save[] } | null> {
  const sb = await serverClient();
  if (!sb) {
    const c = sampleCollections.find((x) => x.invite_token === token);
    return c ? getCollection(c.id) : null;
  }
  const { data: c } = await sb.from("collections").select("*").eq("invite_token", token).single();
  return c ? getCollection((c as Collection).id) : null;
}

export async function getReviews(): Promise<Review[]> {
  const sb = await serverClient();
  if (!sb) return sampleReviews;
  const { data } = await sb.from("reviews").select("*").order("created_at", { ascending: false });
  return (data as Review[]) ?? [];
}
