-- Align drugs naming with app model changes
-- - Stop using scientific_name as a required/unique identifier
-- - Rename brand_names (TEXT[]) -> trade_names (TEXT[])
-- - Rename trade_names (JSONB) -> trade_names_by_country (JSONB)
--
-- This keeps both representations:
--   trade_names:              flat list (TEXT[])
--   trade_names_by_country:   country mapping (JSONB)

-- 1) Relax scientific_name constraints and remove the legacy UNIQUE index
DROP INDEX IF EXISTS idx_drugs_scientific_name_unique;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'scientific_name'
  ) THEN
    EXECUTE 'ALTER TABLE public.drugs ALTER COLUMN scientific_name DROP NOT NULL';
    EXECUTE 'ALTER TABLE public.drugs ALTER COLUMN scientific_name DROP DEFAULT';
    UPDATE public.drugs
    SET scientific_name = NULL
    WHERE scientific_name = '';
  END IF;
END $$;

-- 2) Rename columns to match new semantics
DO $$
BEGIN
  -- Existing JSONB column was named trade_names; rename it to trade_names_by_country
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'trade_names'
      AND data_type = 'jsonb'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'trade_names_by_country'
  ) THEN
    EXECUTE 'ALTER TABLE public.drugs RENAME COLUMN trade_names TO trade_names_by_country';
  END IF;

  -- brand_names (TEXT[]) becomes trade_names (TEXT[])
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'brand_names'
  ) AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'trade_names'
  ) THEN
    EXECUTE 'ALTER TABLE public.drugs RENAME COLUMN brand_names TO trade_names';
  END IF;
END $$;

-- 3) Indexes: rename existing ones to keep intent + avoid recreating if possible
-- JSONB GIN index
ALTER INDEX IF EXISTS idx_drugs_trade_names RENAME TO idx_drugs_trade_names_by_country;

-- TEXT[] GIN index
ALTER INDEX IF EXISTS idx_drugs_brand_names RENAME TO idx_drugs_trade_names;

-- Ensure indexes exist with the right targets
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'trade_names_by_country'
  ) THEN
    EXECUTE 'DROP INDEX IF EXISTS idx_drugs_trade_names_by_country';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_drugs_trade_names_by_country ON public.drugs USING GIN(trade_names_by_country)';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'drugs'
      AND column_name = 'trade_names'
  ) THEN
    EXECUTE 'DROP INDEX IF EXISTS idx_drugs_trade_names';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_drugs_trade_names ON public.drugs USING GIN(trade_names)';
  END IF;
END $$;

-- 4) Update helper functions to use renamed columns
CREATE OR REPLACE FUNCTION public.search_trade_names(trade_name TEXT)
RETURNS SETOF public.drugs AS $$
BEGIN
  RETURN QUERY
  SELECT d.*
  FROM public.drugs d,
       jsonb_each_text(d.trade_names_by_country) AS country(country_name, brands_json)
  WHERE trade_name ILIKE '%' || brands_json || '%';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_drugs_by_trade_name_country(
  search_trade_name TEXT,
  country_code TEXT
)
RETURNS SETOF public.drugs AS $$
BEGIN
  RETURN QUERY
  SELECT d.*
  FROM public.drugs d
  WHERE d.trade_names_by_country->>country_code ILIKE '%' || search_trade_name || '%';
END;
$$ LANGUAGE plpgsql;

-- 5) Update views to use new names
DROP VIEW IF EXISTS public.drugs_with_interactions;
CREATE VIEW public.drugs_with_interactions AS
SELECT
  d.id,
  d.generic_name,
  d.trade_names,
  json_agg(
    json_build_object(
      'interacting_drug_id', di.interacting_drug_id,
      'severity', di.severity,
      'description', di.description
    ) ORDER BY di.severity DESC
  ) FILTER (WHERE di.id IS NOT NULL) AS interactions
FROM public.drugs d
LEFT JOIN public.drug_interactions di ON d.id = di.drug_id
GROUP BY d.id;

DROP VIEW IF EXISTS public.drugs_with_side_effects;
CREATE VIEW public.drugs_with_side_effects AS
SELECT
  d.id,
  d.generic_name,
  d.side_effects,
  d.common_side_effects,
  d.rare_side_effects,
  d.serious_side_effects,
  COUNT(se.id) AS detailed_effects_count
FROM public.drugs d
LEFT JOIN public.side_effect_details se ON d.id = se.drug_id
GROUP BY d.id, d.generic_name, d.side_effects,
         d.common_side_effects, d.rare_side_effects, d.serious_side_effects;

-- 6) Update documentation comments
COMMENT ON TABLE public.drugs IS 'Drug master table (generic_name as primary human-readable identifier)';
COMMENT ON COLUMN public.drugs.trade_names IS 'Trade names list (TEXT[])';
COMMENT ON COLUMN public.drugs.trade_names_by_country IS 'JSONB object mapping countries to trade name arrays: {"USA": ["Brand1"], "Egypt": ["Brand1", "Brand2"]}';
