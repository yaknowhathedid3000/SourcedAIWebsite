import { AppNav } from "@/components/AppNav";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-dvh bg-white">
      <AppNav />
      <main className="ml-[72px] min-h-dvh px-8 pb-16 pt-8 lg:ml-60 lg:px-12"><div className="mx-auto w-full max-w-6xl">
        {children}
      </div></main>
    </div>
  );
}
