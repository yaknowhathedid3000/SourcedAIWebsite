import { IngredientChecklist } from "./Checklist";
import type { Save } from "@/lib/types";

/** Category-specific body of an item (teardown chapter 7). Shared by the signed-in detail and the public plan item. */
export function SaveBody({ save }: { save: Save }) {
  if (save.recipe) {
    const r = save.recipe;
    return (
      <div className="flex flex-col gap-8">
        <IngredientChecklist ingredients={r.ingredients} yieldLabel={r.yieldLabel} />
        <section>
          <h2 className="mb-3 font-serif text-[22px] font-bold">Steps</h2>
          <ol className="flex flex-col gap-4">
            {r.steps.map((step, i) => (
              <li key={i} className="flex gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-option text-[18px]">{r.stepEmoji?.[i] ?? i + 1}</span>
                <p className="pt-1.5 text-[16px] leading-6">{step}</p>
              </li>
            ))}
          </ol>
        </section>
      </div>
    );
  }
  if (save.place) {
    const p = save.place;
    const q = encodeURIComponent(`${save.title} ${p.address ?? ""}`);
    const bbox = `${p.longitude - 0.01},${p.latitude - 0.006},${p.longitude + 0.01},${p.latitude + 0.006}`;
    return (
      <div className="flex flex-col gap-5">
        <iframe
          title="Map"
          className="h-[220px] w-full rounded-card border border-hairline bg-surface"
          loading="lazy"
          src={`https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${p.latitude},${p.longitude}`}
        />
        <div className="flex gap-2">
          <a className="btn-outline flex-1" href={`https://maps.apple.com/?q=${q}&ll=${p.latitude},${p.longitude}`} target="_blank" rel="noreferrer">Apple Maps</a>
          <a className="btn-outline flex-1" href={`https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}`} target="_blank" rel="noreferrer">Google Maps</a>
        </div>
        <dl className="divide-y divide-hairline rounded-card border border-hairline px-4">
          {p.address && <Row k="Address" v={p.address} />}
          {p.hoursLabel && <Row k="Hours" v={p.hoursLabel} />}
          {p.phone && <Row k="Phone" v={<a href={`tel:${p.phone}`} className="text-blue">{p.phone}</a>} />}
          {p.website && <Row k="Website" v={<a href={p.website} target="_blank" rel="noreferrer" className="text-blue">{p.website.replace(/^https?:\/\//, "")}</a>} />}
          {p.priceLevel && <Row k="Price" v={p.priceLevel} />}
        </dl>
        {p.about && <p className="text-[16px] leading-7 text-ink">{p.about}</p>}
      </div>
    );
  }
  if (save.event) {
    const e = save.event;
    const start = new Date(e.start);
    const stamp = start.toISOString().replace(/[-:]/g, "").replace(/\.\d+/, "");
    const ics = `data:text/calendar;charset=utf8,${encodeURIComponent(`BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:${save.title}\nDTSTART:${stamp}\nLOCATION:${e.venue}\nEND:VEVENT\nEND:VCALENDAR`)}`;
    return (
      <div className="flex flex-col gap-5">
        <div className="flex items-center gap-4 rounded-card border border-hairline p-4">
          <div className="flex h-16 w-16 flex-col items-center justify-center rounded-2xl bg-ink text-white">
            <span className="text-[11px] font-semibold uppercase">{start.toLocaleDateString("en-US", { month: "short" })}</span>
            <span className="text-[26px] font-bold leading-none">{start.getDate()}</span>
          </div>
          <div>
            <p className="text-[16px] font-semibold">{start.toLocaleDateString("en-US", { weekday: "long", day: "numeric", month: "long" })}</p>
            <p className="text-[14px] text-ink2">{e.venue}</p>
            {e.address && <p className="text-[13px] text-muted">{e.address}</p>}
          </div>
        </div>
        <a href={ics} download={`${save.title}.ics`} className="btn-outline">Add to calendar</a>
        {e.about && <p className="text-[16px] leading-7">{e.about}</p>}
        {e.organizer && <p className="text-[14px] text-muted">Organised by {e.organizer}</p>}
      </div>
    );
  }
  if (save.note_body) return <p className="whitespace-pre-wrap text-[16px] leading-7">{save.note_body}</p>;
  if (save.media) {
    const m = save.media;
    return (
      <dl className="divide-y divide-hairline rounded-card border border-hairline px-4">
        {m.author && <Row k="Author" v={m.author} />}
        {m.year && <Row k="Year" v={String(m.year)} />}
        {m.genre && <Row k="Genre" v={m.genre} />}
        {m.pages && <Row k="Pages" v={String(m.pages)} />}
        {m.runtimeLabel && <Row k="Runtime" v={m.runtimeLabel} />}
        {m.rating && <Row k="Rating" v={`★ ${m.rating.toFixed(1)}`} />}
      </dl>
    );
  }
  return save.subtitle ? <p className="text-[16px] leading-7 text-ink2">{save.subtitle}</p> : null;
}

function Row({ k, v }: { k: string; v: React.ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-4 py-3">
      <dt className="shrink-0 text-[14px] font-semibold text-muted">{k}</dt>
      <dd className="text-right text-[15px]">{v}</dd>
    </div>
  );
}
