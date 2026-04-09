create or replace function public.delete_account_owned_data(target_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  post_ids text[] := '{}'::text[];
  listing_ids text[] := '{}'::text[];
  event_ids text[] := '{}'::text[];
begin
  if target_user_id is null then
    raise exception 'target_user_id is required';
  end if;

  if to_regclass('public.posts') is not null then
    execute '
      select coalesce(array_agg(id::text), ''{}''::text[])
      from public.posts
      where user_id = $1
    '
    into post_ids
    using target_user_id;
  end if;

  if to_regclass('public.listings') is not null then
    execute '
      select coalesce(array_agg(id::text), ''{}''::text[])
      from public.listings
      where user_id = $1
    '
    into listing_ids
    using target_user_id;
  end if;

  if to_regclass('public.events') is not null then
    execute '
      select coalesce(array_agg(id::text), ''{}''::text[])
      from public.events
      where user_id = $1
    '
    into event_ids
    using target_user_id;
  end if;

  if to_regclass('public.notifications') is not null then
    execute '
      delete from public.notifications
      where recipient_user_id = $1 or actor_user_id = $1
    '
    using target_user_id;

    if coalesce(array_length(post_ids, 1), 0) > 0 then
      execute '
        delete from public.notifications
        where content_type = ''post'' and content_id = any($1)
      '
      using post_ids;
    end if;

    if coalesce(array_length(listing_ids, 1), 0) > 0 then
      execute '
        delete from public.notifications
        where content_type = ''place'' and content_id = any($1)
      '
      using listing_ids;
    end if;

    if coalesce(array_length(event_ids, 1), 0) > 0 then
      execute '
        delete from public.notifications
        where content_type = ''event'' and content_id = any($1)
      '
      using event_ids;
    end if;
  end if;

  if to_regclass('public.user_likes') is not null then
    execute 'delete from public.user_likes where user_id = $1'
    using target_user_id;

    if coalesce(array_length(post_ids, 1), 0) > 0 then
      execute '
        delete from public.user_likes
        where content_type = ''post'' and content_id = any($1)
      '
      using post_ids;
    end if;

    if coalesce(array_length(listing_ids, 1), 0) > 0 then
      execute '
        delete from public.user_likes
        where content_type = ''place'' and content_id = any($1)
      '
      using listing_ids;
    end if;

    if coalesce(array_length(event_ids, 1), 0) > 0 then
      execute '
        delete from public.user_likes
        where content_type = ''event'' and content_id = any($1)
      '
      using event_ids;
    end if;
  end if;

  if to_regclass('public.user_bookmarks') is not null then
    execute 'delete from public.user_bookmarks where user_id = $1'
    using target_user_id;

    if coalesce(array_length(post_ids, 1), 0) > 0 then
      execute '
        delete from public.user_bookmarks
        where content_type = ''post'' and content_id = any($1)
      '
      using post_ids;
    end if;

    if coalesce(array_length(listing_ids, 1), 0) > 0 then
      execute '
        delete from public.user_bookmarks
        where content_type = ''place'' and content_id = any($1)
      '
      using listing_ids;
    end if;

    if coalesce(array_length(event_ids, 1), 0) > 0 then
      execute '
        delete from public.user_bookmarks
        where content_type = ''event'' and content_id = any($1)
      '
      using event_ids;
    end if;
  end if;

  if to_regclass('public.post_comments') is not null then
    execute 'delete from public.post_comments where user_id = $1'
    using target_user_id;

    if coalesce(array_length(post_ids, 1), 0) > 0 then
      execute '
        delete from public.post_comments
        where post_id::text = any($1)
      '
      using post_ids;
    end if;
  end if;

  if to_regclass('public.event_comments') is not null then
    execute 'delete from public.event_comments where user_id = $1'
    using target_user_id;

    if coalesce(array_length(event_ids, 1), 0) > 0 then
      execute '
        delete from public.event_comments
        where event_id::text = any($1)
      '
      using event_ids;
    end if;
  end if;

  if to_regclass('public.reviews') is not null then
    execute 'delete from public.reviews where user_id = $1'
    using target_user_id;

    if coalesce(array_length(listing_ids, 1), 0) > 0 then
      execute '
        delete from public.reviews
        where listing_id::text = any($1)
      '
      using listing_ids;
    end if;
  end if;

  if to_regclass('public.posts') is not null then
    execute 'delete from public.posts where user_id = $1'
    using target_user_id;
  end if;

  if to_regclass('public.events') is not null then
    execute 'delete from public.events where user_id = $1'
    using target_user_id;
  end if;

  if to_regclass('public.listings') is not null then
    execute 'delete from public.listings where user_id = $1'
    using target_user_id;
  end if;

  if to_regclass('public.profiles') is not null then
    execute 'delete from public.profiles where id = $1'
    using target_user_id;
  end if;

  return jsonb_build_object(
    'deleted_user_id', target_user_id,
    'post_count', coalesce(array_length(post_ids, 1), 0),
    'listing_count', coalesce(array_length(listing_ids, 1), 0),
    'event_count', coalesce(array_length(event_ids, 1), 0)
  );
end;
$$;

revoke all on function public.delete_account_owned_data(uuid) from public;
revoke all on function public.delete_account_owned_data(uuid) from anon;
revoke all on function public.delete_account_owned_data(uuid) from authenticated;
grant execute on function public.delete_account_owned_data(uuid) to service_role;
