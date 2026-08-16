-- ============================================================
-- SARI-SARI STORE DATA PIPELINE
-- 01 - BRONZE LAYER
-- ============================================================

USE CATALOG workspace;
USE SCHEMA sari_bronze;

-- Create landing volume for raw CSV files
CREATE VOLUME IF NOT EXISTS workspace.sari_bronze.source_files
COMMENT 'Landing area for incoming Sari-Sari Store source CSV files';

-- Create the Bronze raw table
CREATE TABLE IF NOT EXISTS workspace.sari_bronze.sari_sari_transactions_raw (
    Transaction_ID STRING,
    Date STRING,
    Item STRING,
    Quantity STRING,
    Unit_Price STRING,
    Total_Amount STRING,
    Payment_Method STRING,
    Customer_Type STRING
)
COMMENT 'Raw Sari-Sari Store transaction records loaded from source CSV files';

-- Check Bronze row count
-- Expected Result 5100
SELECT COUNT(*) AS bronze_row_count
FROM workspace.sari_bronze.sari_sari_transactions_raw;


-- 3. LOAD NEW SOURCE FILES
COPY INTO workspace.sari_bronze.sari_sari_transactions_raw
FROM '/Volumes/workspace/sari_bronze/source_files/'
FILEFORMAT = CSV
FORMAT_OPTIONS (
    'header' = 'true',
    'inferSchema' = 'false'
);

-- Preview the raw records
SELECT *
FROM workspace.sari_bronze.sari_sari_transactions_raw
LIMIT 20;


-- Check table structure
DESCRIBE TABLE workspace.sari_bronze.sari_sari_transactions_raw;