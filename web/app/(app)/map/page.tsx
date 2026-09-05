import Link from "next/link";
import { getSaves } from "@/lib/data";
import { CATEGORY, metaLine } from "@/lib/types";

export const dynamic = "force-dynamic";

/** Map tab: every saved place, grouped by city, with an embedded map of them all. */
export default async function MapPage() {
  const saves = (await getSaves()).filter((s) => s.place || (s.event?.latitude && s.event?.longitude));
  const pts = saves.map((s) => ({ s, lat: s.place?.latitude ?? s.event!.latitude!, lng: s.place?.longitude ?? s.event!.longitude! }));
  const byCity = new Map<string, typeof pts>();
  for (const p of pts) {
    const key = p.s.place?.city ?? p.s.event?.venue ?? "Elsewhere";
    byCity.set(key, [...(byCity.get(key) ?? []), p]);
  }
  const bbox = pts.length
    ? [Math.min(...pts.map((p) => p.lng)) - 0.5, Math.min(...pts.map((p) => p.lat)) - 0.5, Math.max(...pts.map((p) => p.lng)) + 0.5, Math.max(...pts.map((p) => p.lat)) + 0.5].join(",")
    : "-20,20,40,60";

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-serif text-[32px] font-bold leading-tight">Map</h1>
      <iframe title="Saved places" loading="lazy" className="h-[260px] w-full rounded-card border border-hairline md:h-[360px]" src={`https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik${pts[0] ? `&marker=${pts[0].lat},${pts[0].lng}` : ""}`} />
      {pts.length === 0 && <p className="text-[14px] text-muted">Save a place or an event and it shows up here.</p>}
      {[...byCity.entries()].map(([city, list]) => (
        <section key={city}>
          <h2 className="mb-2 font-serif text-[22px] font-bold">{list[0].s.place?.countryFlag ?? "📍"} {city}</h2>
          <div className="flex flex-col divide-y divide-hairline">
            {list.map(({ s, lat, lng }) => (
              <div key={s.id} className="flex items-center gap-3 py-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-full bg-option text-[22px]">{s.cover_emoji ?? CATEGORY[s.category].emoji}</span>
                <Link href={`/saves/${s.id}`} className="min-w-0 flex-1">
                  <p className="truncate text-[16px] font-semibold">{s.title}</p>
                  <p className="truncate text-[13px] text-ink2">{metaLine(s)}</p>
                </Link>
                <a className="chip" href={`https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`} target="_blank" rel="noreferrer">Directions</a>
              </div>
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}
