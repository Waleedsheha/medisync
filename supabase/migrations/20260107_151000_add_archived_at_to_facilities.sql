-- Adds soft-archive support for facilities.
-- Used by hierarchy delete (soft-archive) and the Archive screen.

alter table public.hospitals
  add column if not exists archived_at timestamptz;

alter table public.clinics
  add column if not exists archived_at timestamptz;

create index if not exists idx_hospitals_archived_at on public.hospitals (archived_at);
create index if not exists idx_clinics_archived_at on public.clinics (archived_at);
