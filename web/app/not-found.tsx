import Link from "next/link";
import { Mascot } from "@/components/Mascot";

export default function NotFound() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center gap-4 p-8 text-center">
      <Mascot size={72} variant="explorer" />
      <h1 className="balance font-serif text-[28px] font-bold">Nothing saved here</h1>
      <p className="balance max-w-sm text-[15px] text-ink2">That link doesn't point at a save, plan or profile we can find.</p>
      <Link href="/library" className="btn-primary max-w-xs">Back to library</Link>
    </main>
  );
}
