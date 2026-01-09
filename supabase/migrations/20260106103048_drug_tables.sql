-- Single comprehensive drugs table
-- Migration: drug_tables

-- Main drugs table with all dosage and safety information
CREATE TABLE IF NOT EXISTS drugs (
    -- Identification
    id TEXT PRIMARY KEY,
    generic_name TEXT NOT NULL,
    trade_names TEXT[] DEFAULT '{}',
    
    -- Classification
    drug_class TEXT,
    mechanism TEXT,
    
    -- Clinical Use
    indications TEXT[] DEFAULT '{}',
    
    -- Safety Information
    contraindications TEXT[] DEFAULT '{}',
    warnings TEXT[] DEFAULT '{}',
    black_box_warnings TEXT[] DEFAULT '{}',
    side_effects TEXT[] DEFAULT '{}',
    common_side_effects TEXT[] DEFAULT '{}',
    rare_side_effects TEXT[] DEFAULT '{}',
    serious_side_effects TEXT[] DEFAULT '{}',
    
    -- Drug Interactions
    interacts_with TEXT[] DEFAULT '{}',
    
    -- Standard Dosing
    standard_dose_indication TEXT,
    standard_dose_route TEXT,
    standard_dose TEXT,
    standard_dose_frequency TEXT,
    standard_dose_duration TEXT,
    standard_dose_notes TEXT,
    
    -- Special Populations
    geriatric_notes TEXT,
    max_daily_dose TEXT,
    
    -- Renal Dosing
    renal_crcl_gt_50 TEXT DEFAULT '-',
    renal_crcl_30_50 TEXT DEFAULT '-',
    renal_crcl_10_30 TEXT DEFAULT '-',
    renal_crcl_lt_10 TEXT DEFAULT '-',
    renal_dialysis TEXT,
    renal_notes TEXT,
    
    -- Hepatic Dosing
    hepatic_child_pugh_a TEXT,
    hepatic_child_pugh_b TEXT,
    hepatic_child_pugh_c TEXT,
    hepatic_notes TEXT,
    
    -- Pediatric Dosing
    pediatric_neonates TEXT,
    pediatric_infants TEXT,
    pediatric_children TEXT,
    pediatric_adolescents TEXT,
    pediatric_weight_based TEXT,
    pediatric_notes TEXT,
    
    -- Metadata
    cached_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better search performance
CREATE INDEX IF NOT EXISTS idx_drugs_generic_name ON drugs(generic_name);
CREATE INDEX IF NOT EXISTS idx_drugs_trade_names ON drugs USING GIN(trade_names);
CREATE INDEX IF NOT EXISTS idx_drugs_indications ON drugs USING GIN(indications);
CREATE INDEX IF NOT EXISTS idx_drugs_side_effects ON drugs USING GIN(side_effects);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for drugs table
DROP TRIGGER IF EXISTS update_drugs_updated_at ON drugs;
CREATE TRIGGER update_drugs_updated_at BEFORE UPDATE ON drugs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read access on drugs" ON drugs;
DROP POLICY IF EXISTS "Allow authenticated insert on drugs" ON drugs;
DROP POLICY IF EXISTS "Allow authenticated update on drugs" ON drugs;

-- Create policies: Allow read access to everyone, authenticated users can insert/update
CREATE POLICY "Allow public read access on drugs" ON drugs
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert on drugs" ON drugs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update on drugs" ON drugs
    FOR UPDATE USING (auth.role() = 'authenticated');
