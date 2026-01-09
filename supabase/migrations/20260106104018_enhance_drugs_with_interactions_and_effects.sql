-- Enhanced Drugs Migration
-- Adds: scientific name (primary), trade names by country, interactions, side effects

-- ============================================================================
-- 1. ALTER EXISTING TABLES
-- ============================================================================

-- Add scientific_name, side_effects, and other fields to drugs table
ALTER TABLE drugs 
    ADD COLUMN IF NOT EXISTS scientific_name TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS side_effects TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS common_side_effects TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS rare_side_effects TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS serious_side_effects TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS trade_names JSONB DEFAULT '{}'::jsonb;

-- Create unique index on scientific_name to prevent duplicates
DROP INDEX IF EXISTS idx_drugs_scientific_name_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_drugs_scientific_name_unique 
    ON drugs(scientific_name);

-- Create GIN index on trade_names for country-specific queries
DROP INDEX IF EXISTS idx_drugs_trade_names;
CREATE INDEX IF NOT EXISTS idx_drugs_trade_names 
    ON drugs USING GIN(trade_names);

-- Create GIN index on side_effects for searching
DROP INDEX IF EXISTS idx_drugs_side_effects;
CREATE INDEX IF NOT EXISTS idx_drugs_side_effects 
    ON drugs USING GIN(side_effects);

-- Update existing generic_name to scientific_name if scientific_name is empty
UPDATE drugs 
SET scientific_name = generic_name 
WHERE scientific_name = '' OR scientific_name IS NULL;

-- ============================================================================
-- 2. DRUG INTERACTIONS TABLE (Normalized)
-- ============================================================================

