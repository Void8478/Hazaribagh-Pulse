create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_name text,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  category_id uuid references public.categories (id) on delete set null,
  title text not null,
  name text not null,
  description text not null,
  image_url text,
  image_urls text[] not null default '{}',
  address text not null,
  location text,
  phone text,
  opening_hours text,
  price_range text,
  rating double precision not null default 0,
  review_count integer not null default 0,
  is_sponsored boolean not null default false,
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  category_id uuid references public.categories (id) on delete set null,
  title text not null,
  description text not null,
  image_url text,
  category text,
  organizer text,
  location text not null,
  address text,
  date timestamptz not null,
  time text not null,
  is_free boolean not null default false,
  price text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  category_id uuid references public.categories (id) on delete set null,
  title text not null,
  description text not null,
  image_url text,
  location text,
  status text not null default 'published',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists listings_category_id_idx
  on public.listings (category_id);

create index if not exists listings_rating_idx
  on public.listings (rating desc, review_count desc);

create index if not exists listings_created_at_idx
  on public.listings (created_at desc);

create index if not exists events_category_id_idx
  on public.events (category_id);

create index if not exists events_date_idx
  on public.events (date asc);

create index if not exists posts_created_at_idx
  on public.posts (created_at desc);

alter table public.categories enable row level security;
alter table public.listings enable row level security;
alter table public.events enable row level security;
alter table public.posts enable row level security;

create or replace function public.set_content_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at
before update on public.listings
for each row
execute function public.set_content_updated_at();

drop trigger if exists events_set_updated_at on public.events;
create trigger events_set_updated_at
before update on public.events
for each row
execute function public.set_content_updated_at();

drop trigger if exists posts_set_updated_at on public.posts;
create trigger posts_set_updated_at
before update on public.posts
for each row
execute function public.set_content_updated_at();

drop policy if exists "categories_read_all" on public.categories;
create policy "categories_read_all"
on public.categories
for select
to public
using (true);

drop policy if exists "listings_read_all" on public.listings;
create policy "listings_read_all"
on public.listings
for select
to public
using (true);

drop policy if exists "listings_insert_own" on public.listings;
create policy "listings_insert_own"
on public.listings
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "listings_update_own" on public.listings;
create policy "listings_update_own"
on public.listings
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "events_read_all" on public.events;
create policy "events_read_all"
on public.events
for select
to public
using (true);

drop policy if exists "events_insert_own" on public.events;
create policy "events_insert_own"
on public.events
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "events_update_own" on public.events;
create policy "events_update_own"
on public.events
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "posts_read_all" on public.posts;
create policy "posts_read_all"
on public.posts
for select
to public
using (true);

drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own"
on public.posts
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own"
on public.posts
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('content-media', 'content-media', true)
on conflict (id) do nothing;

drop policy if exists "content_media_read_all" on storage.objects;
create policy "content_media_read_all"
on storage.objects
for select
to public
using (bucket_id = 'content-media');

drop policy if exists "content_media_insert_own" on storage.objects;
create policy "content_media_insert_own"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'content-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "content_media_update_own" on storage.objects;
create policy "content_media_update_own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'content-media'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'content-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "content_media_delete_own" on storage.objects;
create policy "content_media_delete_own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'content-media'
  and (storage.foldername(name))[1] = auth.uid()::text
);
