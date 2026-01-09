-- Remove owner/admin roles from hospital_members.
-- Permissions become membership-based only (roles are informational).

-- 1) Normalize legacy roles into staff
update public.hospital_members
set role = 'staff'
where role in ('owner', 'admin');

-- 2) Normalize typo (if any)
update public.hospital_members
set role = 'pharmacist'
where role = 'pharmasist';

-- 3) Constrain allowed roles
alter table public.hospital_members
  drop constraint if exists hospital_members_role_check;

alter table public.hospital_members
  add constraint hospital_members_role_check
  check (role in ('staff','doctor','pharmacist','pharmasist'));

-- 4) hospital_members policies
-- Replace the insert policy so membership can be created when:
-- - you created the hospital (h.owner_id = auth.uid()) OR
-- - you're already a member of that hospital (to let members add other members if needed)

drop policy if exists "Hospital members: insert self as owner" on public.hospital_members;
drop policy if exists "Hospital members: insert by membership" on public.hospital_members;

create policy "Hospital members: insert by membership" on public.hospital_members
for insert
with check (
  -- caller must be authenticated
  (select auth.uid()) is not null
  and (
    -- bootstrap: hospital creator can add members
    exists (
      select 1
      from public.hospitals h
      where h.id = hospital_members.hospital_id
        and h.owner_id = (select auth.uid())
    )
    or
    -- any existing member can add other members (no admin/owner concept)
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = hospital_members.hospital_id
        and m.user_id = (select auth.uid())
    )
  )
);

-- 5) Hospitals policies: any member can update/delete

drop policy if exists "Hospitals: select by membership" on public.hospitals;
drop policy if exists "Hospitals: update by membership" on public.hospitals;
drop policy if exists "Hospitals: delete by membership" on public.hospitals;

create policy "Hospitals: select by membership" on public.hospitals
for select
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
  )
);

create policy "Hospitals: update by membership" on public.hospitals
for update
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
  )
);

create policy "Hospitals: delete by membership" on public.hospitals
for delete
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
  )
);

-- 6) Clinics policies: any member can insert/update/delete

drop policy if exists "Clinics: insert by membership" on public.clinics;
drop policy if exists "Clinics: update by membership" on public.clinics;
drop policy if exists "Clinics: delete by membership" on public.clinics;

create policy "Clinics: insert by membership" on public.clinics
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Clinics: update by membership" on public.clinics
for update
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Clinics: delete by membership" on public.clinics
for delete
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
  )
);

-- 7) Patients delete policy: allow any member

drop policy if exists "Patients: delete by membership" on public.patients;

create policy "Patients: delete by membership" on public.patients
for delete
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
  )
);

-- 8) Lab ranges delete policy: allow any member (only if table exists)

do $$
begin
  if to_regclass('public.lab_range_overrides') is null then
    raise notice 'Skipping lab_range_overrides delete policy update (table does not exist).';
    return;
  end if;

  drop policy if exists "Lab ranges: delete by membership" on public.lab_range_overrides;

  create policy "Lab ranges: delete by membership" on public.lab_range_overrides
  for delete
  using (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
    )
  );
end
$$;
