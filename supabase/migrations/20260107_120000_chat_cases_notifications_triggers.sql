-- Adds realtime-friendly author_name on cases and creates notification triggers

-- ==========================================
-- 1) CASES: denormalize author name for realtime feeds
-- ==========================================
alter table public.cases
add column if not exists author_name text;

create or replace function public.set_case_author_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.author_name is null then
    select p.full_name
      into new.author_name
    from public.profiles p
    where p.id = new.author_id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_set_case_author_name on public.cases;
create trigger trg_set_case_author_name
before insert on public.cases
for each row
execute function public.set_case_author_name();

-- ==========================================
-- 2) NOTIFICATIONS: create on new chat messages
-- ==========================================
create or replace function public.notify_on_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Notify all other members of the conversation
  insert into public.notifications (user_id, title, body, read)
  select cm.user_id,
         'New message',
         left(new.body, 180),
         false
    from public.conversation_members cm
   where cm.conversation_id = new.conversation_id
     and cm.user_id <> new.sender_id;

  return new;
end;
$$;

drop trigger if exists trg_notify_on_new_message on public.messages;
create trigger trg_notify_on_new_message
after insert on public.messages
for each row
execute function public.notify_on_new_message();

-- ==========================================
-- 3) NOTIFICATIONS: create on new case posted
-- ==========================================
create or replace function public.notify_on_new_case()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  t text;
  b text;
begin
  t := 'New case posted';
  b := left(coalesce(new.title, 'A new case was posted'), 180);

  -- Notify everyone except the author.
  insert into public.notifications (user_id, title, body, read)
  select p.id,
         t,
         b,
         false
    from public.profiles p
   where p.id <> new.author_id;

  return new;
end;
$$;

drop trigger if exists trg_notify_on_new_case on public.cases;
create trigger trg_notify_on_new_case
after insert on public.cases
for each row
execute function public.notify_on_new_case();
