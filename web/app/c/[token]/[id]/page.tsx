import Link from "next/link";
import { notFound } from "next/navigation";
import { Mascot, Wordmark } from "@/components/Mascot";
import { SaveBody } from "@/components/SaveBody";
import { SaveCover } from "@/components/SaveCard";
import { getCollectionByToken } from "@/lib/data";
import { CATEGORY, metaLine } from "@/lib/types";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ token: string; id: string }> }) {
  const { token, id } = await params;
  const data = await getCollectionByToken(token);
  const save = data?.saves.find((s) => s.id === id);
  return { title: save ? `${save.title} · ${data!.collection.name}` : "Shared plan" };
}

/** Public, read-only item inside a shared plan. No account needed. */
export default async function SharedItemPage({ params }: { params: Promise<{ token: string; id: string }> }) {
  const { token, id } = await params;
  const data = await getCollectionByToken(token);
  const save = data?.saves.find((s) => s.id === id);
  if (!data || !save) notFound();
  const cat = CATEGORY[save.category];

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-2xl flex-col gap-6 px-4 pb-16 pt-6">
      <header className="flex items-center justify-between">
        <Link href={`/c/${token}`} className="text-[14px] font-semibold text-ink2">‹ {data.collection.name}</Link>
        <Link href="/" className="flex items-center gap-2"><Mascot size={24} /><Wordmark className="text-[20px]" /></Link>
      </header>
      <SaveCover save={save} className="h-[220px] rounded-card [&_.cover-emoji]:text-[88px]" />
      <div>
        <p className="text-[13px] font-semibold uppercase tracking-wide text-muted">{cat.emoji} {cat.title}</p>
        <h1 className="balance mt-1 font-serif text-[30px] font-bold leading-tight">{save.title}</h1>
        <p className="mt-1 text-[15px] text-ink2">{metaLine(save)}</p>
        {save.source_url && (
          <a href={save.source_url} target="_blank" rel="noreferrer" className="mt-2 inline-flex items-center gap-1 text-[14px] font-semibold text-blue">Open source ↗</a>
        )}
      </div>
      <SaveBody save={save} />
      <div className="card mt-2 flex items-center gap-3 p-4">
        <Mascot size={36} />
        <p className="balance text-[14px] leading-5 text-ink2">Want this in your own library? <Link href={`/c/${token}`} className="font-semibold text-ink underline underline-offset-2">Join the plan</Link>.</p>
      </div>
    </main>
  );
}
