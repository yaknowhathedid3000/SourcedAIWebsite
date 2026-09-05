-- Shared plans on the web: anyone holding a public collection's link can read the
-- saves inside it, even when a save's owner has a private profile.
drop policy if exists saves_read on public.saves;
create policy saves_read on public.saves for select
  using (
    public.can_view(owner_id)
    or exists (
      select 1 from public.collection_saves cs
      where cs.save_id = saves.id and public.is_collection_member(cs.collection_id)
    )
    or exists (
      select 1 from public.collection_saves cs
      join public.collections c on c.id = cs.collection_id
      where cs.save_id = saves.id and c.is_public
    )
  );
