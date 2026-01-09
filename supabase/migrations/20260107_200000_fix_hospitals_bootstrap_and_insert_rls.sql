-- Fix: allow authenticated users to create hospitals and immediately become members.
--
-- Symptoms addressed:
-- - PostgrestException: new row violates row-level security policy for table "hospitals"
-- - Newly created hospitals/departments appear "deleted" after navigation (remote reload shows none)
--
-- Approach:
-- 1) Re-assert a safe INSERT policy on hospitals (owner_id must match auth.uid()).
-- 2) Add an AFTER INSERT trigger that inserts the creator into hospital_members as 'staff'.
--    This makes "Hospitals: select by membership" work immediately after creation.

alter table public.hospitals enable row level security;

drop policy if exists "Hospitals: insert own" on public.hospitals;
create policy "Hospitals: insert own" on public.hospitals
for insert
with check (
  (select auth.uid()) is not null
  and owner_id = (select auth.uid())
);

create or replace function public.add_hospital_creator_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Ensure the creator can see/manage the hospital via membership-based RLS.
  insert into public.hospital_members (hospital_id, user_id, role)
  values (new.id, new.owner_id, 'staff')
  on conflict (hospital_id, user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_hospitals_add_creator_membership on public.hospitals;
create trigger trg_hospitals_add_creator_membership
after insert on public.hospitals
for each row execute function public.add_hospital_creator_membership();

-- Backfill: ensure existing hospital owners are members too.
-- This is important because current hospital SELECT policy is membership-based.
insert into public.hospital_members (hospital_id, user_id, role)
select h.id, h.owner_id, 'staff'
from public.hospitals h
where h.owner_id is not null
on conflict (hospital_id, user_id) do nothing;
