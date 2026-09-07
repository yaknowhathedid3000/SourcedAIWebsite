import type { Metadata } from "next";
import Link from "next/link";
import { Mascot, Wordmark } from "@/components/Mascot";
import { PhoneMock } from "@/components/marketing/PhoneMock";

export const metadata: Metadata = {
  title: { absolute: "Yogi — save it, then actually do it" },
  description:
    "Yogi catches the recipes, places, films and links you save across TikTok, Instagram and Safari, reads them properly, and files them where you will find them again.",
};

const STEPS = [
  {
    n: "01",
    title: "Share it",
    body: "Hit share in TikTok, Instagram, Safari or Photos and pick Yogi. One tap, no forms, no tabs left open.",
  },
  {
    n: "02",
    title: "Yogi reads it",
    body: "It watches the video, reads the page, pulls out the ingredients, the address, the runtime — and files it under the right category.",
  },
  {
    n: "03",
    title: "Actually do it",
    body: "Cook it, visit it, watch it. Slide to confirm, leave a line about how it went, and it lands in your journal.",
  },
];

const CATEGORIES = [
  { emoji: "🍲", label: "Recipes", tint: "#F7D9B0" },
  { emoji: "🗺️", label: "Places", tint: "#DDF0E2" },
  { emoji: "📼", label: "Films", tint: "#E4E1FA" },
  { emoji: "📚", label: "Books", tint: "#FDE7F3" },
  { emoji: "🧺", label: "Products", tint: "#FFF1E6" },
  { emoji: "🏋️", label: "Workouts", tint: "#E6F0FF" },
  { emoji: "🖥️", label: "Software", tint: "#F1F1F1" },
  { emoji: "📺", label: "TV", tint: "#FDE8E8" },
  { emoji: "🎟️", label: "Events", tint: "#FFF6DA" },
  { emoji: "📰", label: "Articles", tint: "#E8F8FA" },
  { emoji: "📐", label: "Tutorials", tint: "#EDE9FE" },
  { emoji: "🎮", label: "Games", tint: "#FFEBDD" },
];

const FEATURES = [
  {
    emoji: "💬",
    title: "Ask Yogi",
    body: "“What was that pasta I saved last week?” It answers from your own library, not the internet's.",
  },
  {
    emoji: "🌍",
    title: "Your places on a map",
    body: "Every restaurant and bar you saved, pinned. Yogi nudges you when you are standing near one.",
  },
  {
    emoji: "⏰",
    title: "Reminders that land",
    body: "Set a save for Saturday morning and it comes back then, instead of rotting at the bottom of a list.",
  },
  {
    emoji: "📔",
    title: "A journal, not a graveyard",
    body: "Rate what you tried, add a photo, keep the note. The stuff you did is worth more than the stuff you saved.",
  },
  {
    emoji: "📁",
    title: "Collections you can share",
    body: "Build a list of places for a trip, send one link, let people add to it. No screenshots in the group chat.",
  },
  {
    emoji: "🖥️",
    title: "Same library on desktop",
    body: "Plan on the big screen, sorted and searchable, synced with the phone in your pocket.",
  },
];

