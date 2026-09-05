"use client";

import { useState } from "react";

export function CopyButton({ text, label = "Copy link", className = "btn-outline" }: { text: string; label?: string; className?: string }) {
  const [done, setDone] = useState(false);
  return (
    <button
      type="button"
      className={className}
      onClick={async () => {
        try {
          await navigator.clipboard.writeText(text);
          setDone(true);
          setTimeout(() => setDone(false), 1800);
        } catch {
          window.prompt("Copy this link", text);
        }
      }}
    >
      {done ? "Copied ✓" : label}
    </button>
  );
}

export function ShareButton({ title, url, className = "btn-primary" }: { title: string; url: string; className?: string }) {
  const [state, setState] = useState<"idle" | "done">("idle");
  return (
    <button
      type="button"
      className={className}
      onClick={async () => {
        if (navigator.share) {
          try { await navigator.share({ title, url }); return; } catch { /* dismissed */ }
        }
        try { await navigator.clipboard.writeText(url); setState("done"); setTimeout(() => setState("idle"), 1800); } catch { window.prompt("Copy this link", url); }
      }}
    >
      {state === "done" ? "Link copied ✓" : "Share plan"}
    </button>
  );
}
