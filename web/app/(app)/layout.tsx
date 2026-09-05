import { AppNav } from "@/components/AppNav";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-dvh bg-white">
      <AppNav />
      <main className="mx-auto w-full max-w-3xl px-4 pb-[calc(88px+env(safe-area-inset-bottom))] pt-4 md:ml-60 md:max-w-none md:px-10 md:pb-16 md:pt-8 lg:max-w-4xl">
        {children}
      </main>
    </div>
  );
}
