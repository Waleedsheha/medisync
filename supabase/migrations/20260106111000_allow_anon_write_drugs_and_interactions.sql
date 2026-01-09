-- Allow anon (client) to upsert drugs and interactions
-- This fixes: PostgrestException 42501 "new row violates row-level security"
-- NOTE: This makes drugs/interactions writable by anon key; tighten for production if needed.

-- ============================
-- DRUGS
-- ============================
ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;

-- Keep existing read policy (if any)
DROP POLICY IF EXISTS "Allow anon insert on drugs" ON drugs;
DROP POLICY IF EXISTS "Allow anon update on drugs" ON drugs;

CREATE POLICY "Allow anon insert on drugs" ON drugs
  FOR INSERT
  WITH CHECK (auth.role() IN ('anon', 'authenticated'));

CREATE POLICY "Allow anon update on drugs" ON drugs
  FOR UPDATE
  USING (auth.role() IN ('anon', 'authenticated'))
  WITH CHECK (auth.role() IN ('anon', 'authenticated'));

-- ============================
-- DRUG INTERACTIONS
-- ============================
ALTER TABLE drug_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow anon insert on drug_interactions" ON drug_interactions;
DROP POLICY IF EXISTS "Allow anon update on drug_interactions" ON drug_interactions;

CREATE POLICY "Allow anon insert on drug_interactions" ON drug_interactions
  FOR INSERT
  WITH CHECK (auth.role() IN ('anon', 'authenticated'));

CREATE POLICY "Allow anon update on drug_interactions" ON drug_interactions
  FOR UPDATE
  USING (auth.role() IN ('anon', 'authenticated'))
  WITH CHECK (auth.role() IN ('anon', 'authenticated'));
