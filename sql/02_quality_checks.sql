-- Quality checks
-- Stores invalid or suspicious records before Silver cleaning.

USE CATALOG workspace;
USE SCHEMA quality;


-- 1. Invalid transactions
-- Remove rows with zero/negative quantity or recorded sales.

CREATE OR REPLACE TABLE workspace.quality.invalid_transactions AS

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
    branch,

    CASE
        WHEN quantity <= 0 THEN 'Quantity <= 0'
        ELSE 'Recorded sales <= 0'
    END AS exclusion_reason

FROM workspace.bronze.transaction_details_raw

WHERE quantity <= 0
   OR total_unit_price <= 0;


-- 2. Receipt date issues
-- Keep valid transactions but flag receipts recorded more than 1 day later.

CREATE OR REPLACE TABLE workspace.quality.receipt_date_issues AS

SELECT
    customer_id,
    transaction_id,
    TRY_TO_TIMESTAMP(receipt_date, 'M/d/yy H:mm') AS receipt_date,
    transaction_date,
    receipt_number,
    product_sku,
    product_brand,
    quantity,
    total_unit_price AS recorded_sales,
    retailer,
    branch,
    'Receipt date is more than 1 day after transaction date' AS quality_issue

FROM workspace.bronze.transaction_details_raw

WHERE quantity > 0
  AND total_unit_price > 0
  AND TRY_TO_TIMESTAMP(receipt_date, 'M/d/yy H:mm')
      > transaction_date + INTERVAL 1 DAY;


-- 3. Invalid loyalty birthdays
-- Flag customers whose recorded age is over 110.

CREATE OR REPLACE TABLE workspace.quality.invalid_loyalty_birthdays AS

SELECT
    user_id,
    birthday AS original_birthday,
    registered_date,
    'Age over 110' AS quality_issue

FROM workspace.bronze.loyalty_cardholders_raw

WHERE YEAR(registered_date) - YEAR(birthday) > 110;


-- 4. Check results

SELECT
    'Invalid Transactions' AS quality_check,
    COUNT(*) AS row_count
FROM workspace.quality.invalid_transactions

UNION ALL

SELECT
    'Receipt Date Issues',
    COUNT(*)
FROM workspace.quality.receipt_date_issues

UNION ALL

SELECT
    'Invalid Loyalty Birthdays',
    COUNT(*)
FROM workspace.quality.invalid_loyalty_birthdays;