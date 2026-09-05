"use client";

import { useState, useTransition } from "react";
import Link from "next/link";
import { joinCollection } from "@/app/actions";

export function JoinButton({ token, name }: { token: string; name: string }) {
  const [pending, start] = useTransition();
  const [result, setResult] = useState<{ ok: boolean; id?: string; error?: string } | null>(null);
  if (result?.ok) {
    return (
      <div className="rounded-2xl bg-[#EAF8EE] px-4 py-3 text-[15px] font-semibold text-rewardDeep">
        ✅ You're in. <Link href={result.id && result.id !== "demo" ? `/collections/${result.id}` : "/library"} className="underline underline-offset-2">Open {name} in your library</Link>
      </div>
    );
  }
  return (
    <div className="flex flex-col gap-2">
      <button type="button" disabled={pending} onClick={() => start(async () => setResult(await joinCollection(token)))} className="btn-primary">
        {pending ? "Joining…" : "Join this plan"}
      </button>
      {result?.error && <p className="text-[13px] font-medium text-danger">{result.error}</p>}
    </div>
  );
}
