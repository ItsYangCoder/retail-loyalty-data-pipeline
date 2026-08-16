-- ============================================================
-- RETAIL TRANSACTIONS + LOYALTY CUSTOMER DATA PIPELINE
-- 01 - BRONZE LAYER
-- ============================================================
--
-- PURPOSE:
-- Preserve the source data before cleaning and transformation.
--
-- SOURCE 1:
-- Transaction Details
--
-- SOURCE 2:
-- Loyalty Cardholders
--
-- Bronze tables:
-- workspace.bronze.transaction_details_raw
-- workspace.bronze.loyalty_cardholders_raw
-- ============================================================


USE CATALOG workspace;
USE SCHEMA bronze;


-- ============================================================
-- 1. CREATE LANDING VOLUME
-- ============================================================
--
-- The Volume can be used later when another batch of source
-- files arrives.
-- ============================================================

CREATE VOLUME IF NOT EXISTS workspace.bronze.source_files
COMMENT 'Landing area for Retail Transaction and Loyalty source files';


-- ============================================================
-- 2. TRANSACTION DETAILS RAW TABLE
-- ============================================================
--
-- Grain:
-- One row represents one purchased product / transaction line.
--
-- The table preserves the source values before Silver cleaning.
-- ============================================================

CREATE TABLE IF NOT EXISTS workspace.bronze.transaction_details_raw (

    `# customer_id` BIGINT,
    transaction_id BIGINT,
    receipt_date STRING,
    transaction_date TIMESTAMP,
    receipt_number STRING,
    product_sku STRING,
    product_brand STRING,
    quantity BIGINT,
    total_unit_price DOUBLE,
    retailer STRING,
    branch STRING

)
COMMENT 'Raw Retail Transaction Details source data';


-- ============================================================
-- 3. LOYALTY CARDHOLDERS RAW TABLE
-- ============================================================
--
-- Grain:
-- One row represents one registered loyalty member.
-- ============================================================

CREATE TABLE IF NOT EXISTS workspace.bronze.loyalty_cardholders_raw (

    user_id BIGINT,
    birthday DATE,
    registered_date TIMESTAMP

)
COMMENT 'Raw Loyalty Cardholders source data';


-- ============================================================
-- 4. BRONZE ROW COUNT VALIDATION
-- ============================================================
--
-- Current expected baseline:
--
-- Transaction Details = 3,167
-- Loyalty Cardholders = 5,949
--
-- These counts will increase when future batches are loaded.
-- ============================================================

SELECT
    'Transaction Details' AS source,
    COUNT(*) AS row_count

FROM workspace.bronze.transaction_details_raw

UNION ALL

SELECT
    'Loyalty Cardholders' AS source,
    COUNT(*) AS row_count

FROM workspace.bronze.loyalty_cardholders_raw;


-- ============================================================
-- 5. TRANSACTION DATA PREVIEW
-- ============================================================

SELECT *
FROM workspace.bronze.transaction_details_raw
LIMIT 20;


-- ============================================================
-- 6. LOYALTY DATA PREVIEW
-- ============================================================

SELECT *
FROM workspace.bronze.loyalty_cardholders_raw
LIMIT 20;