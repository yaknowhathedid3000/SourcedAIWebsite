"use client";

import { useState } from "react";
import type { Ingredient } from "@/lib/types";

function fmt(q: number): string {
  const whole = Math.floor(q);
  const frac = q - whole;
  const map: [number, string][] = [[0.25, "¼"], [0.333, "⅓"], [0.5, "½"], [0.666, "⅔"], [0.75, "¾"]];
  const f = map.find(([v]) => Math.abs(v - frac) < 0.05);
  if (f) return `${whole ? whole : ""}${f[1]}`;
  return Number.isInteger(q) ? String(q) : q.toFixed(1).replace(/\.0$/, "");
}

/** Ingredient list with the serving multiplier and tick-off (teardown 7.2). */
export function IngredientChecklist({ ingredients, yieldLabel }: { ingredients: Ingredient[]; yieldLabel: string | null }) {
  const [mult, setMult] = useState(1);
  const [checked, setChecked] = useState<Set<number>>(new Set());
  const toggle = (i: number) => setChecked((s) => { const n = new Set(s); n.has(i) ? n.delete(i) : n.add(i); return n; });
  return (
    <section>
      <div className="mb-3 flex items-center justify-between">
        <h2 className="font-serif text-[22px] font-bold">Ingredients</h2>
        <div className="flex items-center gap-1 rounded-pill bg-option p-1 text-[14px] font-semibold">
          {[0.5, 1, 2, 3].map((m) => (
            <button key={m} type="button" onClick={() => setMult(m)} className={`h-8 rounded-pill px-3 transition ${mult === m ? "bg-ink text-white" : "text-ink2"}`}>
              {m}×
            </button>
          ))}
        </div>
      </div>
      {yieldLabel && <p className="mb-2 text-[13px] text-muted">{yieldLabel}{mult !== 1 ? ` · scaled ${mult}×` : ""}</p>}
      <ul className="divide-y divide-hairline">
        {ingredients.map((ing, i) => {
          const on = checked.has(i);
          return (
            <li key={i}>
              <button type="button" onClick={() => toggle(i)} className="flex w-full items-center gap-3 py-3 text-left">
                <span className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 text-[13px] transition ${on ? "border-ink bg-ink text-white" : "border-hairline"}`}>{on ? "✓" : ""}</span>
                <span className="text-[20px]">{ing.emoji}</span>
                <span className={`flex-1 text-[16px] ${on ? "text-muted line-through" : "text-ink"}`}>{ing.name}</span>
                {ing.quantity != null && (
                  <span className="text-[15px] font-semibold text-ink2">{fmt(ing.quantity * mult)}{ing.unit ? ` ${ing.unit}` : ""}</span>
                )}
              </button>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
