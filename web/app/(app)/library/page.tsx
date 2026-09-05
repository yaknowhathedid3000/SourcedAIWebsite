import Link from "next/link";
import { Mascot } from "@/components/Mascot";
import { SaveCard } from "@/components/SaveCard";
import { getCollections, getProfile, getSaves } from "@/lib/data";
import { BROWSABLE, CATEGORY, tint } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Library home: greeting, category chips, Recently saved, Collections (teardown 6.1, 6.2). */
export default async function LibraryPage() {
  const [profile, saves, collections] = await Promise.all([getProfile(), getSaves(), getCollections()]);
  const counts = new Map<string, number>();
  for (const s of saves) counts.set(s.category, (counts.get(s.category) ?? 0) + 1);
  const cats = BROWSABLE.filter((c) => (counts.get(c) ?? 0) > 0);

  return (
    <div className="flex flex-col gap-8">
      <header className="flex items-center justify-between">
        <div>
          <p className="text-[13px] font-semibold uppercase tracking-wide text-muted">Library</p>
          <h1 className="font-serif text-[32px] font-bold leading-tight">Hey {profile?.name || "there"} 👋</h1>
        </div>
        <Link href="/profile" aria-label="Profile"><Mascot size={40} variant={profile?.avatar_mascot} /></Link>
      </header>

      <section>
        <div className="-mx-4 flex gap-2 overflow-x-auto px-4 md:mx-0 md:flex-wrap md:px-0">
          {cats.map((c) => (
            <Link key={c} href={`/library/${c}`} className="chip h-10 whitespace-nowrap px-4 text-[15px]">
              {CATEGORY[c].emoji} {CATEGORY[c].plural} <span className="text-muted">{counts.get(c)}</span>
            </Link>
          ))}
          {cats.length === 0 && <p className="text-[14px] text-muted">Your categories appear here as you save.</p>}
        </div>
      </section>

      <section>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-serif text-[22px] font-bold">Recently saved</h2>
          <Link href="/add" className="text-[14px] font-semibold text-blue">Add +</Link>
        </div>
        {saves.length === 0 ? (
          <div className="rounded-card bg-surface p-8 text-center">
            <Mascot size={56} className="mx-auto" />
            <p className="balance mt-3 text-[17px] font-semibold">Nothing saved yet</p>
            <p className="balance mt-1 text-[14px] text-ink2">Paste a link from Instagram, TikTok or Safari and Albo files it for you.</p>
            <Link href="/add" className="btn-primary mx-auto mt-5 max-w-[240px]">Save something</Link>
          </div>
        ) : (
          <div className="-mx-4 flex gap-3 overflow-x-auto px-4 pb-2 md:mx-0 md:grid md:grid-cols-3 md:px-0 lg:grid-cols-4">
            {saves.slice(0, 12).map((s) => <SaveCard key={s.id} save={s} />)}
          </div>
        )}
      </section>

      <section>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-serif text-[22px] font-bold">Collections</h2>
          <span className="text-[13px] text-muted">Shared plans live here</span>
        </div>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {collections.map((c) => (
            <Link key={c.id} href={`/collections/${c.id}`} className="card flex items-center gap-4 p-3 transition active:scale-[0.99]">
              <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl text-[32px]" style={{ background: tint(c.cover_tint) }}>{c.cover_emoji}</div>
              <div className="min-w-0">
                <p className="truncate text-[17px] font-semibold">{c.name}</p>
                <p className="line-clamp-1 text-[13px] text-ink2">{c.details ?? (c.is_public ? "Shared · anyone with the link can join" : "Private")}</p>
              </div>
              <span className="ml-auto text-muted">›</span>
            </Link>
          ))}
          {collections.length === 0 && <p className="text-[14px] text-muted">Create a collection in the app to share a plan.</p>}
        </div>
      </section>
    </div>
  );
}
