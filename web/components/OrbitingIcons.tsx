import { Mascot } from "./Mascot";

// The login hero from yogi.app/login: source-platform icons circling the mascot.
const INNER = [
  { label: "Instagram", emoji: "📸", bg: "#FDE7F3" },
  { label: "TikTok", emoji: "🎵", bg: "#E8F8FA" },
  { label: "YouTube", emoji: "▶️", bg: "#FDE8E8" },
  { label: "Pinterest", emoji: "📌", bg: "#FDE8EC" },
  { label: "Safari", emoji: "🧭", bg: "#E6F0FF" },
  { label: "Notes", emoji: "📝", bg: "#FFF6DA" },
];
const OUTER = [
  { label: "Threads", emoji: "🧵", bg: "#F1F1F1" },
  { label: "X", emoji: "✖️", bg: "#F1F1F1" },
  { label: "Podcasts", emoji: "🎧", bg: "#F3E8FF" },
  { label: "Maps", emoji: "🗺️", bg: "#E7F6EA" },
  { label: "Reddit", emoji: "👽", bg: "#FFEBDD" },
  { label: "Photos", emoji: "🖼️", bg: "#FFF1E6" },
  { label: "Spotify", emoji: "🎶", bg: "#E3F7EA" },
  { label: "Chrome", emoji: "🌐", bg: "#E6F0FF" },
];

function Ring({ items, radius, reverse }: { items: typeof INNER; radius: number; reverse?: boolean }) {
  const size = radius * 2 + 64;
  return (
    <div
      className={`absolute left-1/2 top-1/2 rounded-full border border-hairline/80 ${reverse ? "animate-orbitReverse" : "animate-orbit"} motion-reduce:animate-none`}
      style={{ width: size, height: size, marginLeft: -size / 2, marginTop: -size / 2 }}
    >
      {items.map((it, i) => {
        const angle = (i / items.length) * 360;
        return (
          <div
            key={it.label}
            className="absolute left-1/2 top-1/2"
            style={{ transform: `rotate(${angle}deg) translate(${radius}px) rotate(${-angle}deg)` }}
          >
            <div
              className={`-ml-7 -mt-7 flex h-14 w-14 items-center justify-center rounded-2xl text-[26px] shadow-card ${reverse ? "animate-orbit" : "animate-orbitReverse"} motion-reduce:animate-none`}
              style={{ background: it.bg }}
              title={it.label}
            >
              {it.emoji}
            </div>
          </div>
        );
      })}
    </div>
  );
}

export function OrbitingIcons() {
  return (
    <div className="relative mx-auto aspect-square w-[min(88vw,520px)]">
      <Ring items={OUTER} radius={228} reverse />
      <Ring items={INNER} radius={132} />
      <div className="absolute left-1/2 top-1/2 flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-2">
        <Mascot size={96} />
      </div>
    </div>
  );
}
