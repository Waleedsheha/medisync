-- Add explicit clinician roles to hospital_members and update RLS role checks.
--
-- New roles:
-- - doctor
-- - pharmacist
--
-- Note: user previously typed "pharmasist"; we normalize it to "pharmacist" but
-- we keep "pharmasist" allowed in the check constraint for backward-compat.

-- 1) Normalize typo (if any existing rows)
update public.hospital_members
set role = 'pharmacist'
where role = 'pharmasist';

-- 2) Constrain allowed roles (optional but recommended)
-- If you already have a check constraint name that differs, adjust accordingly.
alter table public.hospital_members
  drop constraint if exists hospital_members_role_check;

alter table public.hospital_members
  add constraint hospital_members_role_check
  check (role in ('owner','admin','staff','doctor','pharmacist','pharmasist'));

-- 3) Update Patients RLS: allow doctor/pharmacist like staff

drop policy if exists "Patients: insert by membership" on public.patients;
drop policy if exists "Patients: update by membership" on public.patients;

-- Recreate with expanded role list
create policy "Patients: insert by membership" on public.patients
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin','staff','doctor','pharmacist','pharmasist')
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
      and m.role in ('owner','admin','staff','doctor','pharmacist','pharmasist')
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = patients.hospital_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner','admin','staff','doctor','pharmacist','pharmasist')
  )
);

-- 4) Update Lab Range Overrides RLS similarly (only if the table exists)

do $$
begin
  if to_regclass('public.lab_range_overrides') is null then
    raise notice 'Skipping lab_range_overrides role expansion (table does not exist).';
    return;
  end if;

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
        and m.role in ('owner','admin','staff','doctor','pharmacist','pharmasist')
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
        and m.role in ('owner','admin','staff','doctor','pharmacist','pharmasist')
    )
  )
  with check (
    exists (
      select 1
      from public.hospital_members m
      where m.hospital_id = lab_range_overrides.hospital_id
        and m.user_id = (select auth.uid())
        and m.role in ('owner','admin','staff','doctor','pharmacist','pharmasist')
    )
  );
end
$$;
