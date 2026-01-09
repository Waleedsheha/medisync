-- Create core facility + patient tables
-- Tables: hospitals, clinics, patients
-- Notes:
-- - Each hospital is owned by a single Supabase user (auth.users)
-- - Clinics belong to a hospital (can represent a clinic/unit/ICU/ward)
-- - Patients belong to a hospital and optionally a clinic
-- - RLS restricts access to the owning hospital user

-- updated_at trigger helper (self-contained, avoids relying on other migrations)
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- lock down search_path to avoid mutable-search-path lints
alter function public.set_updated_at() set search_path = public;


-- 1) Hospitals
create table if not exists public.hospitals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint hospitals_owner_name_unique unique (owner_id, name)
);

create index if not exists idx_hospitals_owner_id on public.hospitals(owner_id);

alter table public.hospitals enable row level security;

drop policy if exists "Hospitals: select own" on public.hospitals;
drop policy if exists "Hospitals: insert own" on public.hospitals;
drop policy if exists "Hospitals: update own" on public.hospitals;
drop policy if exists "Hospitals: delete own" on public.hospitals;

create policy "Hospitals: select own" on public.hospitals
for select
using (owner_id = (select auth.uid()));

create policy "Hospitals: insert own" on public.hospitals
for insert
with check (owner_id = (select auth.uid()));

create policy "Hospitals: update own" on public.hospitals
for update
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "Hospitals: delete own" on public.hospitals
for delete
using (owner_id = (select auth.uid()));

drop trigger if exists trg_hospitals_set_updated_at on public.hospitals;
create trigger trg_hospitals_set_updated_at
before update on public.hospitals
for each row execute function public.set_updated_at();


-- 2) Clinics (can represent units/ICU/ward/clinic)
create table if not exists public.clinics (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  name text not null,
  kind text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint clinics_hospital_name_unique unique (hospital_id, name)
);

create index if not exists idx_clinics_hospital_id on public.clinics(hospital_id);

alter table public.clinics enable row level security;

drop policy if exists "Clinics: select by hospital owner" on public.clinics;
drop policy if exists "Clinics: insert by hospital owner" on public.clinics;
drop policy if exists "Clinics: update by hospital owner" on public.clinics;
drop policy if exists "Clinics: delete by hospital owner" on public.clinics;

create policy "Clinics: select by hospital owner" on public.clinics
for select
using (
  exists (
    select 1 from public.hospitals h
    where h.id = clinics.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Clinics: insert by hospital owner" on public.clinics
for insert
with check (
  exists (
    select 1 from public.hospitals h
    where h.id = clinics.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Clinics: update by hospital owner" on public.clinics
for update
using (
  exists (
    select 1 from public.hospitals h
    where h.id = clinics.hospital_id
      and h.owner_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.hospitals h
    where h.id = clinics.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Clinics: delete by hospital owner" on public.clinics
for delete
using (
  exists (
    select 1 from public.hospitals h
    where h.id = clinics.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

drop trigger if exists trg_clinics_set_updated_at on public.clinics;
create trigger trg_clinics_set_updated_at
before update on public.clinics
for each row execute function public.set_updated_at();


-- 3) Patients
create table if not exists public.patients (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  clinic_id uuid references public.clinics(id) on delete set null,

  mrn text not null,
  name text not null default '',
  phone text,
  age text,
  gender text,

  admission_date date,
  discharge_date date,

  -- store rich patient details without creating many tables yet
  details jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint patients_hospital_mrn_unique unique (hospital_id, mrn)
);

create index if not exists idx_patients_hospital_id on public.patients(hospital_id);
create index if not exists idx_patients_clinic_id on public.patients(clinic_id);

alter table public.patients enable row level security;

drop policy if exists "Patients: select by hospital owner" on public.patients;
drop policy if exists "Patients: insert by hospital owner" on public.patients;
drop policy if exists "Patients: update by hospital owner" on public.patients;
drop policy if exists "Patients: delete by hospital owner" on public.patients;

create policy "Patients: select by hospital owner" on public.patients
for select
using (
  exists (
    select 1 from public.hospitals h
    where h.id = patients.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Patients: insert by hospital owner" on public.patients
for insert
with check (
  exists (
    select 1 from public.hospitals h
    where h.id = patients.hospital_id
      and h.owner_id = (select auth.uid())
  )
  and (
    patients.clinic_id is null
    or exists (
      select 1
      from public.clinics c
      join public.hospitals h on h.id = c.hospital_id
      where c.id = patients.clinic_id
        and c.hospital_id = patients.hospital_id
        and h.owner_id = (select auth.uid())
    )
  )
);

create policy "Patients: update by hospital owner" on public.patients
for update
using (
  exists (
    select 1 from public.hospitals h
    where h.id = patients.hospital_id
      and h.owner_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.hospitals h
    where h.id = patients.hospital_id
      and h.owner_id = (select auth.uid())
  )
  and (
    patients.clinic_id is null
    or exists (
      select 1
      from public.clinics c
      join public.hospitals h on h.id = c.hospital_id
      where c.id = patients.clinic_id
        and c.hospital_id = patients.hospital_id
        and h.owner_id = (select auth.uid())
    )
  )
);

create policy "Patients: delete by hospital owner" on public.patients
for delete
using (
  exists (
    select 1 from public.hospitals h
    where h.id = patients.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

drop trigger if exists trg_patients_set_updated_at on public.patients;
create trigger trg_patients_set_updated_at
before update on public.patients
for each row execute function public.set_updated_at();
