import Link from "next/link";
import { notFound } from "next/navigation";
import { CategoryTabs } from "@/components/CategoryTabs";
import { getSaves } from "@/lib/data";
import { CATEGORY, type SaveCategory } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function CategoryPage({ params }: { params: Promise<{ category: string }> }) {
  const { category } = await params;
  if (!(category in CATEGORY)) notFound();
  const cat = category as SaveCategory;
  const saves = (await getSaves()).filter((s) => s.category === cat);
  return (
    <div className="flex flex-col gap-5">
      <Link href="/library" className="text-[14px] font-semibold text-ink2">‹ Library</Link>
      <h1 className="font-serif text-[32px] font-bold leading-tight">{CATEGORY[cat].emoji} {CATEGORY[cat].plural}</h1>
      <CategoryTabs saves={saves} category={cat} />
    </div>
  );
}
