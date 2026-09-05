"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { createSave } from "@/app/actions";
import { BROWSABLE, CATEGORY, type SaveCategory } from "@/lib/types";

/** Add hub: paste a link (extracted by the backend) or write a note. Mirrors the iOS AddAnythingSheet. */
export function AddForm() {
  const router = useRouter();
  const [mode, setMode] = useState<"link" | "note">("link");
  const [url, setUrl] = useState("");
  const [note, setNote] = useState("");
  const [category, setCategory] = useState<SaveCategory>("recipe");
  const [error, setError] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const submit = () => {
    setError(null);
    start(async () => {
      const res = mode === "link" ? await createSave({ url: url.trim(), category }) : await createSave({ note: note.trim(), title: note.trim().split("\n")[0].slice(0, 80), category: "note" });
      if (!res.ok) { setError(res.error ?? "Couldn't save that"); return; }
      router.push(res.id ? `/saves/${res.id}` : "/library");
    });
  };

  const valid = mode === "link" ? /^https?:\/\/\S+$/i.test(url.trim()) : note.trim().length > 0;

  return (
    <div className="flex flex-col gap-5">
      <div className="flex gap-2 rounded-pill bg-option p-1">
        {(["link", "note"] as const).map((m) => (
          <button key={m} type="button" onClick={() => setMode(m)} className={`h-10 flex-1 rounded-pill text-[15px] font-semibold transition ${mode === m ? "bg-white text-ink shadow-card" : "text-ink2"}`}>
            {m === "link" ? "🔗 Paste a link" : "📝 Write a note"}
          </button>
        ))}
      </div>

      {mode === "link" ? (
        <>
          <label className="flex flex-col gap-2">
            <span className="text-[13px] font-semibold uppercase tracking-wide text-muted">Link</span>
            <div className="flex gap-2">
              <input
                inputMode="url"
                autoComplete="off"
                placeholder="https://www.instagram.com/reel/…"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className="h-14 flex-1 rounded-2xl border-[1.5px] border-hairline bg-white px-4 text-[16px] outline-none focus:border-ink"
              />
              <button type="button" onClick={async () => { try { setUrl((await navigator.clipboard.readText()).trim()); } catch { /* denied */ } }} className="btn-outline h-14 px-4">Paste</button>
            </div>
          </label>
          <div>
            <p className="mb-2 text-[13px] font-semibold uppercase tracking-wide text-muted">What is it?</p>
            <div className="flex flex-wrap gap-2">
              {BROWSABLE.map((c) => (
                <button key={c} type="button" onClick={() => setCategory(c)} className={`chip transition ${category === c ? "bg-ink text-white" : ""}`}>
                  {CATEGORY[c].emoji} {CATEGORY[c].title}
                </button>
              ))}
            </div>
            <p className="balance mt-2 text-[12px] text-muted">Albo re-detects the type from the link, this just sets the default.</p>
          </div>
        </>
      ) : (
        <label className="flex flex-col gap-2">
          <span className="text-[13px] font-semibold uppercase tracking-wide text-muted">Note</span>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value.slice(0, 2000))}
            rows={8}
            placeholder={"Cookie recipe from mom\n\n1 cup butter, 2 cups flour…"}
            className="rounded-2xl border-[1.5px] border-hairline bg-white p-4 text-[16px] leading-6 outline-none focus:border-ink"
          />
          <span className="self-end text-[12px] text-muted">{note.length}/2000</span>
        </label>
      )}

      {error && <p className="text-[14px] font-medium text-danger">{error}</p>}
      <button type="button" disabled={!valid || pending} onClick={submit} className="btn-primary">
        {pending ? "Saving…" : "Save to Albo"}
      </button>
    </div>
  );
}
