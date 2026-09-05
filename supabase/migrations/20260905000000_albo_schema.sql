-- Albo schema. Mirrors the Swift models in ios/Albo/Albo/Models/Models.swift
-- and the object model in docs/albo/albo-teardown.md chapter 2.
-- Apply with: supabase db push

create extension if not exists "pgcrypto";
create extension if not exists "citext";
create extension if not exists "pg_trgm";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

create type public.save_category as enum (
  'recipe','place','film','book','product','workout','software',
  'tvShow','event','article','tutorial','game','note','image'
);

create type public.save_status as enum ('saved','wantTo','done');

create type public.source_platform as enum (
  'tiktok','instagram','safari','facebook','youtube','linkedin','pinterest',
  'threads','screenshot','note','manual'
);

create type public.sentiment as enum (
  'lovedIt','hiddenGem','itsOkay','meh','overhyped','notForMe','avoid'
);

create type public.reminder_slot as enum ('morning','afternoon','evening','beforeBed');

create type public.entitlement as enum ('free','pro','max');

create type public.import_kind as enum ('url','note','screenshots');

create type public.import_status as enum ('queued','running','done','failed');

-- ---------------------------------------------------------------------------
-- Profiles (one per auth user). Albo #171, #174.
-- ---------------------------------------------------------------------------

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  handle         citext unique not null check (handle ~ '^[A-Za-z0-9_]{3,20}$'),
  name           text not null default '',
  bio            text not null default '' check (char_length(bio) <= 500),
  avatar_url     text,
  avatar_mascot  text not null default 'plain',
  instagram      text not null default '',
  tiktok         text not null default '',
  country        text,
  home_cities    text[] not null default '{}',
  is_private     boolean not null default false,
  entitlement    public.entitlement not null default 'free',
  credits        integer not null default 20 check (credits >= 0),
  streak_weeks   integer not null default 0,
  last_done_at   timestamptz,
  discovery_source text,
  onboarding     jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.profiles is 'Public profile plus gamification counters. Credits meter free-tier imports.';

-- ---------------------------------------------------------------------------
-- Saves. The polymorphic core noun (teardown 2.2).
-- Category details live in jsonb columns that decode straight into the Swift
-- RecipeDetails / PlaceDetails / EventDetails / MediaDetails structs.
-- ---------------------------------------------------------------------------