export default function Home() {
  return (
    <main>
      {/* ---------- nav ---------- */}
      <header className="mx-auto flex max-w-6xl items-center justify-between px-5 py-5 sm:px-8">
        <div className="flex items-center gap-2">
          <Mascot size={30} />
          <Wordmark className="text-[25px]" />
        </div>
        <nav className="flex items-center gap-2 sm:gap-4">
          <Link href="#how" className="hidden text-[15px] font-medium text-ink2 hover:text-ink sm:block">
            How it works
          </Link>
          <Link href="/library" className="btn-outline">
            Open the web app
          </Link>
        </nav>
      </header>

      {/* ---------- hero ---------- */}
      <section className="mx-auto max-w-6xl px-5 pb-16 pt-6 sm:px-8 sm:pb-24 sm:pt-14">
        <div className="grid items-center gap-14 lg:grid-cols-[1.05fr_auto]">
          <div className="animate-rise">
            <span className="chip">Coming to iPhone</span>
            <h1 className="balance mt-5 font-serif text-[46px] font-bold leading-[1.03] tracking-tight sm:text-[64px]">
              Save it. Then actually do it.
            </h1>
            <p className="balance mt-5 max-w-xl text-[18px] leading-7 text-ink2 sm:text-[19px]">
              You have saved four hundred recipes and cooked six of them. Yogi catches everything
              you send it, reads it properly, and hands it back at the moment you can use it.
            </p>
            <div className="mt-8 flex max-w-md flex-col gap-3 sm:flex-row">
              <Link href="/library" className="btn-primary sm:w-auto sm:px-8">
                Open the web app
              </Link>
              <Link href="#how" className="btn-secondary sm:w-auto sm:px-8">
                See how it works
              </Link>
            </div>
            <p className="mt-4 text-[14px] text-muted">Free while we are in beta. No card, no ads.</p>
          </div>
          <PhoneMock />
        </div>
      </section>

      {/* ---------- how it works ---------- */}
      <section id="how" className="scroll-mt-8 bg-surface py-20 sm:py-28">
        <div className="mx-auto max-w-6xl px-5 sm:px-8">
          <h2 className="balance max-w-2xl font-serif text-[34px] font-bold leading-tight tracking-tight sm:text-[44px]">
            Three taps between seeing it and having it.
          </h2>
          <div className="mt-12 grid gap-8 sm:grid-cols-3 sm:gap-6">
            {STEPS.map((s) => (
              <div key={s.n}>
                <span className="font-serif text-[15px] font-bold tracking-[0.14em] text-muted">{s.n}</span>
                <h3 className="mt-3 font-serif text-[24px] font-bold tracking-tight">{s.title}</h3>
                <p className="mt-2 text-[16px] leading-7 text-ink2">{s.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ---------- categories ---------- */}
      <section className="py-20 sm:py-28">
        <div className="mx-auto max-w-6xl px-5 sm:px-8">
          <h2 className="balance max-w-2xl font-serif text-[34px] font-bold leading-tight tracking-tight sm:text-[44px]">
            It knows what kind of thing you just sent it.
          </h2>
          <p className="balance mt-4 max-w-xl text-[17px] leading-7 text-ink2">
            A recipe gets ingredients and a method. A restaurant gets an address and opening hours.
            A book gets its author. You never pick a folder.
          </p>
          <ul className="mt-12 grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-6">
            {CATEGORIES.map((c) => (
              <li
                key={c.label}
                className="flex flex-col items-center gap-2 rounded-card border border-hairline px-3 py-6"
              >
                <span
                  className="grid h-12 w-12 place-items-center rounded-[14px] text-[24px]"
                  style={{ background: c.tint }}
                >
                  {c.emoji}
                </span>
                <span className="text-[15px] font-semibold">{c.label}</span>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* ---------- features ---------- */}
      <section className="bg-surface py-20 sm:py-28">
        <div className="mx-auto max-w-6xl px-5 sm:px-8">
          <h2 className="balance max-w-2xl font-serif text-[34px] font-bold leading-tight tracking-tight sm:text-[44px]">
            Everything after the save.
          </h2>
          <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((f) => (
              <div key={f.title} className="card p-6">
                <span className="text-[26px]">{f.emoji}</span>
                <h3 className="mt-3 font-serif text-[21px] font-bold tracking-tight">{f.title}</h3>
                <p className="mt-2 text-[15px] leading-6 text-ink2">{f.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ---------- closing ---------- */}
      <section className="py-24 sm:py-32">
        <div className="mx-auto flex max-w-2xl flex-col items-center px-5 text-center sm:px-8">
          <Mascot size={58} />
          <h2 className="balance mt-6 font-serif text-[36px] font-bold leading-tight tracking-tight sm:text-[46px]">
            Your saved folder is not a plan.
          </h2>
          <p className="balance mt-4 text-[18px] leading-7 text-ink2">
            Start with the last thing you sent yourself and never got round to.
          </p>
          <Link href="/library" className="btn-primary mt-8 sm:w-auto sm:px-10">
            Open the web app
          </Link>
        </div>
      </section>

      {/* ---------- footer ---------- */}
      <footer className="border-t border-hairline">
        <div className="mx-auto flex max-w-6xl flex-col gap-4 px-5 py-10 sm:flex-row sm:items-center sm:justify-between sm:px-8">
          <div className="flex items-center gap-2">
            <Mascot size={24} />
            <Wordmark className="text-[19px]" />
          </div>
          <p className="text-[14px] text-muted">© {new Date().getFullYear()} Yogi. Save it, then actually do it.</p>
        </div>
      </footer>
    </main>
  );
}
