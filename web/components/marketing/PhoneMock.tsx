import { Mascot } from "@/components/Mascot";

// A miniature of the iOS library screen, built from the same tokens as the app
// so the hero shows the real thing rather than a stock mockup.
const SAVES = [
  { emoji: "🍲", tint: "#F7D9B0", title: "Miso butter pasta", meta: "25 mins · Italian", tilt: "-2.5deg" },
  { emoji: "🗺️", tint: "#DDF0E2", title: "Bar Termini", meta: "Soho · Cocktail bar", tilt: "1.8deg" },
  { emoji: "📚", tint: "#E4E1FA", title: "Project Hail Mary", meta: "Andy Weir", tilt: "-1.2deg" },
];

function Glyph({ d, active = false }: { d: string; active?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" width="19" height="19" fill="none" aria-hidden>
      <path
        d={d}
        stroke="#1C1C1E"
        strokeOpacity={active ? 1 : 0.35}
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function PhoneMock() {
  return (
    <div className="relative mx-auto w-[300px] shrink-0 sm:w-[330px]">
      {/* device */}
      <div className="relative rounded-[46px] border-[10px] border-ink bg-white shadow-[0_28px_60px_rgba(0,0,0,0.18)]">
        <div className="absolute left-1/2 top-2 h-[22px] w-[92px] -translate-x-1/2 rounded-pill bg-ink" />
        <div className="overflow-hidden rounded-[36px] px-4 pb-3 pt-9">
          <div className="flex items-center justify-between pb-3">
            <span className="font-serif text-[26px] font-bold tracking-tight">Library</span>
            <Mascot size={26} />
          </div>

          <div className="flex items-baseline gap-4 border-b border-hairline pb-2">
            <span className="tab-serif-active text-[17px]">All</span>
            <span className="tab-serif text-[17px]">Recipes</span>
            <span className="tab-serif text-[17px]">Places</span>
          </div>

          <div className="space-y-2.5 pt-3">
            {SAVES.map((s) => (
              <div key={s.title} className="flex items-center gap-3 rounded-[14px] bg-white p-2 shadow-card">
                {/* polaroid */}
                <div
                  className="grid h-[54px] w-[42px] shrink-0 place-items-center rounded-[4px] border-[3px] border-white bg-option shadow-card"
                  style={{ background: s.tint, transform: `rotate(${s.tilt})` }}
                >
                  <span className="text-[20px] leading-none">{s.emoji}</span>
                </div>
                <div className="min-w-0">
                  <p className="truncate text-[14px] font-semibold leading-tight">{s.title}</p>
                  <p className="truncate text-[12px] text-muted">{s.meta}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-3 rounded-[14px] bg-surface p-3">
            <p className="text-[12px] font-semibold text-ink2">Ask Yogi</p>
            <p className="mt-0.5 text-[13px] leading-snug text-muted">
              &ldquo;What was that pasta I saved last week?&rdquo;
            </p>
          </div>

          {/* Tab bar: monochrome strokes, matching the SF Symbols the app uses. */}
          <div className="mt-3 flex items-center justify-between px-4 pb-1 pt-2">
            <Glyph d="M3 10.2 12 3l9 7.2V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" active />
            <Glyph d="M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM3.6 9h16.8M3.6 15h16.8M12 3a14 14 0 0 1 0 18 14 14 0 0 1 0-18z" />
            <span className="grid h-8 w-8 place-items-center rounded-full bg-ink text-[16px] font-medium leading-none text-white">
              +
            </span>
            <Glyph d="M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2.5 20a6.5 6.5 0 0 1 13 0M16 11.5a3 3 0 1 0 0-6M17 14.6a5.5 5.5 0 0 1 4.5 5.4" />
            <span className="h-[18px] w-[18px] rounded-full border-[1.6px] border-ink/35 bg-option" />
          </div>
        </div>
      </div>
    </div>
  );
}
