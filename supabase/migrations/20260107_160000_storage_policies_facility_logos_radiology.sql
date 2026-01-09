-- Storage security policies for facility logos + radiology.
-- Buckets:
-- - facility-logos: stores hospital/unit logos
-- - patient-radiology: stores radiology images
--
-- App object naming conventions (SHARED/MULTI-USER MODEL):
-- - facility-logos:    logos/<hospital_id>/<scope>/<facility_id>/logo.<ext>
-- - patient-radiology: radiology/<hospital_id>/<mrn>/<file>.<ext>

-- IMPORTANT (Supabase hosted projects):
-- In many projects, the SQL editor user is NOT the owner of storage.objects/storage.buckets
-- (owner is typically "supabase_storage_admin"). In that case, running this file will fail
-- with: "ERROR: 42501: must be owner of table objects".
--
-- ✅ Use this file as a SCRIPT REFERENCE:
-- 1) Go to Dashboard → Storage → (bucket) → Policies
-- 2) Create policies with the expressions shown below.
-- 3) Set bucket visibility to PRIVATE in the bucket settings.

-- Make buckets private (recommended).
-- Run via UI (Dashboard → Storage → bucket → Settings): set to PRIVATE.
-- SQL version (may fail with ownership error):
-- update storage.buckets set public = false where id in ('facility-logos', 'patient-radiology');

-- Ensure RLS is enabled on storage.objects.
-- SQL version (may fail with ownership error):
-- alter table storage.objects enable row level security;

-- ========================
-- facility-logos (membership-based)
-- ========================

drop policy if exists "facility-logos: select own" on storage.objects;
drop policy if exists "facility-logos: insert own" on storage.objects;
drop policy if exists "facility-logos: update own" on storage.objects;
drop policy if exists "facility-logos: delete own" on storage.objects;

create policy "facility-logos: select own" on storage.objects
for select
using (
  bucket_id = 'facility-logos'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

create policy "facility-logos: insert own" on storage.objects
for insert
with check (
  bucket_id = 'facility-logos'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

create policy "facility-logos: update own" on storage.objects
for update
using (
  bucket_id = 'facility-logos'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
)
with check (
  bucket_id = 'facility-logos'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

create policy "facility-logos: delete own" on storage.objects
for delete
using (
  bucket_id = 'facility-logos'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

-- ========================
-- patient-radiology (membership-based)
-- ========================

drop policy if exists "patient-radiology: select own" on storage.objects;
drop policy if exists "patient-radiology: insert own" on storage.objects;
drop policy if exists "patient-radiology: update own" on storage.objects;
drop policy if exists "patient-radiology: delete own" on storage.objects;

create policy "patient-radiology: select own" on storage.objects
for select
using (
  bucket_id = 'patient-radiology'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

create policy "patient-radiology: insert own" on storage.objects
for insert
with check (
  bucket_id = 'patient-radiology'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

create policy "patient-radiology: update own" on storage.objects
for update
using (
  bucket_id = 'patient-radiology'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
)
with check (
  bucket_id = 'patient-radiology'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);

create policy "patient-radiology: delete own" on storage.objects
for delete
using (
  bucket_id = 'patient-radiology'
  and exists (
    select 1
    from public.hospital_members m
    where m.hospital_id = (split_part(name, '/', 2))::uuid
      and m.user_id = auth.uid()
  )
);
