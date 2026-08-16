-- ============================================================
-- RETAIL TRANSACTIONS + LOYALTY CUSTOMER DATA PIPELINE
-- 00 - PROJECT SETUP
-- ============================================================
USE CATALOG workspace;

-- Bronze: preserves raw source data
CREATE SCHEMA IF NOT EXISTS workspace.bronze
COMMENT 'Raw and preserved retail transaction and loyalty source data';

-- Silver: cleaned and standardized data
CREATE SCHEMA IF NOT EXISTS workspace.silver
COMMENT 'Cleaned and standardized transaction and loyalty data';

-- Quality: rejected, suspicious, and validation records
CREATE SCHEMA IF NOT EXISTS workspace.quality
COMMENT 'Data quality findings and rejected or suspicious records';

-- Gold: business-ready analytical tables
CREATE SCHEMA IF NOT EXISTS workspace.gold
COMMENT 'Business-ready tables for purchasing behavior analysis';
