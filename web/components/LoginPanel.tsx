"use client";

import { useState } from "react";
import Link from "next/link";
import { QRCodeSVG } from "qrcode.react";
import { browserClient, isConfigured } from "@/lib/supabase/client";

type Modal = null | "setup" | "qr";

/** The albo.inc/login "Sign In" card: Google, Apple, QR, and the "Set up your account on the Albo app" modal. */
export function LoginPanel({ next, error }: { next: string; error?: string }) {
  const [modal, setModal] = useState<Modal>(error === "no_account" ? "setup" : null);
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(error === "auth" ? "That sign-in didn't complete. Try again." : null);

  const oauth = async (provider: "google" | "apple") => {
    const sb = browserClient();
    if (!sb) { setModal("setup"); return; }
    setBusy(provider);
    const redirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;
    const { error } = await sb.auth.signInWithOAuth({ provider, options: { redirectTo } });
    if (error) { setMessage(error.message); setBusy(null); }
  };

  const qrValue = typeof window === "undefined" ? "https://albo.app/download" : `${window.location.origin}/login?via=qr`;

  return (
    <>
      <div className="card w-full max-w-[420px] px-7 py-8 sm:px-9">
        <h1 className="font-serif text-[34px] font-bold leading-tight">Sign In</h1>
        <p className="balance mt-1 text-[15px] text-ink2">Your saves, plans and journal, on any screen.</p>
        <div className="mt-7 flex flex-col gap-3">
          <button type="button" onClick={() => oauth("google")} disabled={busy !== null} className="btn-outline h-[52px] w-full justify-start gap-3 px-5 text-[16px]">
            <GoogleGlyph /> {busy === "google" ? "Opening Google…" : "Continue with Google"}
          </button>
          <button type="button" onClick={() => oauth("apple")} disabled={busy !== null} className="btn-outline h-[52px] w-full justify-start gap-3 px-5 text-[16px]">
            <AppleGlyph /> {busy === "apple" ? "Opening Apple…" : "Continue with Apple"}
          </button>
          <button type="button" onClick={() => setModal("qr")} className="btn-outline h-[52px] w-full justify-start gap-3 px-5 text-[16px]">
            <QrGlyph /> Continue with QR code
          </button>
        </div>
        {message && <p className="mt-4 text-[13px] font-medium text-danger">{message}</p>}
        {!isConfigured && (
          <div className="mt-6 rounded-2xl bg-surface p-4 text-[13px] leading-5 text-ink2">
            <p className="font-semibold text-ink">Demo mode</p>
            <p className="balance">No backend is configured, so the site runs on sample data.</p>
            <Link href="/library" className="mt-3 inline-flex h-10 items-center rounded-pill bg-ink px-4 font-semibold text-white">Explore the demo →</Link>
          </div>
        )}
        <p className="mt-6 text-[12px] leading-5 text-muted">
          New here? Create your account on the Albo app first, then sign in with the same Google or Apple ID.{" "}
          <button type="button" onClick={() => setModal("setup")} className="font-semibold text-ink underline underline-offset-2">Get the app</button>
        </p>
      </div>

      {modal && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-0 sm:items-center sm:p-6" onClick={() => setModal(null)}>
          <div className="w-full max-w-[440px] rounded-t-sheet bg-white px-7 pb-[max(28px,env(safe-area-inset-bottom))] pt-7 sm:rounded-sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal>
            {modal === "setup" ? (
              <>
                <h2 className="balance font-serif text-[26px] font-bold leading-tight">Set up your account on the Albo app</h2>
                <p className="balance mt-2 text-[15px] leading-6 text-ink2">To use the web app, you first need to create an account on the Albo mobile app.</p>
                <div className="mx-auto mt-6 w-fit rounded-2xl border border-hairline p-3"><QRCodeSVG value="https://albo.app/download" size={164} /></div>
                <div className="mt-6 grid grid-cols-2 gap-3">
                  <StoreBadge label="Download on the" store="App Store" href="https://apps.apple.com/app/albo-save-organize/id6484345096" />
                  <StoreBadge label="GET IT ON" store="Google Play" href="https://play.google.com/store/apps/details?id=inc.albo" />
                </div>
              </>
            ) : (
              <>
                <h2 className="balance font-serif text-[26px] font-bold leading-tight">Scan with the Albo app</h2>
                <p className="balance mt-2 text-[15px] leading-6 text-ink2">Open Albo on your phone, go to Profile → Sign in on web, and point the camera here.</p>
                <div className="mx-auto mt-6 w-fit rounded-2xl border border-hairline p-3"><QRCodeSVG value={qrValue} size={184} /></div>
              </>
            )}
            <button type="button" onClick={() => setModal(null)} className="mt-6 w-full text-center text-[15px] font-semibold text-ink underline-offset-2 hover:underline">Back to sign in</button>
          </div>
        </div>
      )}
    </>
  );
}

function StoreBadge({ label, store, href }: { label: string; store: string; href: string }) {
  return (
    <a href={href} target="_blank" rel="noreferrer" className="flex h-[52px] items-center gap-2 rounded-xl bg-ink px-3 text-white">
      <span className="text-[20px]">{store === "App Store" ? "" : "▶"}</span>
      <span className="flex flex-col leading-none"><span className="text-[9px] uppercase tracking-wide opacity-80">{label}</span><span className="text-[15px] font-semibold">{store}</span></span>
    </a>
  );
}
function GoogleGlyph() {
  return <svg width="20" height="20" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.6 12.3c0-.8-.1-1.5-.2-2.2H12v4.2h6c-.3 1.4-1 2.6-2.2 3.4v2.8h3.6c2.1-1.9 3.2-4.8 3.2-8.2z" /><path fill="#34A853" d="M12 23c3 0 5.5-1 7.3-2.7l-3.6-2.8c-1 .7-2.3 1.1-3.7 1.1-2.9 0-5.3-1.9-6.2-4.6H2.1v2.9C3.9 20.4 7.7 23 12 23z" /><path fill="#FBBC05" d="M5.8 14c-.2-.7-.4-1.4-.4-2s.1-1.4.4-2V7H2.1C1.4 8.5 1 10.2 1 12s.4 3.5 1.1 5l3.7-3z" /><path fill="#EA4335" d="M12 5.4c1.6 0 3.1.6 4.2 1.7l3.2-3.2C17.5 2.1 15 1 12 1 7.7 1 3.9 3.6 2.1 7l3.7 3c.9-2.7 3.3-4.6 6.2-4.6z" /></svg>;
}
function AppleGlyph() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M16.4 12.6c0-2.5 2-3.6 2.1-3.7-1.2-1.7-3-1.9-3.6-2-1.5-.2-3 .9-3.8.9-.8 0-2-.9-3.3-.8-1.7 0-3.2 1-4.1 2.5-1.8 3-.5 7.6 1.3 10.1.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.3.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9-.1 0-2.9-1.1-2.9-4.2zM14 5.3c.7-.8 1.2-2 1-3.1-1 0-2.2.7-2.9 1.5-.6.7-1.2 1.9-1 3 1.1.1 2.2-.6 2.9-1.4z" /></svg>;
}
function QrGlyph() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="3" width="7" height="7" rx="1.5" /><rect x="3" y="14" width="7" height="7" rx="1.5" /><path d="M14 14h3v3h-3zM20 14v.01M17 20h3M14 20v.01M20 17v.01" /></svg>;
}
