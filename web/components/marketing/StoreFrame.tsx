// One App Store screenshot at the 6.7" iPhone size Apple requires (1290x2796).
// Rendered in the browser and captured, so the type and UI are the real thing
// rather than a mockup drawn somewhere else.
export const FRAME_W = 1290;
export const FRAME_H = 2796;

export function StoreFrame({
  id,
  line1,
  line2,
  stickers = [],
  children,
}: {
  id: string;
  line1: string;
  line2?: string;
  stickers?: { emoji: string; top: number; left: number; size?: number; bg?: string }[];
  children: React.ReactNode;
}) {
  return (
    <div
      id={id}
      className="paper relative shrink-0 overflow-hidden"
      style={{ width: FRAME_W, height: FRAME_H }}
    >
      <div className="flex h-full flex-col items-center px-16 pt-[150px]">
        <h2
          className="text-center font-serif font-normal text-ink"
          style={{ fontSize: 96, lineHeight: 1.08, letterSpacing: "-0.015em" }}
        >
          {line1}
          {line2 && (
            <>
              <br />
              {line2}
            </>
          )}
        </h2>

        {/* device */}
        <div className="relative mt-[110px]">
          <div
            className="relative overflow-hidden border-ink bg-white"
            style={{ width: 880, height: 1800, borderWidth: 16, borderRadius: 84 }}
          >
            <div
              className="absolute left-1/2 z-20 -translate-x-1/2 rounded-pill bg-ink"
              style={{ top: 22, width: 250, height: 62 }}
            />
            <div className="h-full w-full overflow-hidden" style={{ paddingTop: 104 }}>
              {children}
            </div>
          </div>

          {stickers.map((s, i) => (
            <span
              key={i}
              className="absolute z-30 grid place-items-center rounded-full shadow-[0_10px_28px_rgba(60,45,25,0.22)]"
              style={{
                top: s.top,
                left: s.left,
                width: s.size ?? 128,
                height: s.size ?? 128,
                background: s.bg ?? "#fff",
                fontSize: (s.size ?? 128) * 0.52,
              }}
            >
              {s.emoji}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
