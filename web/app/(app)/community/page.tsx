import Link from "next/link";
import { Mascot } from "@/components/Mascot";
import { SaveCover } from "@/components/SaveCard";
import { getProfile, getReviews, getSaves } from "@/lib/data";
import { CATEGORY, SENTIMENT } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Community feed: journal entries from you and the people you follow (teardown chapter 9). */
export default async function CommunityPage() {
  const [profile, reviews, saves] = await Promise.all([getProfile(), getReviews(), getSaves()]);
  const byId = new Map(saves.map((s) => [s.id, s]));
  const posts = reviews.map((r) => ({ r, s: byId.get(r.save_id) })).filter((p) => p.s);

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-serif text-[32px] font-bold leading-tight">Community</h1>
      {posts.length === 0 ? (
        <div className="rounded-card bg-surface p-8 text-center">
          <Mascot size={56} className="mx-auto" variant="reader" />
          <p className="balance mt-3 text-[17px] font-semibold">Nothing in the feed yet</p>
          <p className="balance mt-1 text-[14px] text-ink2">Mark something as made, visited or watched and it shows up here for your friends.</p>
        </div>
      ) : (
        <div className="columns-1 gap-4 sm:columns-2">
          {posts.map(({ r, s }) => (
            <article key={r.id} className="card mb-4 break-inside-avoid overflow-hidden">
              <SaveCover save={s!} className="h-40 [&_.cover-emoji]:text-[56px]" />
              <div className="flex flex-col gap-2 p-4">
                <div className="flex items-center gap-2">
                  <Mascot size={22} variant={profile?.avatar_mascot} />
                  <span className="text-[13px] font-semibold">@{profile?.handle ?? "you"}</span>
                  <span className="text-[13px] text-muted">{CATEGORY[s!.category].journalVerb.toLowerCase()} this</span>
                </div>
                <Link href={`/saves/${s!.id}`} className="text-[16px] font-semibold leading-snug">{s!.title}</Link>
                <p className="text-[14px] text-ink2">{SENTIMENT[r.sentiment].emoji} {SENTIMENT[r.sentiment].title}{r.stars ? ` · ${"★".repeat(r.stars)}` : ""}</p>
                {r.title && <p className="font-serif text-[16px] italic">“{r.title}”</p>}
              </div>
            </article>
          ))}
        </div>
      )}
    </div>
  );
}
