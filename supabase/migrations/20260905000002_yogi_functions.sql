-- RPCs, views and seed data. Every multi-table mutation the app performs goes
-- through one of these so the rules (streaks, credits, task progress) live in
-- exactly one place.

-- ---------------------------------------------------------------------------
-- Seed: the seven Get Started tasks (Albo #146 to #149) and the first stamp.
-- ---------------------------------------------------------------------------

insert into public.checklist_tasks (id, title, subtitle, emoji, reward, target, position) values
  ('list',       'Try making a list',        'Rank your favourites.',                     '📼', 2,   1, 1),
  ('screenshot', 'Import a screenshot',      'Share things you see in videos, or irl.',   '📷', 2,   1, 2),
  ('import5',    'Import 5 things',          'Kickstart your collection.',                '📦', 10,  5, 3),
  ('pin',        'Pin the Yogi shortcut',    'Import things to Yogi even faster.',        '📌', 2,   1, 4),
  ('invite',     'Invite friends',           'Earn 100 credits for every friend who joins.', '🖼️', 500, 1, 5),
  ('bulk',       'Try bulk importing',       'Add a whole collection of saves at once.',  '📦', 2,   1, 6),
  ('review',     'Try reviewing something',  'Rate and review one of your saves.',        '⭐️', 2,   1, 7)
on conflict (id) do update set title = excluded.title, subtitle = excluded.subtitle, emoji = excluded.emoji, reward = excluded.reward, target = excluded.target, position = excluded.position;

insert into public.stamps (id, title, subtitle, goal_label, target, position) values
  ('hoarder', 'Digital Hoarder', 'Build up your stash in Yogi!', 'Import 10 things', 10, 1)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Task and stamp progress helpers (security definer so they can bypass RLS
-- on the ledger, but they only ever act on auth.uid()).
-- ---------------------------------------------------------------------------

create or replace function public.advance_task(p_task_id text, p_amount integer default 1)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.user_tasks ut
  set progress = least(ct.target, ut.progress + p_amount)
  from public.checklist_tasks ct
  where ut.task_id = ct.id and ut.user_id = auth.uid() and ut.task_id = p_task_id;
end $$;

create or replace function public.claim_task(p_task_id text)
returns integer language plpgsql security definer set search_path = public as $$
declare
  reward integer;
begin
  select ct.reward into reward
  from public.user_tasks ut join public.checklist_tasks ct on ct.id = ut.task_id
  where ut.user_id = auth.uid() and ut.task_id = p_task_id
    and ut.progress >= ct.target and ut.claimed_at is null
  for update of ut;
  if reward is null then
    raise exception 'task not claimable' using errcode = 'P0001';
  end if;
  update public.user_tasks set claimed_at = now() where user_id = auth.uid() and task_id = p_task_id;
  insert into public.credit_ledger (user_id, delta, reason, ref) values (auth.uid(), reward, 'task', p_task_id);
  update public.profiles set credits = credits + reward where id = auth.uid();
  return reward;
end $$;

create or replace function public.advance_stamp(p_stamp_id text, p_amount integer default 1)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.user_stamps us
  set progress = least(s.target, us.progress + p_amount),
      unlocked_at = case when us.progress + p_amount >= s.target and us.unlocked_at is null then now() else us.unlocked_at end
  from public.stamps s
  where us.stamp_id = s.id and us.user_id = auth.uid() and us.stamp_id = p_stamp_id;
end $$;

-- Every new save counts toward "Import 5 things" and "Digital Hoarder",
-- and screenshots count toward their task.
create or replace function public.saves_after_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.user_tasks ut set progress = least(ct.target, ut.progress + 1)
  from public.checklist_tasks ct
  where ut.task_id = ct.id and ut.user_id = new.owner_id and ut.task_id = 'import5';

  if new.source_platform = 'screenshot' then
    update public.user_tasks ut set progress = least(ct.target, ut.progress + 1)
    from public.checklist_tasks ct
    where ut.task_id = ct.id and ut.user_id = new.owner_id and ut.task_id = 'screenshot';
  end if;

  update public.user_stamps us
  set progress = least(s.target, us.progress + 1),
      unlocked_at = case when us.progress + 1 >= s.target and us.unlocked_at is null then now() else us.unlocked_at end
  from public.stamps s
  where us.stamp_id = s.id and us.user_id = new.owner_id and us.stamp_id = 'hoarder';
  return new;
end $$;

create trigger saves_after_insert after insert on public.saves
  for each row execute function public.saves_after_insert();

-- Lists count toward "Try making a list".
create or replace function public.lists_after_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.user_tasks ut set progress = least(ct.target, ut.progress + 1)
  from public.checklist_tasks ct
  where ut.task_id = ct.id and ut.user_id = new.owner_id and ut.task_id = 'list';
  return new;
end $$;

create trigger lists_after_insert after insert on public.lists
  for each row execute function public.lists_after_insert();

-- ---------------------------------------------------------------------------
-- submit_review: the "How was it?" transaction (Albo #83 -> #78 -> #85).
-- Marks the save done, stores the review, extends the streak, advances the
-- review task. Returns the new streak length.
-- ---------------------------------------------------------------------------

create or replace function public.submit_review(
  p_save_id uuid,
  p_sentiment public.sentiment,
  p_title text default null,
  p_stars smallint default null,
  p_completed_on date default null,
  p_friends_only boolean default false,
  p_tagged uuid[] default '{}',
  p_photo_paths text[] default '{}'
)
returns table (review_id uuid, streak_weeks integer)
language plpgsql security definer set search_path = public as $$
declare
  v_review_id uuid;
  v_last timestamptz;
  v_streak integer;
  i integer;
begin
  if not exists (select 1 from public.saves where id = p_save_id and owner_id = auth.uid()) then
    raise exception 'not your save' using errcode = '42501';
  end if;

  update public.saves set status = 'done' where id = p_save_id;

  insert into public.reviews (owner_id, save_id, sentiment, title, stars, completed_on, friends_only)
  values (auth.uid(), p_save_id, p_sentiment, nullif(p_title, ''), p_stars, p_completed_on, p_friends_only)
  returning id into v_review_id;

  if array_length(p_tagged, 1) > 0 then
    insert into public.review_tags (review_id, user_id) select v_review_id, unnest(p_tagged) on conflict do nothing;
  end if;

  if array_length(p_photo_paths, 1) > 0 then
    for i in 1..array_length(p_photo_paths, 1) loop
      insert into public.review_photos (review_id, storage_path, position) values (v_review_id, p_photo_paths[i], i - 1);
    end loop;
  end if;

  select last_done_at, profiles.streak_weeks into v_last, v_streak from public.profiles where id = auth.uid() for update;
  if v_last is not null and date_trunc('week', v_last) = date_trunc('week', now()) then
    null; -- same week, streak unchanged
  elsif v_last is not null and date_trunc('week', v_last) + interval '1 week' = date_trunc('week', now()) then
    v_streak := coalesce(v_streak, 0) + 1;
  else
    v_streak := 1;
  end if;
  update public.profiles set streak_weeks = v_streak, last_done_at = now() where id = auth.uid();

  perform public.advance_task('review', 1);

  return query select v_review_id, v_streak;
end $$;

-- ---------------------------------------------------------------------------
-- Collections: join by invite token (join.yogi.app/<token>), Albo #77.
-- ---------------------------------------------------------------------------

create or replace function public.join_collection(p_token text)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  cid uuid;
begin
  select id into cid from public.collections where invite_token = p_token;
  if cid is null then raise exception 'invalid invite' using errcode = 'P0002'; end if;
  insert into public.collection_members (collection_id, user_id, role) values (cid, auth.uid(), 'editor')
  on conflict do nothing;
  return cid;
end $$;

-- ---------------------------------------------------------------------------
-- Referrals: redeem a code, both sides earn (Albo #191 "Redeem Referral Code").
-- ---------------------------------------------------------------------------

create or replace function public.redeem_referral(p_code text)
returns integer language plpgsql security definer set search_path = public as $$
declare
  r public.referrals%rowtype;
begin
  select * into r from public.referrals where code = upper(p_code) for update;
  if r.code is null or r.owner_id = auth.uid() then raise exception 'invalid code' using errcode = 'P0002'; end if;
  if exists (select 1 from public.credit_ledger where user_id = auth.uid() and reason = 'referral_redeemed') then
    raise exception 'already redeemed' using errcode = 'P0003';
  end if;
  insert into public.credit_ledger (user_id, delta, reason, ref) values (auth.uid(), 100, 'referral_redeemed', r.code);
  insert into public.credit_ledger (user_id, delta, reason, ref) values (r.owner_id, 100, 'referral_earned', auth.uid()::text);
  update public.profiles set credits = credits + 100 where id in (auth.uid(), r.owner_id);
  update public.user_tasks ut set progress = least(ct.target, ut.progress + 1)
    from public.checklist_tasks ct where ut.task_id = ct.id and ut.user_id = r.owner_id and ut.task_id = 'invite';
  return 100;
end $$;

-- ---------------------------------------------------------------------------
-- Credits: spend one per import on the free tier. Pro/Max are unlimited.
-- ---------------------------------------------------------------------------

create or replace function public.spend_import_credit()
returns boolean language plpgsql security definer set search_path = public as $$
declare
  p public.profiles%rowtype;
begin
  select * into p from public.profiles where id = auth.uid() for update;
  if p.entitlement <> 'free' then return true; end if;
  if p.credits <= 0 then return false; end if;
  update public.profiles set credits = credits - 1 where id = auth.uid();
  insert into public.credit_ledger (user_id, delta, reason) values (auth.uid(), -1, 'import');
  return true;
end $$;

-- ---------------------------------------------------------------------------
-- Account deletion: schedule, cancel (Albo #205).
-- ---------------------------------------------------------------------------

create or replace function public.request_account_deletion(p_reason text, p_details text default null)
returns timestamptz language plpgsql security definer set search_path = public as $$
declare
  purge timestamptz;
begin
  insert into public.deletion_requests (user_id, reason, details)
  values (auth.uid(), p_reason, p_details)
  on conflict (user_id) do update set reason = excluded.reason, details = excluded.details, requested_at = now(), purge_after = now() + interval '14 days'
  returning purge_after into purge;
  return purge;
end $$;

-- ---------------------------------------------------------------------------
-- Views: save counts, leaderboards, feed, profile stats.
-- ---------------------------------------------------------------------------

-- How many people saved the same thing ("1165 saves"). Public rows only.
create or replace view public.save_counts with (security_invoker = true) as
  select canonical_key, count(*)::integer as save_count
  from public.saves
  group by canonical_key;

create or replace view public.leaderboard_hoarders with (security_invoker = true) as
  select p.id as user_id, p.name, p.handle, p.avatar_mascot, p.avatar_url,
         count(s.id)::integer as count,
         rank() over (order by count(s.id) desc, p.created_at) as rank
  from public.profiles p
  left join public.saves s on s.owner_id = p.id
  group by p.id;

create or replace view public.leaderboard_yappers with (security_invoker = true) as
  select p.id as user_id, p.name, p.handle, p.avatar_mascot, p.avatar_url,
         count(r.id)::integer as count,
         rank() over (order by count(r.id) desc, p.created_at) as rank
  from public.profiles p
  left join public.reviews r on r.owner_id = p.id
  group by p.id;

-- Community feed: public reviews and public lists, newest first (Albo #145).
create or replace view public.feed with (security_invoker = true) as
  select r.id, 'review'::text as kind, r.owner_id as author_id, r.created_at,
         coalesce(r.title, s.title) as title, r.stars, s.id as save_id, s.cover_url, s.cover_emoji, s.cover_tint,
         s.latitude, s.longitude
  from public.reviews r join public.saves s on s.id = r.save_id
  where r.friends_only = false
  union all
  select l.id, 'list', l.owner_id, l.created_at, l.title, null::smallint, null::uuid, null::text, l.cover_emoji, 15658734, null, null
  from public.lists l where l.is_public;

create or replace view public.profile_stats with (security_invoker = true) as
  select p.id as user_id,
         (select count(*) from public.follows f where f.followee_id = p.id and f.status = 'accepted')::integer as followers,
         (select count(*) from public.follows f where f.follower_id = p.id and f.status = 'accepted')::integer as following,
         (select count(*) from public.saves s where s.owner_id = p.id)::integer as saves,
         (select count(*) from public.collections c where c.owner_id = p.id and c.is_public)::integer as public_collections
  from public.profiles p;

-- Common saves between the viewer and another user ("1 common save", Albo #158).
create or replace function public.common_saves(p_user uuid)
returns integer language sql stable security invoker set search_path = public as $$
  select count(distinct a.canonical_key)::integer
  from public.saves a join public.saves b on a.canonical_key = b.canonical_key
  where a.owner_id = auth.uid() and b.owner_id = p_user;
$$;

-- Nearby saves for the map and the Nearby feed (Albo #165), cheap bounding box.
create or replace function public.nearby_saves(p_lat double precision, p_lng double precision, p_radius_km double precision default 10, p_limit integer default 50)
returns setof public.saves language sql stable security invoker set search_path = public as $$
  select * from public.saves
  where latitude between p_lat - p_radius_km / 111.0 and p_lat + p_radius_km / 111.0
    and longitude between p_lng - p_radius_km / (111.0 * cos(radians(p_lat))) and p_lng + p_radius_km / (111.0 * cos(radians(p_lat)))
  order by (latitude - p_lat)^2 + (longitude - p_lng)^2
  limit p_limit;
$$;

-- Full-text search across the caller's library ("Search saves...").
create or replace function public.search_saves(p_query text, p_limit integer default 30)
returns setof public.saves language sql stable security invoker set search_path = public as $$
  select * from public.saves
  where owner_id = auth.uid()
    and (search @@ plainto_tsquery('simple', p_query) or title ilike '%' || p_query || '%')
  order by ts_rank(search, plainto_tsquery('simple', p_query)) desc, created_at desc
  limit p_limit;
$$;

-- ---------------------------------------------------------------------------
-- Realtime: the app subscribes to its own saves and notifications.
-- ---------------------------------------------------------------------------

alter publication supabase_realtime add table public.saves;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.import_jobs;
