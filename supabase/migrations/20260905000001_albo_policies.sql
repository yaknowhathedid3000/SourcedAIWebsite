-- Row-level security for every Albo table. Principle: owners write, the public
-- reads what a public account chose to share, private accounts are visible to
-- accepted followers only, blocks hide both directions.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.is_following(viewer uuid, target uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.follows
    where follower_id = viewer and followee_id = target and status = 'accepted'
  );
$$;

create or replace function public.is_blocked(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a)
  );
$$;

-- Can the current user see content owned by `owner`?
create or replace function public.can_view(owner uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select
    owner = auth.uid()
    or (
      not public.is_blocked(auth.uid(), owner)
      and (
        not exists (select 1 from public.profiles p where p.id = owner and p.is_private)
        or public.is_following(auth.uid(), owner)
      )
    );
$$;

create or replace function public.is_collection_member(cid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.collections c where c.id = cid and c.owner_id = auth.uid()
  ) or exists (
    select 1 from public.collection_members m where m.collection_id = cid and m.user_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------

alter table public.profiles           enable row level security;
alter table public.saves              enable row level security;
alter table public.collections        enable row level security;
alter table public.collection_members enable row level security;
alter table public.collection_saves   enable row level security;
alter table public.lists              enable row level security;
alter table public.list_items         enable row level security;
alter table public.reviews            enable row level security;
alter table public.review_photos      enable row level security;
alter table public.review_tags        enable row level security;
alter table public.comments           enable row level security;
alter table public.comment_likes      enable row level security;
alter table public.reactions          enable row level security;
alter table public.reminders          enable row level security;
alter table public.notifications      enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.device_tokens      enable row level security;
alter table public.follows            enable row level security;
alter table public.blocks             enable row level security;
alter table public.checklist_tasks    enable row level security;
alter table public.user_tasks         enable row level security;
alter table public.stamps             enable row level security;
alter table public.user_stamps        enable row level security;
alter table public.credit_ledger      enable row level security;
alter table public.referrals          enable row level security;
alter table public.import_jobs        enable row level security;
alter table public.subscriptions      enable row level security;
alter table public.deletion_requests  enable row level security;

-- ---------------------------------------------------------------------------
-- Profiles: everyone can read the public card; only the owner writes.
-- ---------------------------------------------------------------------------

create policy profiles_read on public.profiles for select
  using (not public.is_blocked(auth.uid(), id));

create policy profiles_update_own on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- Saves
-- ---------------------------------------------------------------------------

create policy saves_read on public.saves for select
  using (
    public.can_view(owner_id)
    or exists (
      select 1 from public.collection_saves cs
      where cs.save_id = saves.id and public.is_collection_member(cs.collection_id)
    )
  );

create policy saves_insert_own on public.saves for insert
  with check (owner_id = auth.uid());

create policy saves_update_own on public.saves for update
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy saves_delete_own on public.saves for delete
  using (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Collections: owner and members read/write; public collections readable.
-- ---------------------------------------------------------------------------

create policy collections_read on public.collections for select
  using ((is_public and public.can_view(owner_id)) or public.is_collection_member(id));

create policy collections_insert_own on public.collections for insert
  with check (owner_id = auth.uid());

create policy collections_update on public.collections for update
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy collections_delete_own on public.collections for delete
  using (owner_id = auth.uid());

create policy collection_members_read on public.collection_members for select
  using (public.is_collection_member(collection_id) or user_id = auth.uid());

create policy collection_members_join on public.collection_members for insert
  with check (user_id = auth.uid());

create policy collection_members_leave on public.collection_members for delete
  using (user_id = auth.uid() or exists (select 1 from public.collections c where c.id = collection_id and c.owner_id = auth.uid()));

create policy collection_saves_read on public.collection_saves for select
  using (
    public.is_collection_member(collection_id)
    or exists (select 1 from public.collections c where c.id = collection_id and c.is_public and public.can_view(c.owner_id))
  );

create policy collection_saves_write on public.collection_saves for insert
  with check (public.is_collection_member(collection_id));

create policy collection_saves_delete on public.collection_saves for delete
  using (public.is_collection_member(collection_id));

-- ---------------------------------------------------------------------------
-- Lists
-- ---------------------------------------------------------------------------

create policy lists_read on public.lists for select
  using (owner_id = auth.uid() or (is_public and public.can_view(owner_id)));

create policy lists_write_own on public.lists for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy list_items_read on public.list_items for select
  using (exists (select 1 from public.lists l where l.id = list_id and (l.owner_id = auth.uid() or (l.is_public and public.can_view(l.owner_id)))));

create policy list_items_write on public.list_items for all
  using (exists (select 1 from public.lists l where l.id = list_id and l.owner_id = auth.uid()))
  with check (exists (select 1 from public.lists l where l.id = list_id and l.owner_id = auth.uid()));

-- ---------------------------------------------------------------------------
-- Reviews: owner always; public reviews follow the owner's visibility;
-- friends-only reviews are visible to accepted followers and tagged people.
-- ---------------------------------------------------------------------------

create policy reviews_read on public.reviews for select
  using (
    owner_id = auth.uid()
    or (not friends_only and public.can_view(owner_id))
    or (friends_only and public.is_following(auth.uid(), owner_id))
    or exists (select 1 from public.review_tags t where t.review_id = reviews.id and t.user_id = auth.uid())
  );

create policy reviews_write_own on public.reviews for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy review_photos_read on public.review_photos for select
  using (exists (select 1 from public.reviews r where r.id = review_id));

create policy review_photos_write on public.review_photos for all
  using (exists (select 1 from public.reviews r where r.id = review_id and r.owner_id = auth.uid()))
  with check (exists (select 1 from public.reviews r where r.id = review_id and r.owner_id = auth.uid()));

create policy review_tags_read on public.review_tags for select
  using (user_id = auth.uid() or exists (select 1 from public.reviews r where r.id = review_id));

create policy review_tags_write on public.review_tags for all
  using (exists (select 1 from public.reviews r where r.id = review_id and r.owner_id = auth.uid()))
  with check (exists (select 1 from public.reviews r where r.id = review_id and r.owner_id = auth.uid()));

-- ---------------------------------------------------------------------------
-- Comments, likes, reactions: readable wherever the target is readable.
-- ---------------------------------------------------------------------------

create policy comments_read on public.comments for select
  using (exists (select 1 from public.saves s where s.id = save_id));

create policy comments_insert on public.comments for insert
  with check (author_id = auth.uid() and exists (select 1 from public.saves s where s.id = save_id));

create policy comments_delete on public.comments for delete
  using (author_id = auth.uid() or exists (select 1 from public.saves s where s.id = save_id and s.owner_id = auth.uid()));

create policy comment_likes_all on public.comment_likes for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy comment_likes_read on public.comment_likes for select using (true);

create policy reactions_read on public.reactions for select using (true);

create policy reactions_write on public.reactions for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Reminders, notifications, prefs, device tokens: strictly per user.
-- ---------------------------------------------------------------------------

create policy reminders_own on public.reminders for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy notifications_read_own on public.notifications for select
  using (user_id = auth.uid());

create policy notifications_update_own on public.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy notification_prefs_own on public.notification_prefs for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy device_tokens_own on public.device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Social graph
-- ---------------------------------------------------------------------------

create policy follows_read on public.follows for select
  using (follower_id = auth.uid() or followee_id = auth.uid() or status = 'accepted');

create policy follows_insert on public.follows for insert
  with check (follower_id = auth.uid() and not public.is_blocked(auth.uid(), followee_id));

create policy follows_update_target on public.follows for update
  using (followee_id = auth.uid()) with check (followee_id = auth.uid());

create policy follows_delete on public.follows for delete
  using (follower_id = auth.uid() or followee_id = auth.uid());

create policy blocks_own on public.blocks for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Gamification: definitions readable by all; progress per user; the ledger is
-- read-only for users (written by security-definer RPCs).
-- ---------------------------------------------------------------------------

create policy checklist_tasks_read on public.checklist_tasks for select using (true);
create policy stamps_read          on public.stamps          for select using (true);

create policy user_tasks_read_own on public.user_tasks for select using (user_id = auth.uid());
create policy user_stamps_read_own on public.user_stamps for select using (user_id = auth.uid());
create policy credit_ledger_read_own on public.credit_ledger for select using (user_id = auth.uid());

create policy referrals_read_own on public.referrals for select using (owner_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Import jobs, subscriptions, deletion
-- ---------------------------------------------------------------------------

create policy import_jobs_own on public.import_jobs for all
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy subscriptions_read_own on public.subscriptions for select using (user_id = auth.uid());

create policy deletion_requests_own on public.deletion_requests for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Storage policies
-- ---------------------------------------------------------------------------

create policy "covers are public" on storage.objects for select
  using (bucket_id in ('covers', 'avatars'));

create policy "users upload their own covers" on storage.objects for insert
  with check (bucket_id in ('covers', 'avatars', 'review-photos', 'imports') and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users manage their own files" on storage.objects for update
  using (bucket_id in ('covers', 'avatars', 'review-photos', 'imports') and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users delete their own files" on storage.objects for delete
  using (bucket_id in ('covers', 'avatars', 'review-photos', 'imports') and (storage.foldername(name))[1] = auth.uid()::text);

create policy "review photos follow review visibility" on storage.objects for select
  using (
    bucket_id = 'review-photos'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or exists (
        select 1 from public.review_photos rp
        join public.reviews r on r.id = rp.review_id
        where rp.storage_path = name
      )
    )
  );

create policy "imports are private" on storage.objects for select
  using (bucket_id = 'imports' and (storage.foldername(name))[1] = auth.uid()::text);
