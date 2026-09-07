import { AddForm } from "@/components/AddForm";

export const metadata = { title: "Add" };

export default function AddPage() {
  return (
    <div className="mx-auto flex max-w-xl flex-col gap-6">
      <div>
        <h1 className="font-serif text-[32px] font-bold leading-tight">Add anything</h1>
        <p className="balance mt-1 text-[15px] text-ink2">Paste a link from any app, or jot a note. Yogi turns it into a recipe, place, event or whatever it is.</p>
      </div>
      <AddForm />
    </div>
  );
}
