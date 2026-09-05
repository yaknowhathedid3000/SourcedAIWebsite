"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Mascot, Wordmark } from "./Mascot";

// Tab order mirrors the iOS AlboTabBar: Library, Map, Add, Community, Profile.
const TABS = [
  { href: "/library", label: "Library", icon: HouseIcon },
  { href: "/map", label: "Map", icon: GlobeIcon },
  { href: "/add", label: "Add", icon: PlusIcon, primary: true },
  { href: "/community", label: "Community", icon: PeopleIcon },
  { href: "/profile", label: "Profile", icon: null },
];

export function AppNav() {
  const path = usePathname();
  const active = (href: string) => path === href || path.startsWith(href + "/");
  return (
    <>
      {/* Desktop sidebar */}
      <aside className="fixed inset-y-0 left-0 hidden w-60 flex-col border-r border-hairline bg-white px-4 py-6 md:flex">
        <Link href="/library" className="mb-8 flex items-center gap-2 px-2">
          <Mascot size={30} />
          <Wordmark className="text-[24px]" />
        </Link>
        <nav className="flex flex-col gap-1">
          {TABS.map((t) => (
            <Link
              key={t.href}
              href={t.href}
              className={`flex h-11 items-center gap-3 rounded-xl px-3 text-[15px] font-semibold transition ${active(t.href) ? "bg-option text-ink" : "text-ink2 hover:bg-surface"}`}
            >
              {t.icon ? <t.icon active={active(t.href)} /> : <Mascot size={22} />}
              {t.label}
            </Link>
          ))}
        </nav>
        <p className="mt-auto px-2 text-[12px] leading-5 text-muted">Save anything, find it later, and get plans out of the group chat.</p>
      </aside>

      {/* Mobile bottom tab bar (matches the iOS bar, incl. the raised plus) */}
      <nav className="fixed inset-x-0 bottom-0 z-30 border-t border-hairline bg-white/95 pb-[env(safe-area-inset-bottom)] backdrop-blur md:hidden">
        <div className="mx-auto flex h-[62px] max-w-lg items-center justify-around px-2">
          {TABS.map((t) =>
            t.primary ? (
              <Link key={t.href} href={t.href} aria-label="Add" className="-mt-6 flex h-14 w-14 items-center justify-center rounded-full bg-ink text-white shadow-hard active:translate-y-[3px] active:shadow-none">
                <PlusIcon active />
              </Link>
            ) : (
              <Link key={t.href} href={t.href} aria-label={t.label} className={`flex h-12 w-14 items-center justify-center ${active(t.href) ? "text-ink" : "text-muted"}`}>
                {t.icon ? <t.icon active={active(t.href)} /> : <span className={`rounded-full ${active(t.href) ? "ring-2 ring-ink ring-offset-2" : ""}`}><Mascot size={24} /></span>}
              </Link>
            ),
          )}
        </div>
      </nav>
    </>
  );
}

type IconProps = { active?: boolean };
const stroke = (a?: boolean) => ({ fill: "none", stroke: "currentColor", strokeWidth: a ? 2.4 : 2, strokeLinecap: "round" as const, strokeLinejoin: "round" as const });

function HouseIcon({ active }: IconProps) {
  return <svg width="26" height="26" viewBox="0 0 24 24" {...stroke(active)}><path d="M3 11.5 12 4l9 7.5" /><path d="M5 10v10h5v-6h4v6h5V10" fill={active ? "currentColor" : "none"} /></svg>;
}
function GlobeIcon({ active }: IconProps) {
  return <svg width="26" height="26" viewBox="0 0 24 24" {...stroke(active)}><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18" /></svg>;
}
function PlusIcon({ active }: IconProps) {
  return <svg width="26" height="26" viewBox="0 0 24 24" {...stroke(active)} strokeWidth={2.6}><path d="M12 5v14M5 12h14" /></svg>;
}
function PeopleIcon({ active }: IconProps) {
  return <svg width="26" height="26" viewBox="0 0 24 24" {...stroke(active)}><circle cx="9" cy="8" r="3.5" fill={active ? "currentColor" : "none"} /><circle cx="17" cy="9" r="2.5" /><path d="M2.5 19c.5-3.5 3-5.5 6.5-5.5s6 2 6.5 5.5M16 14.5c2.5 0 4.5 1.5 5 4" /></svg>;
}
