import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { JoinButton } from "@/components/JoinButton";
import { Mascot, Wordmark } from "@/components/Mascot";
import { SaveCover } from "@/components/SaveCard";
import { getCollectionByToken } from "@/lib/data";
import { CATEGORY, metaLine, tint } from "@/lib/types";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ token: string }> }): Promise<Metadata> {
  const { token } = await params;
  const data = await getCollectionByToken(token);
  return { title: data ? `${data.collection.name} · shared plan` : "Shared plan", description: data?.collection.details ?? "A plan shared from Yogi." };
}

/**
 * Public shared-plan page. No account needed to read it; joining puts it in your library.
 * This is the link that gets plans out of the group chat.
 */
export default async function SharedPlanPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params;
  const data = await getCollectionByToken(token);
  if (!data) notFound();
  const { collection: c, saves } = data;
  const places = saves.filter((s) => s.place);

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-2xl flex-col gap-6 px-4 pb-16 pt-6">
      <header className="flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2"><Mascot size={28} /><Wordmark className="text-[22px]" /></Link>
        <Link href="/login" className="text-[14px] font-semibold text-ink2">Sign in</Link>
      </header>
      <section className="card overflow-hidden">
        <div className="flex h-40 items-center justify-center text-[72px]" style={{ background: tint(c.cover_tint) }}>{c.cover_emoji}</div>
        <div className="p-5">
          <p className="text-[12px] font-semibold uppercase tracking-wide text-muted">Shared plan</p>
          <h1 className="balance mt-1 font-serif text-[30px] font-bold leading-tight">{c.name}</h1>
          {c.details && <p className="balance mt-2 text-[15px] leading-6 text-ink2">{c.details}</p>}
          <p className="mt-2 text-[13px] text-muted">{saves.length} {saves.length === 1 ? "item" : "items"}{places.length ? ` · ${places.length} ${places.length === 1 ? "place" : "places"}` : ""}</p>
          <div className="mt-5"><JoinButton token={token} name={c.name} /></div>
        </div>
      </section>
      <section className="flex flex-col gap-3">
        {saves.map((s) => (
          <div key={s.id} className="card flex items-center gap-3 p-3">
            <Link href={`/c/${token}/${s.id}`} className="flex min-w-0 flex-1 items-center gap-3">
              <SaveCover save={s} className="h-[72px] w-[72px] shrink-0 rounded-2xl [&_.cover-emoji]:text-[30px]" />
              <div className="min-w-0 flex-1">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-muted">{CATEGORY[s.category].emoji} {CATEGORY[s.category].title}</p>
                <p className="line-clamp-2 text-[16px] font-semibold leading-snug">{s.title}</p>
                <p className="line-clamp-1 text-[13px] text-ink2">{metaLine(s)}</p>
              </div>
            </Link>
            {s.place && (
              <a href={`https://www.google.com/maps/search/?api=1&query=${s.place.latitude},${s.place.longitude}`} target="_blank" rel="noreferrer" className="chip">Map</a>
            )}
          </div>
        ))}
      </section>
      <footer className="mt-auto flex flex-col items-center gap-2 pt-6 text-center">
        <Mascot size={40} variant="traveler" />
        <p className="balance text-[13px] text-muted">Saved with Yogi. Get the app to save from Instagram, TikTok and Safari.</p>
      </footer>
    </main>
  );
}
