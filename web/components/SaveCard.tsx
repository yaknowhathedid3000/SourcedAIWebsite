import Link from "next/link";
import { CATEGORY, metaLine, tint, type Save } from "@/lib/types";

const PLATFORM: Record<string, string> = { instagram: "📸", tiktok: "🎵", youtube: "▶️", pinterest: "📌", safari: "🧭", note: "📝", manual: "✍️", screenshot: "🖼️", threads: "🧵", x: "✖️" };

export function SaveCover({ save, className = "" }: { save: Save; className?: string }) {
  return (
    <div className={`relative flex items-center justify-center overflow-hidden ${className}`} style={{ background: tint(save.cover_tint) }}>
      {save.cover_url ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={save.cover_url} alt="" className="absolute inset-0 h-full w-full object-cover" />
      ) : (
        <span className="cover-emoji text-[44px] drop-shadow-sm">{save.cover_emoji ?? CATEGORY[save.category].emoji}</span>
      )}
      {save.status === "done" && (
        <span className="absolute right-2 top-2 flex h-6 w-6 items-center justify-center rounded-full bg-white text-[13px] shadow-card" title={CATEGORY[save.category].doneTab}>✅</span>
      )}
    </div>
  );
}

/** Library "Recently saved" tile (teardown 6.2). */
export function SaveCard({ save }: { save: Save }) {
  return (
    <Link href={`/saves/${save.id}`} className="card group flex flex-col overflow-hidden transition hover:-translate-y-0.5 hover:shadow-[0_10px_24px_rgba(0,0,0,0.08)] active:scale-[0.98]">
      <SaveCover save={save} className="h-[150px]" />
      <div className="flex flex-col gap-0.5 p-3">
        <span className="text-[11px] font-semibold uppercase tracking-wide text-muted">{CATEGORY[save.category].emoji} {CATEGORY[save.category].title}</span>
        <span className="line-clamp-2 text-[15px] font-semibold leading-tight text-ink">{save.title}</span>
        <span className="line-clamp-1 text-[12px] text-ink2">{metaLine(save)}</span>
      </div>
    </Link>
  );
}

/** Category list row (teardown 6.4). */
export function SaveRow({ save }: { save: Save }) {
  return (
    <Link href={`/saves/${save.id}`} className="flex items-center gap-3 rounded-2xl px-2 py-2 transition hover:bg-surface active:bg-option">
      <SaveCover save={save} className="h-[76px] w-[76px] shrink-0 rounded-2xl [&_.cover-emoji]:text-[32px]" />
      <div className="min-w-0 flex-1">
        <p className="line-clamp-2 text-[16px] font-semibold leading-snug text-ink">{save.title}</p>
        <p className="line-clamp-1 text-[13px] text-ink2">{metaLine(save)}</p>
        <p className="mt-0.5 text-[12px] text-muted">{PLATFORM[save.source_platform] ?? "🔗"} {save.source_platform}</p>
      </div>
      <span className="text-muted">›</span>
    </Link>
  );
}