create table public.saves (
  id                   uuid primary key default gen_random_uuid(),
  owner_id             uuid not null references public.profiles (id) on delete cascade,
  category             public.save_category not null,
  title                text not null check (char_length(title) between 1 and 300),
  subtitle             text,
  cover_url            text,
  cover_emoji          text,
  cover_tint           integer not null default 15658734, -- 0xEEEEEE
  source_url           text,
  source_platform      public.source_platform not null default 'manual',
  status               public.save_status not null default 'saved',
  private_note         text,
  note_body            text,
  recipe               jsonb,
  place                jsonb,
  event                jsonb,
  media                jsonb,
  latitude             double precision,
  longitude            double precision,
  event_start          timestamptz,
  is_importing         boolean not null default false,
  mentioned_in_note_id uuid references public.saves (id) on delete set null,
  canonical_key        text generated always as (category::text || ':' || lower(regexp_replace(title, '\s+', ' ', 'g'))) stored,
  search               tsvector generated always as (
                         setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
                         setweight(to_tsvector('simple', coalesce(subtitle, '')), 'B') ||
                         setweight(to_tsvector('simple', coalesce(private_note, '')), 'C')
                       ) stored,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index saves_owner_created_idx   on public.saves (owner_id, created_at desc);
create index saves_owner_category_idx  on public.saves (owner_id, category);
create index saves_canonical_idx       on public.saves (canonical_key);
create index saves_search_idx          on public.saves using gin (search);
create index saves_title_trgm_idx      on public.saves using gin (title gin_trgm_ops);
create index saves_geo_idx             on public.saves (latitude, longitude) where latitude is not null;
create index saves_event_start_idx     on public.saves (event_start) where category = 'event';

-- Keep the geo columns in step with the place jsonb so map queries stay cheap.
create or replace function public.saves_sync_columns()
returns trigger language plpgsql as $$
begin
  if new.place is not null then
    new.latitude  := (new.place->>'latitude')::double precision;
    new.longitude := (new.place->>'longitude')::double precision;
  elsif new.event is not null and new.event ? 'latitude' then
    new.latitude  := (new.event->>'latitude')::double precision;
    new.longitude := (new.event->>'longitude')::double precision;
  end if;
  if new.event is not null and new.event ? 'start' then
    new.event_start := (new.event->>'start')::timestamptz;
  end if;
  new.updated_at := now();
  return new;
end $$;

create trigger saves_sync_columns before insert or update on public.saves
  for each row execute function public.saves_sync_columns();

-- ---------------------------------------------------------------------------
-- Collections and lists. Albo #70 to #77, #108 to #112.
-- ---------------------------------------------------------------------------

create table public.collections (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references public.profiles (id) on delete cascade,
  name        text not null check (char_length(name) between 1 and 50),
  details     text check (char_length(details) <= 200),
  cover_url   text,
  cover_emoji text not null default '📁',
  cover_tint  integer not null default 16091423, -- 0xF5891F
  is_public   boolean not null default true,
  invite_token text unique default encode(gen_random_bytes(9), 'base64url'),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index collections_owner_idx on public.collections (owner_id, created_at desc);

create table public.collection_members (
  collection_id uuid not null references public.collections (id) on delete cascade,
  user_id       uuid not null references public.profiles (id) on delete cascade,
  role          text not null default 'editor' check (role in ('owner','editor','viewer')),
  joined_at     timestamptz not null default now(),
  primary key (collection_id, user_id)
);

create table public.collection_saves (
  collection_id uuid not null references public.collections (id) on delete cascade,
  save_id       uuid not null references public.saves (id) on delete cascade,
  added_by      uuid references public.profiles (id) on delete set null,
  position      integer not null default 0,
  added_at      timestamptz not null default now(),
  primary key (collection_id, save_id)
);

create table public.lists (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references public.profiles (id) on delete cascade,
  category    public.save_category not null,
  title       text not null check (char_length(title) between 1 and 120),
  details     text,
  is_ranked   boolean not null default false,
  cover_emoji text not null default '📼',
  is_public   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table public.list_items (
  list_id  uuid not null references public.lists (id) on delete cascade,
  save_id  uuid not null references public.saves (id) on delete cascade,
  position integer not null,
  primary key (list_id, save_id)
);

-- ---------------------------------------------------------------------------
-- Reviews ("How was it?"), photos, tagged friends. Albo #80 to #85.
-- ---------------------------------------------------------------------------

create table public.reviews (
  id           uuid primary key default gen_random_uuid(),
  owner_id     uuid not null references public.profiles (id) on delete cascade,
  save_id      uuid not null references public.saves (id) on delete cascade,
  sentiment    public.sentiment not null,
  title        text check (char_length(title) <= 300),
  stars        smallint check (stars between 1 and 5),
  completed_on date,
  friends_only boolean not null default false,
  created_at   timestamptz not null default now()
);

create index reviews_owner_idx on public.reviews (owner_id, created_at desc);
create index reviews_save_idx  on public.reviews (save_id);
create index reviews_public_idx on public.reviews (created_at desc) where friends_only = false;

create table public.review_photos (
  id           uuid primary key default gen_random_uuid(),
  review_id    uuid not null references public.reviews (id) on delete cascade,
  storage_path text not null,
  position     integer not null default 0
);

create table public.review_tags (
  review_id uuid not null references public.reviews (id) on delete cascade,
  user_id   uuid not null references public.profiles (id) on delete cascade,
  primary key (review_id, user_id)
);

-- ---------------------------------------------------------------------------
-- Comments and reactions. Albo #88, #157, #164.
-- ---------------------------------------------------------------------------

create table public.comments (
  id         uuid primary key default gen_random_uuid(),
  save_id    uuid not null references public.saves (id) on delete cascade,
  author_id  uuid not null references public.profiles (id) on delete cascade,
  parent_id  uuid references public.comments (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index comments_save_idx on public.comments (save_id, created_at);

create table public.comment_likes (
  comment_id uuid not null references public.comments (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  primary key (comment_id, user_id)
);

create table public.reactions (
  target_type text not null check (target_type in ('save','review','list')),
  target_id   uuid not null,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  emoji       text not null check (char_length(emoji) <= 8),
  created_at  timestamptz not null default now(),
  primary key (target_type, target_id, user_id)
);

create index reactions_target_idx on public.reactions (target_type, target_id);

-- ---------------------------------------------------------------------------
-- Reminders and notifications. Albo #92, #131, #192.
-- ---------------------------------------------------------------------------

create table public.reminders (
  id        uuid primary key default gen_random_uuid(),
  owner_id  uuid not null references public.profiles (id) on delete cascade,
  save_id   uuid not null references public.saves (id) on delete cascade,
  fire_at   timestamptz not null,
  slot      public.reminder_slot not null default 'morning',
  sent_at   timestamptz,
  created_at timestamptz not null default now(),
  unique (owner_id, save_id)
);

create index reminders_due_idx on public.reminders (fire_at) where sent_at is null;

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  kind       text not null check (kind in ('reminder','social','location','marketing','system')),
  title      text not null,
  body       text not null default '',
  save_id    uuid references public.saves (id) on delete cascade,
  actor_id   uuid references public.profiles (id) on delete set null,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, created_at desc);

create table public.notification_prefs (
  user_id   uuid primary key references public.profiles (id) on delete cascade,
  enabled   boolean not null default true,
  location  boolean not null default false,
  reminders boolean not null default true,
  social    boolean not null default true,
  marketing boolean not null default false,
  default_slot public.reminder_slot not null default 'morning',
  default_map  text not null default 'apple' check (default_map in ('apple','google')),
  theme        text not null default 'system' check (theme in ('light','dark','system')),
  language     text not null default 'system'
);

create table public.device_tokens (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  token      text not null,
  platform   text not null default 'ios',
  created_at timestamptz not null default now(),
  primary key (user_id, token)
);

-- ---------------------------------------------------------------------------
-- Social graph. Albo #158, #180.
-- ---------------------------------------------------------------------------

create table public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'accepted' check (status in ('pending','accepted')),
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

create index follows_followee_idx on public.follows (followee_id) where status = 'accepted';

create table public.blocks (
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

-- ---------------------------------------------------------------------------
-- Gamification. Albo #78, #146 to #149, #183, #196.
-- ---------------------------------------------------------------------------

create table public.checklist_tasks (
  id       text primary key,
  title    text not null,
  subtitle text not null,
  emoji    text not null,
  reward   integer not null,
  target   integer not null default 1,
  position integer not null
);

create table public.user_tasks (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  task_id    text not null references public.checklist_tasks (id) on delete cascade,
  progress   integer not null default 0,
  claimed_at timestamptz,
  primary key (user_id, task_id)
);

create table public.stamps (
  id         text primary key,
  title      text not null,
  subtitle   text not null,
  goal_label text not null,
  target     integer not null,
  position   integer not null
);

create table public.user_stamps (
  user_id     uuid not null references public.profiles (id) on delete cascade,
  stamp_id    text not null references public.stamps (id) on delete cascade,
  progress    integer not null default 0,
  unlocked_at timestamptz,
  primary key (user_id, stamp_id)
);

create table public.credit_ledger (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  delta      integer not null,
  reason     text not null,
  ref        text,
  created_at timestamptz not null default now()
);

create index credit_ledger_user_idx on public.credit_ledger (user_id, created_at desc);

create table public.referrals (
  code        text primary key,
  owner_id    uuid not null references public.profiles (id) on delete cascade,
  redeemed_by uuid references public.profiles (id) on delete set null,
  redeemed_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Import jobs, processed by the `extract` edge function. Albo #25, #61, #96.
-- ---------------------------------------------------------------------------

create table public.import_jobs (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid not null references public.profiles (id) on delete cascade,
  kind       public.import_kind not null,
  payload    jsonb not null,
  status     public.import_status not null default 'queued',
  result_ids uuid[] not null default '{}',
  error      text,
  created_at timestamptz not null default now(),
  finished_at timestamptz
);

create index import_jobs_owner_idx on public.import_jobs (owner_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Subscriptions (StoreKit 2 transactions mirrored server-side). Albo #41, #198.
-- ---------------------------------------------------------------------------

create table public.subscriptions (
  user_id                  uuid primary key references public.profiles (id) on delete cascade,
  product_id               text not null,
  original_transaction_id  text unique not null,
  entitlement              public.entitlement not null,
  status                   text not null check (status in ('trial','active','grace','expired','revoked')),
  expires_at               timestamptz,
  updated_at               timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Account deletion queue (14-day grace, Albo #205).
-- ---------------------------------------------------------------------------

create table public.deletion_requests (
  user_id      uuid primary key references public.profiles (id) on delete cascade,
  reason       text,
  details      text,
  requested_at timestamptz not null default now(),
  purge_after  timestamptz not null default now() + interval '14 days'
);

-- ---------------------------------------------------------------------------
-- updated_at touch triggers
-- ---------------------------------------------------------------------------

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch    before update on public.profiles    for each row execute function public.touch_updated_at();
create trigger collections_touch before update on public.collections for each row execute function public.touch_updated_at();
create trigger lists_touch       before update on public.lists       for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- New user bootstrap: profile, prefs, checklist, stamps, starter credits.
-- ---------------------------------------------------------------------------

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  base_handle text;
  candidate   text;
  n           integer := 0;
begin
  base_handle := coalesce(new.raw_user_meta_data->>'handle',
                          lower(regexp_replace(split_part(coalesce(new.email, 'user'), '@', 1), '[^A-Za-z0-9_]', '', 'g')));
  if char_length(base_handle) < 3 then base_handle := 'albo_' || substr(new.id::text, 1, 6); end if;
  candidate := substr(base_handle, 1, 20);
  while exists (select 1 from public.profiles where handle = candidate) loop
    n := n + 1;
    candidate := substr(base_handle, 1, 20 - char_length(n::text)) || n::text;
  end loop;

  insert into public.profiles (id, handle, name)
  values (new.id, candidate, coalesce(new.raw_user_meta_data->>'name', ''));

  insert into public.notification_prefs (user_id) values (new.id);
  insert into public.user_tasks (user_id, task_id) select new.id, id from public.checklist_tasks;
  insert into public.user_stamps (user_id, stamp_id) select new.id, id from public.stamps;
  insert into public.credit_ledger (user_id, delta, reason) values (new.id, 20, 'welcome');
  insert into public.referrals (code, owner_id) values (upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 8)), new.id);
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Storage buckets: covers (public), review photos (private per owner), avatars.
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public) values
  ('covers', 'covers', true),
  ('avatars', 'avatars', true),
  ('review-photos', 'review-photos', false),
  ('imports', 'imports', false)
on conflict (id) do nothing;
