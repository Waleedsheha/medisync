-- Cleanup: remove legacy owner-based RLS policies after moving to hospital_members.
--
-- This keeps access control purely membership-driven.

-- ========================
-- Hospitals
-- ========================

drop policy if exists "Hospitals: select own" on public.hospitals;
drop policy if exists "Hospitals: update own" on public.hospitals;
drop policy if exists "Hospitals: delete own" on public.hospitals;

-- Keep "Hospitals: insert own" as-is (creator sets owner_id), but access is via membership.

-- ========================
-- Clinics
-- ========================

drop policy if exists "Clinics: select by hospital owner" on public.clinics;
drop policy if exists "Clinics: insert by hospital owner" on public.clinics;
drop policy if exists "Clinics: update by hospital owner" on public.clinics;
drop policy if exists "Clinics: delete by hospital owner" on public.clinics;

-- ========================
-- Patients
-- ========================

drop policy if exists "Patients: select by hospital owner" on public.patients;
drop policy if exists "Patients: insert by hospital owner" on public.patients;
drop policy if exists "Patients: update by hospital owner" on public.patients;
drop policy if exists "Patients: delete by hospital owner" on public.patients;

-- Tighten membership write policies to remove owner/admin roles if they still exist.
-- (Roles allowed: staff/doctor/pharmacist)

drop policy if exists "Patients: insert by membership" on public.patients;
drop policy if exists "Patients: update by membership" on public.patients;

create policy "Patients: insert by membership" on public.patients
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('staff','doctor','pharmacist','pharmasist')
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
      and m.role in ('staff','doctor','pharmacist','pharmasist')
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('staff','doctor','pharmacist','pharmasist')
  )
);

-- ========================
-- Lab ranges (optional)
-- ========================

do $$
begin
  if to_regclass('public.lab_range_overrides') is null then
    raise notice 'Skipping lab_range_overrides cleanup (table does not exist).';
    return;
  end if;

  drop policy if exists "Lab ranges: select by hospital owner" on public.lab_range_overrides;
  drop policy if exists "Lab ranges: upsert by hospital owner" on public.lab_range_overrides;
  drop policy if exists "Lab ranges: delete by hospital owner" on public.lab_range_overrides;

  -- Recreate insert/update policies to remove owner/admin roles if present.
  drop policy if exists "Lab ranges: upsert by membership" on public.lab_range_overrides;
  drop policy if exists "Lab ranges: update by membership" on public.lab_range_overrides;

  create policy "Lab ranges: upsert by membership" on public.lab_range_overrides
  for insert
  with check (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('staff','doctor','pharmacist','pharmasist')
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
        and m.role in ('staff','doctor','pharmacist','pharmasist')
    )
  )
  with check (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('staff','doctor','pharmacist','pharmasist')
    )
  );
end
$$;
