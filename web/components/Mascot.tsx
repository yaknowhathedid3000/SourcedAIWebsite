// Albo's mascot: the black rounded "tooth" with two white eye slits (teardown 3.5).
// Costumes are drawn as a small emoji "hat" so the shape stays the brand asset.
const HAT: Record<string, string> = {
  plain: "", chef: "👨‍🍳", reader: "📚", news: "📰", king: "👑", max: "⭐️", traveler: "🧳", filmFan: "🎬", explorer: "🧭", coder: "💻", rocket: "🚀",
};

export function Mascot({ size = 56, variant = "plain", color = "#1C1C1E", className = "" }: { size?: number; variant?: string; color?: string; className?: string }) {
  const hat = HAT[variant] ?? "";
  return (
    <span className={`relative inline-block ${className}`} style={{ width: size, height: size }} aria-hidden>
      <svg viewBox="0 0 100 100" width={size} height={size}>
        <path
          d="M20 4 h60 a16 16 0 0 1 16 16 v58 c0 9 -8 14 -15 9 c-4 -3 -8 -3 -12 0 c-4 3 -8 3 -12 0 c-4 -3 -8 -3 -12 0 c-4 3 -8 3 -12 0 c-4 -3 -8 -3 -12 0 c-7 5 -17 0 -17 -9 v-58 a16 16 0 0 1 16 -16 z"
          fill={color}
        />
        <rect x="34" y="36" width="8" height="24" rx="4" fill="#fff" />
        <rect x="58" y="36" width="8" height="24" rx="4" fill="#fff" />
      </svg>
      {hat && (
        <span className="absolute -top-2 left-1/2 -translate-x-1/2 leading-none" style={{ fontSize: size * 0.42 }}>
          {hat}
        </span>
      )}
    </span>
  );
}

export function Wordmark({ className = "" }: { className?: string }) {
  return <span className={`font-serif font-bold tracking-tight ${className}`}>albo</span>;
}
