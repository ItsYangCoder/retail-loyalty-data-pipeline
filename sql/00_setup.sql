-- ============================================================
-- SARI-SARI STORE DATA PIPELINE
-- 00 - PROJECT SETUP
-- ============================================================

USE CATALOG workspace;

-- Bronze: preserves the original Sari-Sari Store source data
CREATE SCHEMA IF NOT EXISTS workspace.sari_bronze
COMMENT 'Raw and preserved source data for the Sari-Sari Store pipeline';

-- Silver: cleaned and standardized data
CREATE SCHEMA IF NOT EXISTS workspace.sari_silver
COMMENT 'Cleaned and standardized data for the Sari-Sari Store pipeline';

-- Gold: business-ready analytical tables
CREATE SCHEMA IF NOT EXISTS workspace.sari_gold
COMMENT 'Business-ready tables for Sari-Sari Store analysis and dashboarding';

-- Quality: data-quality findings and validation results
CREATE SCHEMA IF NOT EXISTS workspace.sari_quality
COMMENT 'Data-quality issues and validation results for the Sari-Sari Store pipeline';