import type { Metadata } from "next";
import Link from "next/link";
import { Mascot, Wordmark } from "@/components/Mascot";
import { Polaroid, type Shot } from "@/components/marketing/Polaroid";

export const metadata: Metadata = {
  title: { absolute: "Yogi — save it, then actually do it" },
  description:
    "Yogi catches the recipes, places, films and links you save across TikTok, Instagram and Safari, reads them properly, and hands them back when you can use them.",
};

const HERO: Shot[] = [
  { emoji: "🍝", caption: "miso butter pasta", from: "#F6C99A", to: "#E9A15E", rotate: -6, tape: true },
  { emoji: "🍸", caption: "Bar Termini, Soho", from: "#BFD9C4", to: "#8FBFA0", rotate: 4.5, tape: true },
  { emoji: "📖", caption: "Project Hail Mary", from: "#CFC9F2", to: "#A79EE0", rotate: -3, tape: true },
  { emoji: "🏝️", caption: "3 days in Lisbon", from: "#F8C6D6", to: "#E894B4", rotate: 7, tape: true },
  { emoji: "🎬", caption: "Past Lives", from: "#C6E6EB", to: "#93C6D4", rotate: -4, tape: true },
];

const STEPS = [
  {
    n: "One",
    title: "Send it to Yogi",
    body: "Hit share in TikTok, Instagram, Safari or Photos and pick Yogi. No forms. No fifty open tabs.",
    shot: { emoji: "📲", caption: "one tap", from: "#F6D5A8", to: "#EDB877" } as Shot,
  },
  {
    n: "Two",
    title: "It reads the whole thing",
    body: "Watches the video, reads the page, pulls the ingredients, the address, the runtime, the author.",
    shot: { emoji: "🔍", caption: "every word", from: "#C7DDF7", to: "#96BDEB" } as Shot,
  },
  {
    n: "Three",
    title: "You actually do it",
    body: "Cook it, go there, watch it. Slide to confirm, add a line about how it went, and it lands in your journal.",
    shot: { emoji: "✅", caption: "made it", from: "#C4E4C9", to: "#93CBA1" } as Shot,
  },
];

const BOARD: Shot[] = [
  { emoji: "🍲", caption: "Recipes", from: "#F6C99A", to: "#EFB077", rotate: -4 },
  { emoji: "🗺️", caption: "Places", from: "#BFD9C4", to: "#96C5A6", rotate: 3 },
  { emoji: "📼", caption: "Films", from: "#CFC9F2", to: "#ADA3E4", rotate: -2.5 },
  { emoji: "📚", caption: "Books", from: "#F8C6D6", to: "#EE9CBB", rotate: 5 },
  { emoji: "🧺", caption: "Products", from: "#F7D8BE", to: "#EFBE96", rotate: -5.5 },
  { emoji: "🏋️", caption: "Workouts", from: "#C7DDF7", to: "#9EC4EE", rotate: 2 },
  { emoji: "🎟️", caption: "Events", from: "#FBE3A8", to: "#F3CE74", rotate: -3 },
  { emoji: "📰", caption: "Articles", from: "#C6E6EB", to: "#96CDD6", rotate: 4 },
];

const FEATURES = [
  {
    title: "Ask it like a person",
    body: "“What was that pasta I saved last week?” It answers out of your own library, not the internet's.",
    span: true,
    shot: { emoji: "💬", caption: "ask yogi", from: "#F6C99A", to: "#E9A15E", rotate: -3, tape: true } as Shot,
  },
  { title: "Your places, pinned", body: "Every bar and restaurant you saved on a map, with a nudge when you are standing near one." },
  { title: "Reminders that land", body: "Set it for Saturday morning. It comes back Saturday morning, not never." },
  { title: "A journal, not a graveyard", body: "Rate what you tried, keep the photo. What you did is worth more than what you saved." },
  { title: "Lists you can send", body: "Build a list of places for a trip, share one link, let people add to it." },
];

