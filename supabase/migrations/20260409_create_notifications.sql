create extension if not exists pgcrypto;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles (id) on delete cascade,
  actor_user_id uuid not null references public.profiles (id) on delete cascade,
  type text not null check (type in ('like', 'comment', 'review', 'bookmark', 'event_interaction')),
  content_id text not null,
  content_type text not null check (content_type in ('post', 'place', 'event')),
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_recipient_created_at_idx
  on public.notifications (recipient_user_id, created_at desc);

create index if not exists notifications_recipient_is_read_idx
  on public.notifications (recipient_user_id, is_read, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "notifications_read_own" on public.notifications;
create policy "notifications_read_own"
on public.notifications
for select
to authenticated
using (auth.uid() = recipient_user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
on public.notifications
for update
to authenticated
using (auth.uid() = recipient_user_id)
with check (auth.uid() = recipient_user_id);

create or replace function public.notification_actor_name(actor_id uuid)
returns text
language sql
stable
set search_path = public
as $$
  select coalesce(
    nullif(trim(p.full_name), ''),
    case
      when nullif(trim(p.username), '') is not null then '@' || trim(p.username)
      else null
    end,
    'Someone'
  )
  from public.profiles p
  where p.id = actor_id
$$;

create or replace function public.notification_recipient_for_content(
  target_content_type text,
  target_content_id text
)
returns uuid
language plpgsql
stable
set search_path = public
as $$
declare
  owner_id uuid;
begin
  case target_content_type
    when 'post' then
      select p.user_id
      into owner_id
      from public.posts p
      where p.id::text = target_content_id;
    when 'place' then
      select l.user_id
      into owner_id
      from public.listings l
      where l.id::text = target_content_id;
    when 'event' then
      select e.user_id
      into owner_id
      from public.events e
      where e.id::text = target_content_id;
    else
      owner_id := null;
  end case;

  return owner_id;
end;
$$;

create or replace function public.insert_notification(
  target_recipient_user_id uuid,
  target_actor_user_id uuid,
  notification_type text,
  target_content_id text,
  target_content_type text,
  notification_title text,
  notification_body text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_recipient_user_id is null
     or target_actor_user_id is null
     or target_recipient_user_id = target_actor_user_id then
    return;
  end if;

  insert into public.notifications (
    recipient_user_id,
    actor_user_id,
    type,
    content_id,
    content_type,
    title,
    body
  )
  values (
    target_recipient_user_id,
    target_actor_user_id,
    notification_type,
    target_content_id,
    target_content_type,
    notification_title,
    notification_body
  );
end;
$$;

create or replace function public.notify_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_id uuid;
  actor_name text;
  content_label text;
begin
  recipient_id := public.notification_recipient_for_content(new.content_type, new.content_id);
  actor_name := public.notification_actor_name(new.user_id);
  content_label := case new.content_type
    when 'post' then 'post'
    when 'place' then 'place'
    when 'event' then 'event'
    else 'item'
  end;

  if recipient_id is null or recipient_id = new.user_id then
    return new;
  end if;

  if exists (
    select 1
    from public.notifications n
    where n.recipient_user_id = recipient_id
      and n.actor_user_id = new.user_id
      and n.type = 'like'
      and n.content_id = new.content_id
      and n.content_type = new.content_type
  ) then
    return new;
  end if;

  perform public.insert_notification(
    recipient_id,
    new.user_id,
    'like',
    new.content_id,
    new.content_type,
    actor_name,
    actor_name || ' liked your ' || content_label || '.'
  );

  return new;
end;
$$;

create or replace function public.notify_post_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_id uuid;
  actor_name text;
begin
  select p.user_id
  into recipient_id
  from public.posts p
  where p.id = new.post_id;

  actor_name := public.notification_actor_name(new.user_id);

  perform public.insert_notification(
    recipient_id,
    new.user_id,
    'comment',
    new.post_id::text,
    'post',
    actor_name,
    actor_name || ' commented on your post.'
  );

  return new;
end;
$$;

create or replace function public.notify_event_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_id uuid;
  actor_name text;
begin
  select e.user_id
  into recipient_id
  from public.events e
  where e.id = new.event_id;

  actor_name := public.notification_actor_name(new.user_id);

  perform public.insert_notification(
    recipient_id,
    new.user_id,
    'comment',
    new.event_id::text,
    'event',
    actor_name,
    actor_name || ' commented on your event.'
  );

  return new;
end;
$$;

create or replace function public.notify_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipient_id uuid;
  actor_name text;
begin
  select l.user_id
  into recipient_id
  from public.listings l
  where l.id = new.listing_id;

  actor_name := public.notification_actor_name(new.user_id);

  perform public.insert_notification(
    recipient_id,
    new.user_id,
    'review',
    new.listing_id::text,
    'place',
    actor_name,
    actor_name || ' reviewed your place.'
  );

  return new;
end;
$$;

do $$
begin
  if to_regclass('public.user_likes') is not null then
    execute 'drop trigger if exists user_likes_notify_insert on public.user_likes';
    execute '
      create trigger user_likes_notify_insert
      after insert on public.user_likes
      for each row
      execute function public.notify_like()
    ';
  end if;

  if to_regclass('public.post_comments') is not null then
    execute 'drop trigger if exists post_comments_notify_insert on public.post_comments';
    execute '
      create trigger post_comments_notify_insert
      after insert on public.post_comments
      for each row
      execute function public.notify_post_comment()
    ';
  end if;

  if to_regclass('public.event_comments') is not null then
    execute 'drop trigger if exists event_comments_notify_insert on public.event_comments';
    execute '
      create trigger event_comments_notify_insert
      after insert on public.event_comments
      for each row
      execute function public.notify_event_comment()
    ';
  end if;

  if to_regclass('public.reviews') is not null then
    execute 'drop trigger if exists reviews_notify_insert on public.reviews';
    execute '
      create trigger reviews_notify_insert
      after insert on public.reviews
      for each row
      execute function public.notify_review()
    ';
  end if;
end;
$$;
