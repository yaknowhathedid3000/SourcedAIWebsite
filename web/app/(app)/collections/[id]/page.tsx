import Link from "next/link";
import { notFound } from "next/navigation";
import { headers } from "next/headers";
import { CopyButton, ShareButton } from "@/components/CopyButton";
import { SaveRow } from "@/components/SaveCard";
import { getCollection } from "@/lib/data";
import { tint } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Collection detail with the share link that turns a group-chat idea into a plan. */
export default async function CollectionPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const data = await getCollection(id);
  if (!data) notFound();
  const { collection: c, saves } = data;
  const h = await headers();
  const origin = `${h.get("x-forwarded-proto") ?? "https"}://${h.get("x-forwarded-host") ?? h.get("host") ?? "localhost:3000"}`;
  const shareUrl = c.is_public && c.invite_token ? `${origin}/c/${c.invite_token}` : null;

  return (
    <div className="flex flex-col gap-6">
      <Link href="/library" className="text-[14px] font-semibold text-ink2">‹ Library</Link>
      <header className="flex items-center gap-4">
        <div className="flex h-20 w-20 items-center justify-center rounded-card text-[40px]" style={{ background: tint(c.cover_tint) }}>{c.cover_emoji}</div>
        <div>
          <h1 className="balance font-serif text-[30px] font-bold leading-tight">{c.name}</h1>
          <p className="text-[14px] text-ink2">{saves.length} {saves.length === 1 ? "item" : "items"}{c.is_public ? " · shared" : " · private"}</p>
        </div>
      </header>
      {shareUrl ? (
        <div className="card flex flex-col gap-3 p-4">
          <p className="balance text-[15px] font-semibold">Send this to the group chat</p>
          <p className="break-all rounded-xl bg-surface px-3 py-2 text-[13px] text-ink2">{shareUrl}</p>
          <div className="flex gap-2">
            <ShareButton title={c.name} url={shareUrl} className="btn-primary h-12 flex-1 text-[16px]" />
            <CopyButton text={shareUrl} className="btn-outline h-12 flex-1" />
          </div>
        </div>
      ) : (
        <p className="rounded-2xl bg-surface p-4 text-[14px] leading-5 text-ink2">This collection is private. Turn on sharing in the Albo app and a link for the group chat appears here.</p>
      )}
      {c.details && <p className="text-[16px] leading-7 text-ink2">{c.details}</p>}
      <section className="flex flex-col">
        {saves.map((s) => <SaveRow key={s.id} save={s} />)}
        {saves.length === 0 && <p className="text-[14px] text-muted">Nothing in this collection yet.</p>}
      </section>
    </div>
  );
}
