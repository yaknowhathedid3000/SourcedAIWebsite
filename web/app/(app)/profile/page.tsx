import Link from "next/link";
import { Mascot } from "@/components/Mascot";
import { SignOutButton } from "@/components/SignOutButton";
import { currentUser, getProfile, getReviews, getSaves } from "@/lib/data";
import { CATEGORY, SENTIMENT } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Profile: card, stats, journal (teardown chapter 10). */
export default async function ProfilePage() {
  const [user, profile, saves, reviews] = await Promise.all([currentUser(), getProfile(), getSaves(), getReviews()]);
  const byId = new Map(saves.map((s) => [s.id, s]));
  const done = saves.filter((s) => s.status === "done").length;

  return (
    <div className="flex flex-col gap-8">
      <header className="flex flex-col items-center gap-3 text-center">
        <Mascot size={88} variant={profile?.avatar_mascot} />
        <div>
          <h1 className="font-serif text-[30px] font-bold leading-tight">{profile?.name || "You"}</h1>
          <p className="text-[15px] text-ink2">@{profile?.handle ?? "albo"}{profile?.country ? ` · ${profile.country}` : ""}</p>
        </div>
        {profile?.bio && <p className="balance max-w-sm text-[15px] leading-6">{profile.bio}</p>}
        <div className="flex gap-2">
          <span className="chip">{profile?.entitlement === "free" ? "Free" : profile?.entitlement === "pro" ? "⭐️ Pro" : "👑 Max"}</span>
          <span className="chip">🔥 {profile?.streak_weeks ?? 0}-week streak</span>
          <span className="chip">🎟️ {profile?.credits ?? 0} credits</span>
        </div>
      </header>

      <section className="grid grid-cols-3 gap-3">
        {[["Saved", saves.length], ["Done", done], ["Journal", reviews.length]].map(([k, v]) => (
          <div key={k} className="card flex flex-col items-center py-4">
            <span className="font-serif text-[28px] font-bold tabular-nums">{v}</span>
            <span className="text-[12px] font-semibold uppercase tracking-wide text-muted">{k}</span>
          </div>
        ))}
      </section>

      <section>
        <h2 className="mb-3 font-serif text-[22px] font-bold">Journal</h2>
        <div className="flex flex-col gap-3">
          {reviews.map((r) => {
            const s = byId.get(r.save_id);
            if (!s) return null;
            return (
              <Link key={r.id} href={`/saves/${s.id}`} className="card flex items-center gap-3 p-3">
                <span className="text-[30px]">{s.cover_emoji ?? CATEGORY[s.category].emoji}</span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[15px] font-semibold">{CATEGORY[s.category].journalVerb} {s.title}</p>
                  <p className="text-[13px] text-ink2">{SENTIMENT[r.sentiment].emoji} {SENTIMENT[r.sentiment].title}{r.completed_on ? ` · ${new Date(r.completed_on).toLocaleDateString(undefined, { day: "numeric", month: "short" })}` : ""}</p>
                </div>
                {r.stars && <span className="text-[13px] text-star">{"★".repeat(r.stars)}</span>}
              </Link>
            );
          })}
          {reviews.length === 0 && <p className="text-[14px] text-muted">Your made, visited and watched moments collect here.</p>}
        </div>
      </section>

      <section className="flex flex-col gap-3">
        <p className="balance text-[13px] leading-5 text-muted">Account settings, subscription and appearance live in the Albo app on your phone.</p>
        {user && !user.demo ? <SignOutButton /> : <Link href="/login" className="btn-secondary">Sign in</Link>}
      </section>
    </div>
  );
}
