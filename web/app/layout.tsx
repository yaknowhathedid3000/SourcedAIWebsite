import type { Metadata, Viewport } from "next";
import { EB_Garamond, Instrument_Sans } from "next/font/google";
import "./globals.css";

// Self-hosted at build time rather than pulled from Google at runtime: no
// render-blocking @import chain, no flash of the fallback serif.
const garamond = EB_Garamond({
  subsets: ["latin"],
  style: ["normal", "italic"],
  variable: "--font-serif",
  display: "swap",
});

const instrument = Instrument_Sans({
  subsets: ["latin"],
  style: ["normal", "italic"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: { default: "Yogi", template: "%s · Yogi" },
  description: "Your Yogi library on the big screen. Save anything, find it later, and get plans out of the group chat.",
  applicationName: "Yogi",
};

export const viewport: Viewport = {
  themeColor: "#ffffff",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${garamond.variable} ${instrument.variable}`}>
      <body className="min-h-dvh bg-white text-ink">{children}</body>
    </html>
  );
}
