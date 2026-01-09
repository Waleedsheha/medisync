-- Shared (multi-user) access model for facilities + patients
-- Adds hospital_members and updates RLS to allow access for members, not only owner.
--
-- Roles:
-- - owner: creator/administrator of a hospital
-- - admin: can manage hospital content
-- - staff: normal access
-- - doctor: clinician access (treated like staff in RLS)
-- - pharmacist: clinician access (treated like staff in RLS)

create table if not exists public.hospital_members (
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'staff',
  created_at timestamptz not null default now(),
  primary key (hospital_id, user_id)
);

create index if not exists idx_hospital_members_user_id on public.hospital_members(user_id);

alter table public.hospital_members enable row level security;

drop policy if exists "Hospital members: select own memberships" on public.hospital_members;
drop policy if exists "Hospital members: insert self as owner" on public.hospital_members;
drop policy if exists "Hospital members: delete self" on public.hospital_members;

-- Users can read their own memberships
create policy "Hospital members: select own memberships" on public.hospital_members
for select
using (user_id = (select auth.uid()));

-- Allow a user to insert THEIR OWN membership as owner, but only if they own the hospital row
-- (used by the app right after creating a hospital)
create policy "Hospital members: insert self as owner" on public.hospital_members
for insert
with check (
  user_id = (select auth.uid())
  and role = 'owner'
  and exists (
    select 1
    from public.hospitals h
    where h.id = hospital_members.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

-- Allow a user to delete THEIR OWN membership (optional, keeps things simple)
create policy "Hospital members: delete self" on public.hospital_members
for delete
using (user_id = (select auth.uid()));

-- Helper predicate: is member of hospital
-- (We inline this logic in policies to avoid function search_path pitfalls.)

-- ========================
-- Update Hospitals RLS
-- ========================

drop policy if exists "Hospitals: select own" on public.hospitals;
drop policy if exists "Hospitals: insert own" on public.hospitals;
drop policy if exists "Hospitals: update own" on public.hospitals;
drop policy if exists "Hospitals: delete own" on public.hospitals;

create policy "Hospitals: select by membership" on public.hospitals
for select
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
  )
  or owner_id = (select auth.uid())
);

create policy "Hospitals: insert own" on public.hospitals
for insert
with check (owner_id = (select auth.uid()));

create policy "Hospitals: update by membership" on public.hospitals
for update
using (
  owner_id = (select auth.uid())
  or exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin')
  )
)
with check (
  owner_id = (select auth.uid())
  or exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin')
  )
);

create policy "Hospitals: delete by membership" on public.hospitals
for delete
using (
  owner_id = (select auth.uid())
  or exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = hospitals.id
      and m.user_id = (select auth.uid())
      and m.role = 'owner'
  )
);

-- ========================
-- Update Clinics RLS
-- ========================

drop policy if exists "Clinics: select by hospital owner" on public.clinics;
drop policy if exists "Clinics: insert by hospital owner" on public.clinics;
drop policy if exists "Clinics: update by hospital owner" on public.clinics;
drop policy if exists "Clinics: delete by hospital owner" on public.clinics;

create policy "Clinics: select by membership" on public.clinics
for select
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Clinics: insert by membership" on public.clinics
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin')
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
      and m.role in ('owner','admin')
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = clinics.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin')
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
      and m.role = 'owner'
  )
);

-- ========================
-- Update Patients RLS
-- ========================

drop policy if exists "Patients: select by hospital owner" on public.patients;
drop policy if exists "Patients: insert by hospital owner" on public.patients;
drop policy if exists "Patients: update by hospital owner" on public.patients;
drop policy if exists "Patients: delete by hospital owner" on public.patients;

create policy "Patients: select by membership" on public.patients
for select
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Patients: insert by membership" on public.patients
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin','staff')
  )
  and (
    patients.clinic_id is null
    or exists (
      select 1
      from public.clinics c
      where c.id = patients.clinic_id
        and c.hospital_id = patients.hospital_id
    )
  )
);

create policy "Patients: update by membership" on public.patients
for update
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin','staff')
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin','staff')
  )
);

create policy "Patients: delete by membership" on public.patients
for delete
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin')
  )
);

-- ========================
-- Update Lab Range Overrides RLS (if table exists)
-- ========================

-- Optional: only apply these policies if the table exists in your project.
do $$
begin
  if to_regclass('public.lab_range_overrides') is null then
    raise notice 'Skipping lab_range_overrides policies (table does not exist).';
    return;
  end if;

  drop policy if exists "Lab ranges: select by hospital owner" on public.lab_range_overrides;
  drop policy if exists "Lab ranges: upsert by hospital owner" on public.lab_range_overrides;
  drop policy if exists "Lab ranges: delete by hospital owner" on public.lab_range_overrides;

  create policy "Lab ranges: select by membership" on public.lab_range_overrides
  for select
  using (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
    )
  );

  create policy "Lab ranges: upsert by membership" on public.lab_range_overrides
  for insert
  with check (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('owner','admin','staff')
    )
  );

  create policy "Lab ranges: update by membership" on public.lab_range_overrides
  for update
  using (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('owner','admin','staff')
    )
  )
  with check (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('owner','admin','staff')
    )
  );

  create policy "Lab ranges: delete by membership" on public.lab_range_overrides
  for delete
  using (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('owner','admin')
    )
  );
end
$$;

-- ========================
-- Bootstrap: ensure each hospital owner is also a member (owner role)
-- ========================

insert into public.hospital_members(hospital_id, user_id, role)
select h.id, h.owner_id, 'owner'
from public.hospitals h
where h.owner_id is not null
on conflict (hospital_id, user_id) do nothing;
