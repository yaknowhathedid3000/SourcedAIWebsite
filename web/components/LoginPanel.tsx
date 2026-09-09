"use client";

import { useState } from "react";
import Link from "next/link";
import { QRCodeSVG } from "qrcode.react";
import { browserClient, isConfigured } from "@/lib/supabase/client";

type Modal = null | "setup" | "qr";

/** The yogi.app/login "Sign In" card. Phone only, matching the app: there is no
 *  password and no third-party provider anywhere in the product. */
export function LoginPanel({ next, error }: { next: string; error?: string }) {
  const [modal, setModal] = useState<Modal>(error === "no_account" ? "setup" : null);
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(error === "auth" ? "That sign-in didn't complete. Try again." : null);

  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [sent, setSent] = useState(false);

  const sendCode = async () => {
    const sb = browserClient();
    if (!sb) { setModal("setup"); return; }
    setBusy("send"); setMessage(null);
    const { error } = await sb.auth.signInWithOtp({ phone });
    setBusy(null);
    if (error) setMessage(error.message); else setSent(true);
  };

  const verifyCode = async () => {
    const sb = browserClient();
    if (!sb) { setModal("setup"); return; }
    setBusy("verify"); setMessage(null);
    const { error } = await sb.auth.verifyOtp({ phone, token: code, type: "sms" });
    setBusy(null);
    if (error) setMessage(error.message);
    else window.location.assign(next);
  };

  const qrValue = typeof window === "undefined" ? "https://yogi.app/download" : `${window.location.origin}/login?via=qr`;

  return (
    <>
      <div className="card w-full max-w-[420px] px-7 py-8 sm:px-9">
        <h1 className="font-serif text-[34px] font-bold leading-tight">Sign In</h1>
        <p className="balance mt-1 text-[15px] text-ink2">Your saves, plans and journal, on the big screen.</p>
        <div className="mt-7 flex flex-col gap-3">
          {!sent ? (
            <>
              <input
                type="tel"
                inputMode="tel"
                autoComplete="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+1 555 123 4567"
                className="h-[52px] w-full rounded-pill bg-option px-5 text-[16px] outline-none focus:ring-2 focus:ring-ink/20"
              />
              <button type="button" onClick={sendCode} disabled={busy !== null || phone.replace(/\D/g, "").length < 7} className="btn-primary h-[52px] text-[16px] disabled:opacity-40">
                {busy === "send" ? "Sending…" : "Text me a code"}
              </button>
            </>
          ) : (
            <>
              <input
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                maxLength={6}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
                placeholder="6 digit code"
                className="h-[52px] w-full rounded-pill bg-option px-5 text-center text-[20px] tracking-[0.4em] outline-none focus:ring-2 focus:ring-ink/20"
              />
              <button type="button" onClick={verifyCode} disabled={busy !== null || code.length !== 6} className="btn-primary h-[52px] text-[16px] disabled:opacity-40">
                {busy === "verify" ? "Checking…" : "Verify"}
              </button>
              <button type="button" onClick={() => { setSent(false); setCode(""); }} className="text-[14px] font-medium text-ink2 underline underline-offset-2">
                Use a different number
              </button>
            </>
          )}
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
          New here? Create your account on the Yogi app first, then sign in here with the same number.{" "}
          <button type="button" onClick={() => setModal("setup")} className="font-semibold text-ink underline underline-offset-2">Get the app</button>
        </p>
      </div>

      {modal && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-0 sm:items-center sm:p-6" onClick={() => setModal(null)}>
          <div className="w-full max-w-[440px] rounded-t-sheet bg-white px-7 pb-[max(28px,env(safe-area-inset-bottom))] pt-7 sm:rounded-sheet" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal>
            {modal === "setup" ? (
              <>
                <h2 className="balance font-serif text-[26px] font-bold leading-tight">Set up your account on the Yogi app</h2>
                <p className="balance mt-2 text-[15px] leading-6 text-ink2">To use the web app, you first need to create an account on the Yogi mobile app.</p>
                <div className="mx-auto mt-6 w-fit rounded-2xl border border-hairline p-3"><QRCodeSVG value="https://yogi.app/download" size={164} /></div>
                <div className="mt-6 grid grid-cols-2 gap-3">
                  <StoreBadge label="Download on the" store="App Store" href="https://apps.apple.com/app/yogi-save-organize/id6484345096" />
                  <StoreBadge label="GET IT ON" store="Google Play" href="https://play.google.com/store/apps/details?id=inc.yogi" />
                </div>
              </>
            ) : (
              <>
                <h2 className="balance font-serif text-[26px] font-bold leading-tight">Scan with the Yogi app</h2>
                <p className="balance mt-2 text-[15px] leading-6 text-ink2">Open Yogi on your phone, go to Profile → Sign in on web, and point the camera here.</p>
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


function QrGlyph() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="7" height="7" rx="1.5" /><rect x="14" y="3" width="7" height="7" rx="1.5" /><rect x="3" y="14" width="7" height="7" rx="1.5" /><path d="M14 14h3v3h-3zM20 14v.01M17 20h3M14 20v.01M20 17v.01" /></svg>;
}
