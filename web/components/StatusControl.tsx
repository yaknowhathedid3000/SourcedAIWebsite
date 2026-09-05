"use client";

import { useRef, useState, useTransition } from "react";
import { setStatus } from "@/app/actions";
import { CATEGORY, type Save, type SaveStatus } from "@/lib/types";

/**
 * The "Made it? / Visited?" control. On touch it is a slide-to-confirm like iOS
 * (teardown 7.1); on desktop a press works too. Optimistic, then persisted.
 */
export function StatusControl({ save }: { save: Save }) {
  const [status, setLocal] = useState<SaveStatus>(save.status);
  const [pending, start] = useTransition();
  const [drag, setDrag] = useState(0);
  const track = useRef<HTMLDivElement>(null);
  const cat = CATEGORY[save.category];

  const commit = (next: SaveStatus) => {
    setLocal(next);
    start(async () => { await setStatus(save.id, next); });
  };

  if (status === "done") {
    return (
      <div className="flex items-center justify-between rounded-2xl bg-[#EAF8EE] px-4 py-3">
        <span className="text-[15px] font-semibold text-rewardDeep">✅ {cat.doneTab} · in your journal</span>
        <button type="button" onClick={() => commit("saved")} className="text-[13px] font-semibold text-ink2 underline-offset-2 hover:underline">Undo</button>
      </div>
    );
  }

  const onPointerMove = (e: React.PointerEvent) => {
    if (!(e.buttons & 1) || !track.current) return;
    const rect = track.current.getBoundingClientRect();
    setDrag(Math.max(0, Math.min(rect.width - 56, e.clientX - rect.left - 28)));
  };
  const onPointerUp = () => {
    if (!track.current) return;
    const max = track.current.getBoundingClientRect().width - 56;
    if (drag > max * 0.8) { commit("done"); if (navigator.vibrate) navigator.vibrate(30); }
    setDrag(0);
  };

  return (
    <div className="flex flex-col gap-3">
      <div
        ref={track}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerLeave={onPointerUp}
        className="relative h-14 select-none overflow-hidden rounded-pill bg-ink text-white"
        role="button"
        aria-label={cat.doneQuestion}
        onKeyDown={(e) => { if (e.key === "Enter" || e.key === " ") commit("done"); }}
        tabIndex={0}
      >
        <span className="absolute inset-0 flex items-center justify-center text-[17px] font-semibold">{cat.doneQuestion} <span className="ml-2 text-white/60">drag →</span></span>
        <div className="absolute left-1 top-1 flex h-12 w-12 cursor-grab items-center justify-center rounded-full bg-white text-ink transition-transform active:cursor-grabbing" style={{ transform: `translateX(${drag}px)`, transition: drag ? "none" : "transform .2s" }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6" /></svg>
        </div>
      </div>
      <div className="flex gap-2">
        <button type="button" disabled={pending} onClick={() => commit(status === "wantTo" ? "saved" : "wantTo")} className={`btn-outline flex-1 ${status === "wantTo" ? "border-ink bg-ink text-white" : ""}`}>
          {status === "wantTo" ? "✓ " : ""}{cat.wantTab}
        </button>
        <button type="button" onClick={() => commit("done")} className="btn-outline flex-1">Mark {cat.doneTab.toLowerCase()}</button>
      </div>
    </div>
  );
}
