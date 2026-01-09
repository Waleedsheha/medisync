-- Hospital hierarchy (separate from global Clinics feature)
-- Flow: Hospital -> Department -> Room -> Patients
--
-- Notes:
-- - `public.clinics` remains for the standalone Clinics pathway.
-- - Hospital navigation uses these new tables.
-- - Patients in hospital hierarchy use `patients.room_id`.

-- 1) Departments
create table if not exists public.departments (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  name text not null,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint departments_hospital_name_unique unique (hospital_id, name)
);

create index if not exists idx_departments_hospital_id on public.departments(hospital_id);
create index if not exists idx_departments_archived_at on public.departments(archived_at);

alter table public.departments enable row level security;

-- 2) Rooms
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  department_id uuid not null references public.departments(id) on delete cascade,
  name text not null,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Keep resolution simple in-app: room names are unique per hospital
  constraint rooms_hospital_name_unique unique (hospital_id, name)
);

create index if not exists idx_rooms_hospital_id on public.rooms(hospital_id);
create index if not exists idx_rooms_department_id on public.rooms(department_id);
create index if not exists idx_rooms_archived_at on public.rooms(archived_at);

alter table public.rooms enable row level security;

-- 3) Patients: add room_id (keep clinic_id for Clinics pathway)
alter table public.patients
  add column if not exists room_id uuid references public.rooms(id) on delete set null;

create index if not exists idx_patients_room_id on public.patients(room_id);

-- 4) updated_at triggers
-- (relies on public.set_updated_at() existing; created earlier in this project)
drop trigger if exists trg_departments_set_updated_at on public.departments;
create trigger trg_departments_set_updated_at
before update on public.departments
for each row execute function public.set_updated_at();

drop trigger if exists trg_rooms_set_updated_at on public.rooms;
create trigger trg_rooms_set_updated_at
before update on public.rooms
for each row execute function public.set_updated_at();

-- 5) RLS (membership-based)
-- Departments
drop policy if exists "Departments: select by membership" on public.departments;
drop policy if exists "Departments: insert by membership" on public.departments;
drop policy if exists "Departments: update by membership" on public.departments;
drop policy if exists "Departments: delete by membership" on public.departments;

create policy "Departments: select by membership" on public.departments
for select
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = departments.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Departments: insert by membership" on public.departments
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = departments.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Departments: update by membership" on public.departments
for update
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = departments.hospital_id
      and m.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = departments.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Departments: delete by membership" on public.departments
for delete
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = departments.hospital_id
      and m.user_id = (select auth.uid())
  )
);

-- Rooms
drop policy if exists "Rooms: select by membership" on public.rooms;
drop policy if exists "Rooms: insert by membership" on public.rooms;
drop policy if exists "Rooms: update by membership" on public.rooms;
drop policy if exists "Rooms: delete by membership" on public.rooms;

create policy "Rooms: select by membership" on public.rooms
for select
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = rooms.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Rooms: insert by membership" on public.rooms
for insert
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = rooms.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Rooms: update by membership" on public.rooms
for update
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = rooms.hospital_id
      and m.user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = rooms.hospital_id
      and m.user_id = (select auth.uid())
  )
);

create policy "Rooms: delete by membership" on public.rooms
for delete
using (
  exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = rooms.hospital_id
      and m.user_id = (select auth.uid())
  )
);