CREATE TABLE IF NOT EXISTS drug_interactions (
    id TEXT PRIMARY KEY,
    drug_id TEXT NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    interacting_drug_id TEXT NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    severity TEXT NOT NULL CHECK (severity IN ('major', 'moderate', 'minor')),
    description TEXT NOT NULL,
    mechanism TEXT,
    management TEXT,
    source TEXT,
    evidence_level TEXT CHECK (evidence_level IN ('A', 'B', 'C', 'D', 'X')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure no duplicate interactions
DROP INDEX IF EXISTS idx_drug_interactions_unique;
CREATE UNIQUE INDEX IF NOT EXISTS idx_drug_interactions_unique 
    ON drug_interactions(
        LEAST(drug_id, interacting_drug_id), 
        GREATEST(drug_id, interacting_drug_id)
    );

-- Indexes for interaction lookups
CREATE INDEX IF NOT EXISTS idx_interactions_drug_id ON drug_interactions(drug_id);
CREATE INDEX IF NOT EXISTS idx_interactions_severity ON drug_interactions(severity);

-- ============================================================================
-- 3. SIDE EFFECTS DETAILS TABLE (Optional - for more detailed info)
-- ============================================================================

CREATE TABLE IF NOT EXISTS side_effect_details (
    id BIGSERIAL PRIMARY KEY,
    drug_id TEXT NOT NULL REFERENCES drugs(id) ON DELETE CASCADE,
    effect_name TEXT NOT NULL,
    frequency TEXT CHECK (frequency IN ('very_common', 'common', 'uncommon', 'rare', 'very_rare')),
    severity TEXT CHECK (severity IN ('mild', 'moderate', 'severe', 'life_threatening')),
    onset_timing TEXT, -- e.g., "Immediate", "Weeks", "Months"
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for side effect lookups
CREATE INDEX IF NOT EXISTS idx_side_effects_drug_id ON side_effect_details(drug_id);
CREATE INDEX IF NOT EXISTS idx_side_effects_frequency ON side_effect_details(frequency);
CREATE INDEX IF NOT EXISTS idx_side_effects_severity ON side_effect_details(severity);

-- ============================================================================
-- 4. TRADE NAMES BY COUNTRY (JSONB structure examples)
-- ============================================================================

-- Example structure for trade_names JSONB column:
-- {
--   "USA": ["Tylenol", "Panadol"],
--   "UK": ["Paracetamol"],
--   "Egypt": ["Adol", "Fevadol"],
--   "Saudi Arabia": ["Panadol Extra", "Adol"],
--   "UAE": ["Panadol", "Buscopan"]
-- }

-- Create a helper function to search trade names
CREATE OR REPLACE FUNCTION search_trade_names(trade_name TEXT)
RETURNS SETOF drugs AS $$
BEGIN
    RETURN QUERY
    SELECT d.*
    FROM drugs d,
         jsonb_each_text(d.trade_names) AS country(country_name, brands_json)
    WHERE trade_name ILIKE '%' || brands_json || '%';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. ROW LEVEL SECURITY
-- ============================================================================

-- Drug interactions RLS
ALTER TABLE drug_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE side_effect_details ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow public read access on drug_interactions" ON drug_interactions;
DROP POLICY IF EXISTS "Allow authenticated insert on drug_interactions" ON drug_interactions;

DROP POLICY IF EXISTS "Allow public read access on side_effect_details" ON side_effect_details;
DROP POLICY IF EXISTS "Allow authenticated insert on side_effect_details" ON side_effect_details;

-- Create policies for drug_interactions
CREATE POLICY "Allow public read access on drug_interactions" ON drug_interactions
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert on drug_interactions" ON drug_interactions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update on drug_interactions" ON drug_interactions
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Create policies for side_effect_details
CREATE POLICY "Allow public read access on side_effect_details" ON side_effect_details
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert on side_effect_details" ON side_effect_details
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================================
-- 6. VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View for drugs with their interactions
CREATE OR REPLACE VIEW drugs_with_interactions AS
SELECT 
    d.id,
    d.scientific_name,
    d.generic_name,
    d.brand_names,
    json_agg(
        json_build_object(
            'interacting_drug_id', di.interacting_drug_id,
            'severity', di.severity,
            'description', di.description
        ) ORDER BY di.severity DESC
    ) FILTER (WHERE di.id IS NOT NULL) as interactions
FROM drugs d
LEFT JOIN drug_interactions di ON d.id = di.drug_id
GROUP BY d.id;

-- View for drugs with side effects summary
CREATE OR REPLACE VIEW drugs_with_side_effects AS
SELECT 
    d.id,
    d.scientific_name,
    d.generic_name,
    d.side_effects,
    d.common_side_effects,
    d.rare_side_effects,
    d.serious_side_effects,
    COUNT(se.id) as detailed_effects_count
FROM drugs d
LEFT JOIN side_effect_details se ON d.id = se.drug_id
GROUP BY d.id, d.scientific_name, d.generic_name, d.side_effects, 
         d.common_side_effects, d.rare_side_effects, d.serious_side_effects;

-- ============================================================================
-- 7. HELPER FUNCTIONS
-- ============================================================================

-- Function to check for interactions between two drugs
CREATE OR REPLACE FUNCTION check_drug_interactions(drug1_id TEXT, drug2_id TEXT)
RETURNS TABLE(
    interaction_id TEXT,
    severity TEXT,
    description TEXT,
    mechanism TEXT,
    management TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        di.id,
        di.severity,
        di.description,
        di.mechanism,
        di.management
    FROM drug_interactions di
    WHERE (di.drug_id = drug1_id AND di.interacting_drug_id = drug2_id)
       OR (di.drug_id = drug2_id AND di.interacting_drug_id = drug1_id);
END;
$$ LANGUAGE plpgsql;

-- Function to get drugs by trade name in a specific country
CREATE OR REPLACE FUNCTION get_drugs_by_trade_name_country(
    search_trade_name TEXT,
    country_code TEXT
)
RETURNS SETOF drugs AS $$
BEGIN
    RETURN QUERY
    SELECT d.*
    FROM drugs d
    WHERE d.trade_names->>country_code ILIKE '%' || search_trade_name || '%';
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 8. TRIGGERS
-- ============================================================================

-- Update timestamp trigger for interactions
DROP TRIGGER IF EXISTS update_interactions_updated_at ON drug_interactions;
CREATE TRIGGER update_interactions_updated_at 
    BEFORE UPDATE ON drug_interactions
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 9. COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE drugs IS 'Drug master table with scientific name as primary identifier';
COMMENT ON COLUMN drugs.scientific_name IS 'International scientific name (generic) - UNIQUE to prevent duplicates';
COMMENT ON COLUMN drugs.trade_names IS 'JSONB object mapping countries to trade name arrays: {"USA": ["Brand1"], "Egypt": ["Brand1", "Brand2"]}';
COMMENT ON COLUMN drugs.side_effects IS 'Complete list of all side effects';
COMMENT ON COLUMN drugs.common_side_effects IS 'Side effects occurring in >1% of patients';
COMMENT ON COLUMN drugs.rare_side_effects IS 'Side effects occurring in <0.1% of patients';
COMMENT ON COLUMN drugs.serious_side_effects IS 'Life-threatening or permanently disabling effects';

COMMENT ON TABLE drug_interactions IS 'Normalized drug-drug interactions table';
COMMENT ON COLUMN drug_interactions.severity IS 'major: Avoid, moderate: Use caution, minor: Monitor';
COMMENT ON COLUMN drug_interactions.evidence_level IS 'A: Good evidence, B: Fair evidence, C: Poor evidence, D: Expert opinion, X: Contraindicated';

COMMENT ON TABLE side_effect_details IS 'Detailed side effect information with frequency and severity';
