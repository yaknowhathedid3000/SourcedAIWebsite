// A saved thing as a taped print. The photo is a warm mat with the subject on
// it, which is how the app renders covers too - emoji standing in for the 3D
// artwork - so the site and the product tell the same visual story.
export type Shot = {
  emoji: string;
  caption: string;
  from: string;
  to: string;
  rotate?: number;
  tape?: boolean;
};

export function Polaroid({
  shot,
  width = 200,
  className = "",
  style,
}: {
  shot: Shot;
  width?: number;
  className?: string;
  style?: React.CSSProperties;
}) {
  return (
    <figure
      className={`polaroid ${shot.tape ? "tape" : ""} ${className}`}
      style={{ width, rotate: `${shot.rotate ?? 0}deg`, ...style }}
    >
      <div
        className="polaroid-photo"
        style={{ background: `linear-gradient(155deg, ${shot.from}, ${shot.to})` }}
      >
        <span
          className="absolute inset-0"
          style={{ background: "linear-gradient(200deg, rgba(255,255,255,.42), transparent 58%)" }}
        />
        <span className="relative" style={{ fontSize: width * 0.42, lineHeight: 1 }}>
          {shot.emoji}
        </span>
      </div>
      <figcaption className="polaroid-caption">{shot.caption}</figcaption>
    </figure>
  );
}
