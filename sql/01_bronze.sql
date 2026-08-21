-- Bronze layer
-- Keeps the original transaction and loyalty data before cleaning.

USE CATALOG workspace;
USE SCHEMA bronze;

-- Landing area for source files
CREATE VOLUME IF NOT EXISTS workspace.bronze.source_files;

-- Raw transaction data
-- One row represents one product line from a transaction.
-- Load transaction details from volume
CREATE OR REPLACE TABLE workspace.bronze.transaction_details_raw AS
SELECT 
  `# customer_id` AS customer_id ,
  transaction_id,
  receipt_date,
  transaction_date,
  receipt_number,
  product_sku,
  product_brand,
  quantity,
  total_unit_price,
  retailer,
  branch
FROM read_files(
  '/Volumes/workspace/bronze/source_files/Transaction Details Original.csv',
  format => 'csv',
  header => true
);

-- Load loyalty cardholders from volume
CREATE OR REPLACE TABLE workspace.bronze.loyalty_cardholders_raw AS
SELECT 
  user_id,
  birthday,
  registered_date
FROM read_files(
  '/Volumes/workspace/bronze/source_files/Loyalty cardholders Original.csv',
  format => 'csv',
  header => true
);

-- Check current row counts
SELECT
    'Transaction Details' AS source,
    COUNT(*) AS row_count
FROM read_files(
  '/Volumes/workspace/bronze/source_files/Transaction Details Original.csv')

UNION ALL

SELECT
    'Loyalty Cardholders' AS source,
    COUNT(*) AS row_count
FROM read_files('/Volumes/workspace/bronze/source_files/Loyalty cardholders Original.csv');