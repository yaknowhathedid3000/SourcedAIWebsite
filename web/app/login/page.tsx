import type { Metadata } from "next";
import { LoginPanel } from "@/components/LoginPanel";
import { OrbitingIcons } from "@/components/OrbitingIcons";
import { Wordmark, Mascot } from "@/components/Mascot";

export const metadata: Metadata = { title: "Sign in" };

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ next?: string; error?: string }> }) {
  const { next = "/library", error } = await searchParams;
  return (
    <main className="grid min-h-dvh grid-cols-1 lg:grid-cols-2">
      <section className="relative hidden items-center justify-center overflow-hidden bg-surface lg:flex">
        <div className="absolute left-8 top-8 flex items-center gap-2">
          <Mascot size={28} />
          <Wordmark className="text-[22px]" />
        </div>
        <OrbitingIcons />
        <p className="balance absolute bottom-10 max-w-md px-8 text-center text-[15px] leading-6 text-ink2">
          Everything you saved on Instagram, TikTok, YouTube, Safari and Notes, in one library that syncs with your phone.
        </p>
      </section>
      <section className="flex flex-col items-center justify-center px-5 py-10 sm:px-10">
        <div className="mb-8 flex items-center gap-2 lg:hidden">
          <Mascot size={34} />
          <Wordmark className="text-[26px]" />
        </div>
        <LoginPanel next={next} error={error} />
        <p className="mt-8 max-w-xs text-center text-[12px] leading-5 text-muted">By continuing you agree to Albo's Terms and Privacy Policy.</p>
      </section>
    </main>
  );
}
