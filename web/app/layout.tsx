import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "Albo", template: "%s · Albo" },
  description: "Your Albo library on the big screen. Save anything, find it later, and get plans out of the group chat.",
  applicationName: "Albo",
};

export const viewport: Viewport = {
  themeColor: "#ffffff",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-dvh bg-white text-ink">{children}</body>
    </html>
  );
}
