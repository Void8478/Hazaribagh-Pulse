create or replace function public.set_discussion_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.post_comments (
  id bigserial primary key,
  post_id bigint not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  text text not null check (char_length(trim(text)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists post_comments_post_id_idx
  on public.post_comments (post_id, created_at desc);

create index if not exists post_comments_user_id_idx
  on public.post_comments (user_id);

alter table public.post_comments enable row level security;

drop trigger if exists post_comments_set_updated_at on public.post_comments;
create trigger post_comments_set_updated_at
before update on public.post_comments
for each row
execute function public.set_discussion_updated_at();

drop policy if exists "post_comments_read_all" on public.post_comments;
create policy "post_comments_read_all"
on public.post_comments
for select
to public
using (true);

drop policy if exists "post_comments_insert_own" on public.post_comments;
create policy "post_comments_insert_own"
on public.post_comments
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "post_comments_update_own" on public.post_comments;
create policy "post_comments_update_own"
on public.post_comments
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "post_comments_delete_own" on public.post_comments;
create policy "post_comments_delete_own"
on public.post_comments
for delete
to authenticated
using (auth.uid() = user_id);

create table if not exists public.event_comments (
  id bigserial primary key,
  event_id bigint not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  text text not null check (char_length(trim(text)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists event_comments_event_id_idx
  on public.event_comments (event_id, created_at desc);

create index if not exists event_comments_user_id_idx
  on public.event_comments (user_id);

alter table public.event_comments enable row level security;

drop trigger if exists event_comments_set_updated_at on public.event_comments;
create trigger event_comments_set_updated_at
before update on public.event_comments
for each row
execute function public.set_discussion_updated_at();

drop policy if exists "event_comments_read_all" on public.event_comments;
create policy "event_comments_read_all"
on public.event_comments
for select
to public
using (true);

drop policy if exists "event_comments_insert_own" on public.event_comments;
create policy "event_comments_insert_own"
on public.event_comments
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "event_comments_update_own" on public.event_comments;
create policy "event_comments_update_own"
on public.event_comments
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "event_comments_delete_own" on public.event_comments;
create policy "event_comments_delete_own"
on public.event_comments
for delete
to authenticated
using (auth.uid() = user_id);

create table if not exists public.reviews (
  id bigserial primary key,
  listing_id bigint not null references public.listings (id) on delete cascade,
  user_id uuid references public.profiles (id) on delete cascade,
  rating numeric(2, 1) not null default 0,
  text text not null default '',
  pros text not null default '',
  cons text not null default '',
  pricing_tip text not null default '',
  best_time_to_visit text not null default '',
  image_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.reviews
  add column if not exists user_id uuid references public.profiles (id) on delete cascade,
  add column if not exists rating numeric(2, 1) not null default 0,
  add column if not exists text text not null default '',
  add column if not exists pros text not null default '',
  add column if not exists cons text not null default '',
  add column if not exists pricing_tip text not null default '',
  add column if not exists best_time_to_visit text not null default '',
  add column if not exists image_urls text[] not null default '{}',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'reviews'
      and column_name = 'listing_id'
      and data_type <> 'bigint'
  ) then
    execute '
      alter table public.reviews
      alter column listing_id
      type bigint
      using nullif(listing_id::text, '''')::bigint
    ';
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'reviews'
      and column_name = 'author_id'
  ) then
    execute '
      update public.reviews
      set user_id = coalesce(
        user_id,
        case
          when nullif(author_id::text, '''') is null then null
          when author_id::text !~* ''^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'' then null
          else author_id::uuid
        end
      )
      where user_id is null
    ';
  end if;
end;
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'reviews'
      and column_name = 'timestamp'
  ) then
    execute '
      update public.reviews
      set created_at = coalesce(created_at, timestamp),
          updated_at = coalesce(updated_at, timestamp)
      where timestamp is not null
    ';
  end if;
end;
$$;

create index if not exists reviews_listing_id_idx
  on public.reviews (listing_id, created_at desc);

create index if not exists reviews_user_id_idx
  on public.reviews (user_id);

alter table public.reviews enable row level security;

drop trigger if exists reviews_set_updated_at on public.reviews;
create trigger reviews_set_updated_at
before update on public.reviews
for each row
execute function public.set_discussion_updated_at();

drop policy if exists "reviews_read_all" on public.reviews;
create policy "reviews_read_all"
on public.reviews
for select
to public
using (true);

drop policy if exists "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own"
on public.reviews
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "reviews_update_own" on public.reviews;
create policy "reviews_update_own"
on public.reviews
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "reviews_delete_own" on public.reviews;
create policy "reviews_delete_own"
on public.reviews
for delete
to authenticated
using (auth.uid() = user_id);
