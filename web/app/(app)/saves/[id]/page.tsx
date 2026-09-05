import Link from "next/link";
import { notFound } from "next/navigation";
import { SaveBody } from "@/components/SaveBody";
import { SaveCover } from "@/components/SaveCard";
import { StatusControl } from "@/components/StatusControl";
import { getSave } from "@/lib/data";
import { CATEGORY, metaLine } from "@/lib/types";

export const dynamic = "force-dynamic";

export async function generateMetadata({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const save = await getSave(id);
  return { title: save?.title ?? "Save" };
}

/** Item detail (teardown chapter 7): hero, meta block, status control, category body. */
export default async function SavePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const save = await getSave(id);
  if (!save) notFound();
  const cat = CATEGORY[save.category];

  return (
    <article className="flex flex-col gap-6">
      <Link href={`/library/${save.category}`} className="text-[14px] font-semibold text-ink2">‹ {cat.plural}</Link>
      <div className="grid grid-cols-1 gap-8 lg:grid-cols-[minmax(0,400px)_minmax(0,1fr)] lg:gap-12">
        <div className="flex flex-col gap-6 lg:sticky lg:top-8 lg:self-start">
          <SaveCover save={save} className="h-[260px] rounded-card [&_.cover-emoji]:text-[96px]" />
          <header>
            <p className="text-[13px] font-semibold uppercase tracking-wide text-muted">{cat.emoji} {cat.title}</p>
            <h1 className="balance mt-1 font-serif text-[32px] font-bold leading-tight">{save.title}</h1>
            <p className="mt-1 text-[15px] text-ink2">{metaLine(save)}</p>
            {save.source_url && (
              <a href={save.source_url} target="_blank" rel="noreferrer" className="mt-2 inline-flex items-center gap-1 text-[14px] font-semibold text-blue">
                Open source ↗
              </a>
            )}
          </header>
          <StatusControl save={save} />
          {save.private_note && (
            <section className="rounded-card bg-rating p-4">
              <p className="text-[12px] font-semibold uppercase tracking-wide text-[#8A6A00]">Private note</p>
              <p className="mt-1 text-[15px] leading-6">{save.private_note}</p>
            </section>
          )}
        </div>
        <div className="min-w-0 max-w-2xl">
          <SaveBody save={save} />
        </div>
      </div>
    </article>
  );
}
