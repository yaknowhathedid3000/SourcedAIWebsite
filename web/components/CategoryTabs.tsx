"use client";

import { useState } from "react";
import { SaveRow } from "./SaveCard";
import { CATEGORY, type Save, type SaveCategory } from "@/lib/types";

/** All / Want to / Done tabs in the italic serif (teardown 6.4). */
export function CategoryTabs({ saves, category }: { saves: Save[]; category: SaveCategory }) {
  const cat = CATEGORY[category];
  const [tab, setTab] = useState<"all" | "wantTo" | "done">("all");
  const [grid, setGrid] = useState(false);
  const shown = saves.filter((s) => tab === "all" || s.status === tab);
  const tabs: ["all" | "wantTo" | "done", string][] = [["all", "All"], ["wantTo", cat.wantTab], ["done", cat.doneTab]];
  return (
    <div>
      <div className="mb-4 flex items-center gap-5 overflow-x-auto">
        {tabs.map(([k, label]) => (
          <button key={k} type="button" onClick={() => setTab(k)} className={`whitespace-nowrap ${tab === k ? "tab-serif-active" : "tab-serif"}`}>
            {label}
          </button>
        ))}
        <button type="button" aria-label="Toggle grid" onClick={() => setGrid((g) => !g)} className="ml-auto flex h-9 w-9 items-center justify-center rounded-full bg-option text-ink2">
          {grid ? "☰" : "▦"}
        </button>
      </div>
      {shown.length === 0 ? (
        <div className="rounded-card bg-surface p-8 text-center">
          <p className="balance text-[17px] font-semibold">Nothing here yet</p>
          <p className="balance mt-1 text-[14px] text-ink2">Save a {cat.title.toLowerCase()} from any app and it lands here.</p>
        </div>
      ) : grid ? (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          {shown.map((s) => (
            <a key={s.id} href={`/saves/${s.id}`} className="card overflow-hidden">
              <div className="flex h-28 items-center justify-center text-[40px]" style={{ background: "#" + s.cover_tint.toString(16).padStart(6, "0") }}>{s.cover_emoji ?? cat.emoji}</div>
              <p className="line-clamp-2 p-3 text-[14px] font-semibold">{s.title}</p>
            </a>
          ))}
        </div>
      ) : (
        <div className="flex flex-col">
          {shown.map((s) => <SaveRow key={s.id} save={s} />)}
        </div>
      )}
    </div>
  );
}