export default function Home() {
  return (
    <main className="paper grain relative overflow-hidden">
      {/* ---------- nav ---------- */}
      <header className="relative z-10 mx-auto flex max-w-[1180px] items-center justify-between px-5 py-6 sm:px-8">
        <div className="flex items-center gap-2">
          <Mascot size={32} />
          <Wordmark className="text-[26px]" />
        </div>
        <Link href="/library" className="btn-outline bg-white/60 backdrop-blur">
          Open the web app
        </Link>
      </header>

      {/* ---------- hero ---------- */}
      <section className="relative z-10 mx-auto max-w-[1180px] px-5 pb-20 pt-4 sm:px-8 sm:pb-24 sm:pt-8">
        <p className="font-serif text-[19px] italic text-ink2">Everything you meant to get round to —</p>
        <h1 className="balance mt-3 max-w-[14ch] font-serif text-[clamp(3.1rem,8vw,6rem)] font-bold leading-[0.93] tracking-[-0.03em]">
          Save it. Then <em className="not-italic text-brand">actually</em> do it.
        </h1>

        <p className="mt-6 max-w-[40ch] text-[19px] leading-8 text-ink2">
          You have four hundred recipes saved and you have cooked six of them. Yogi catches
          everything you send it, reads it properly, and hands it back at the moment it is useful.
        </p>
        <div className="mt-8 flex flex-wrap items-center gap-4">
          <Link href="/library" className="btn-pill-lg">
            Open the web app
          </Link>
          <Link href="#how" className="btn-ghost-lg">
            How it works
          </Link>
        </div>
        <p className="mt-4 flex items-center gap-2 font-serif text-[16px] italic text-ink2">
          <Mascot size={20} /> Coming to iPhone. Free while we are in beta.
        </p>

        {/* Prints laid out along the desk. Staggered, never overlapping, so every
            caption stays readable. Scrolls sideways when the row runs out of room. */}
        <div className="-mx-5 mt-12 flex gap-7 overflow-x-auto px-5 pb-6 pt-5 sm:-mx-8 sm:px-8 lg:mt-14 lg:justify-between lg:gap-4 lg:overflow-visible">
          {HERO.map((s, i) => (
            <Polaroid
              key={s.caption}
              shot={s}
              width={192}
              className="shrink-0"
              style={{ marginTop: [26, 0, 40, 12, 32][i] }}
            />
          ))}
        </div>
      </section>

      {/* ---------- the line ---------- */}
      <section className="relative z-10 bg-ink py-20 text-white sm:py-28">
        <div className="mx-auto max-w-[1180px] px-5 sm:px-8">
          <p className="balance max-w-[20ch] font-serif text-[clamp(2.2rem,5.5vw,4rem)] font-bold leading-[1.02] tracking-[-0.02em]">
            A saved folder is not a plan. It is a pile.
          </p>
          <p className="mt-6 max-w-[48ch] text-[18px] leading-8 text-white/70">
            Bookmarks, screenshots, links in your own DMs, a note called <em className="font-serif italic">stuff</em>.
            Yogi is the part that comes after saving.
          </p>
        </div>
      </section>

      {/* ---------- how ---------- */}
      <section id="how" className="relative z-10 scroll-mt-6 py-24 sm:py-32">
        <div className="mx-auto max-w-[1180px] px-5 sm:px-8">
          <h2 className="balance max-w-[16ch] font-serif text-[clamp(2.2rem,5vw,3.6rem)] font-bold leading-[1.02] tracking-[-0.025em]">
            Three taps from seeing it to having it.
          </h2>
          <div className="mt-16 grid gap-14 sm:grid-cols-3 sm:gap-10">
            {STEPS.map((s, i) => (
              <div key={s.n} className="flex flex-col items-start">
                <Polaroid shot={{ ...s.shot, rotate: [-4, 3, -2][i] }} width={150} />
                <p className="mt-8 font-serif text-[17px] italic text-brand">{s.n}</p>
                <h3 className="mt-1 font-serif text-[26px] font-bold leading-tight tracking-tight">{s.title}</h3>
                <p className="mt-2.5 text-[17px] leading-7 text-ink2">{s.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ---------- the board ---------- */}
      <section className="relative z-10 border-y border-ink/10 bg-white/45 py-24 sm:py-32">
        <div className="mx-auto max-w-[1180px] px-5 sm:px-8">
          <div className="max-w-[52ch]">
            <h2 className="balance font-serif text-[clamp(2.2rem,5vw,3.6rem)] font-bold leading-[1.02] tracking-[-0.025em]">
              It already knows what you sent it.
            </h2>
            <p className="mt-5 text-[18px] leading-8 text-ink2">
              A recipe arrives with its ingredients and method. A restaurant with its address and
              opening hours. A book with its author. You never pick a folder, because it picked one.
            </p>
          </div>
          <div className="mx-auto mt-16 flex max-w-[300px] flex-wrap justify-center gap-x-6 gap-y-10 sm:max-w-[680px] sm:gap-x-9">
            {BOARD.map((s, i) => (
              <Polaroid
                key={s.caption}
                shot={s}
                width={140}
                style={{ marginTop: [0, 26, 6, 34, 12, 30, 0, 22][i] }}
              />
            ))}
          </div>
        </div>
      </section>

      {/* ---------- features ---------- */}
      <section className="relative z-10 py-24 sm:py-32">
        <div className="mx-auto max-w-[1180px] px-5 sm:px-8">
          <h2 className="balance max-w-[16ch] font-serif text-[clamp(2.2rem,5vw,3.6rem)] font-bold leading-[1.02] tracking-[-0.025em]">
            Everything after the save.
          </h2>
          <div className="mt-14 grid gap-x-12 gap-y-12 sm:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((f) =>
              f.span ? (
                <div key={f.title} className="flex flex-col gap-6 sm:col-span-2 sm:flex-row sm:items-center lg:col-span-1 lg:flex-col lg:items-start">
                  {f.shot && <Polaroid shot={f.shot} width={168} className="shrink-0" />}
                  <div>
                    <h3 className="font-serif text-[26px] font-bold leading-tight tracking-tight">{f.title}</h3>
                    <p className="mt-2.5 max-w-[42ch] text-[17px] leading-7 text-ink2">{f.body}</p>
                  </div>
                </div>
              ) : (
                <div key={f.title}>
                  <div className="rule-hand" />
                  <h3 className="mt-5 font-serif text-[24px] font-bold leading-tight tracking-tight">{f.title}</h3>
                  <p className="mt-2 text-[17px] leading-7 text-ink2">{f.body}</p>
                </div>
              ),
            )}
          </div>
        </div>
      </section>

      {/* ---------- close ---------- */}
      <section className="relative z-10 pb-28 sm:pb-36">
        <div className="mx-auto flex max-w-[1180px] flex-col items-center px-5 text-center sm:px-8">
          <Mascot size={62} />
          <h2 className="balance mt-7 max-w-[16ch] font-serif text-[clamp(2.4rem,6vw,4.2rem)] font-bold leading-[1] tracking-[-0.03em]">
            Start with the last thing you sent yourself.
          </h2>
          <Link href="/library" className="btn-pill-lg mt-10">
            Open the web app
          </Link>
        </div>
      </section>

      <footer className="relative z-10 border-t border-ink/10">
        <div className="mx-auto flex max-w-[1180px] flex-col gap-3 px-5 py-9 sm:flex-row sm:items-center sm:justify-between sm:px-8">
          <div className="flex items-center gap-2">
            <Mascot size={22} />
            <Wordmark className="text-[19px]" />
          </div>
          <p className="font-serif text-[15px] italic text-ink2">
            © {new Date().getFullYear()} Yogi — save it, then actually do it.
          </p>
        </div>
      </footer>
    </main>
  );
}
