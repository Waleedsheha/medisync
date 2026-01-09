-- Lab range overrides stored in Supabase (with RLS)
-- Per hospital + clinic (unit) scope

create table if not exists public.lab_range_overrides (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references public.hospitals(id) on delete cascade,
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  overrides jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint lab_range_overrides_unique unique (hospital_id, clinic_id)
);

create index if not exists idx_lab_range_overrides_hospital_id on public.lab_range_overrides(hospital_id);
create index if not exists idx_lab_range_overrides_clinic_id on public.lab_range_overrides(clinic_id);

alter table public.lab_range_overrides enable row level security;

drop policy if exists "Lab ranges: select by hospital owner" on public.lab_range_overrides;
drop policy if exists "Lab ranges: upsert by hospital owner" on public.lab_range_overrides;
drop policy if exists "Lab ranges: delete by hospital owner" on public.lab_range_overrides;

create policy "Lab ranges: select by hospital owner" on public.lab_range_overrides
for select
using (
  exists (
    select 1 from public.hospitals h
    where h.id = lab_range_overrides.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Lab ranges: upsert by hospital owner" on public.lab_range_overrides
for insert
with check (
  exists (
    select 1
    from public.hospitals h
    join public.clinics c on c.hospital_id = h.id
    where h.id = lab_range_overrides.hospital_id
      and c.id = lab_range_overrides.clinic_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Lab ranges: upsert by hospital owner" on public.lab_range_overrides
for update
using (
  exists (
    select 1
    from public.hospitals h
    where h.id = lab_range_overrides.hospital_id
      and h.owner_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.hospitals h
    join public.clinics c on c.hospital_id = h.id
    where h.id = lab_range_overrides.hospital_id
      and c.id = lab_range_overrides.clinic_id
      and h.owner_id = (select auth.uid())
  )
);

create policy "Lab ranges: delete by hospital owner" on public.lab_range_overrides
for delete
using (
  exists (
    select 1 from public.hospitals h
    where h.id = lab_range_overrides.hospital_id
      and h.owner_id = (select auth.uid())
  )
);

drop trigger if exists trg_lab_range_overrides_set_updated_at on public.lab_range_overrides;
create trigger trg_lab_range_overrides_set_updated_at
before update on public.lab_range_overrides
for each row execute function public.set_updated_at();
