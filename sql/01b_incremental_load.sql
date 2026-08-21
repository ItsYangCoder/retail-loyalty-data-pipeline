-- 01B INCREMENTAL LOAD
-- Handles new and updated transaction records without duplicating existing rows.
-- Raw data stays unchanged while the current table keeps the latest version.

USE CATALOG workspace;
USE SCHEMA bronze;


-- Create the current table from the original source
CREATE TABLE IF NOT EXISTS workspace.bronze.transaction_details_current AS

SELECT
    customer_id,
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

FROM workspace.bronze.transaction_details_raw;


-- Empty landing table for the next incoming batch
CREATE TABLE IF NOT EXISTS workspace.bronze.transaction_details_staging AS

SELECT
    customer_id,
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

FROM workspace.bronze.transaction_details_raw

WHERE 1 = 0;


-- Compare the incoming batch with the current transaction data
MERGE INTO workspace.bronze.transaction_details_current AS old

USING workspace.bronze.transaction_details_staging AS new

ON old.transaction_id = new.transaction_id
AND old.product_sku = new.product_sku


-- Update an existing transaction line
WHEN MATCHED THEN
    UPDATE SET
        old.customer_id = new.customer_id,
        old.receipt_date = new.receipt_date,
        old.transaction_date = new.transaction_date,
        old.receipt_number = new.receipt_number,
        old.product_brand = new.product_brand,
        old.quantity = new.quantity,
        old.total_unit_price = new.total_unit_price,
        old.retailer = new.retailer,
        old.branch = new.branch


-- Insert a transaction line that does not exist yet
WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
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
    )

    VALUES (
        new.customer_id,
        new.transaction_id,
        new.receipt_date,
        new.transaction_date,
        new.receipt_number,
        new.product_sku,
        new.product_brand,
        new.quantity,
        new.total_unit_price,
        new.retailer,
        new.branch
    );


-- Check the number of records in the latest version
SELECT
    COUNT(*) AS current_rows
FROM workspace.bronze.transaction_details_current;


-- Check that the transaction key has no duplicates
SELECT
    transaction_id,
    product_sku,
    COUNT(*) AS record_count

FROM workspace.bronze.transaction_details_current

GROUP BY
    transaction_id,
    product_sku

HAVING COUNT(*) > 1;


-- Check the number of incoming records
SELECT
    COUNT(*) AS staging_rows
FROM workspace.bronze.transaction_details_staging;