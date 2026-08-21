-- Bronze layer
-- Keeps the original transaction and loyalty data before cleaning.

USE CATALOG workspace;
USE SCHEMA bronze;

-- Landing area for source files
CREATE VOLUME IF NOT EXISTS workspace.bronze.source_files;

-- Raw transaction data
-- One row represents one product line from a transaction.
CREATE TABLE IF NOT EXISTS workspace.bronze.transaction_details_raw (
    customer_id BIGINT,
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
);

-- Raw loyalty data
-- One row represents one registered loyalty member.
CREATE TABLE IF NOT EXISTS workspace.bronze.loyalty_cardholders_raw (
    user_id BIGINT,
    birthday DATE,
    registered_date TIMESTAMP
);

-- Check current row counts
SELECT
    'Transaction Details' AS source,
    COUNT(*) AS row_count
FROM read_files(
  '/Volumes/workspace/bronze/source_files/transaction_details_raw.csv')

UNION ALL

SELECT
    'Loyalty Cardholders' AS source,
    COUNT(*) AS row_count
FROM read_files('/Volumes/workspace/bronze/source_files/loyalty_cardholders_raw.csv');