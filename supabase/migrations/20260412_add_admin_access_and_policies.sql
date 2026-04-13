alter table public.profiles
  add column if not exists is_admin boolean not null default false;

create or replace function public.is_admin(user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = user_id
      and is_admin = true
  );
$$;

drop policy if exists "categories_admin_insert" on public.categories;
create policy "categories_admin_insert"
on public.categories
for insert
to authenticated
with check (public.is_admin(auth.uid()));

drop policy if exists "categories_admin_update" on public.categories;
create policy "categories_admin_update"
on public.categories
for update
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists "categories_admin_delete" on public.categories;
create policy "categories_admin_delete"
on public.categories
for delete
to authenticated
using (public.is_admin(auth.uid()));

drop policy if exists "listings_admin_insert" on public.listings;
create policy "listings_admin_insert"
on public.listings
for insert
to authenticated
with check (public.is_admin(auth.uid()));

drop policy if exists "listings_admin_update" on public.listings;
create policy "listings_admin_update"
on public.listings
for update
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists "listings_admin_delete" on public.listings;
create policy "listings_admin_delete"
on public.listings
for delete
to authenticated
using (public.is_admin(auth.uid()));

drop policy if exists "events_admin_insert" on public.events;
create policy "events_admin_insert"
on public.events
for insert
to authenticated
with check (public.is_admin(auth.uid()));

drop policy if exists "events_admin_update" on public.events;
create policy "events_admin_update"
on public.events
for update
to authenticated
using (public.is_admin(auth.uid()))
with check (public.is_admin(auth.uid()));

drop policy if exists "events_admin_delete" on public.events;
create policy "events_admin_delete"
on public.events
for delete
to authenticated
using (public.is_admin(auth.uid()));
