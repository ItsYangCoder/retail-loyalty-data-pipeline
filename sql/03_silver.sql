-- SILVER LAYER

USE CATALOG workspace;
USE SCHEMA silver;


-- =========================================================
-- 1. CLEAN TRANSACTIONS
-- =========================================================

--  Transaction cleaning
CREATE OR REPLACE TEMP VIEW transactions_step AS

SELECT
    customer_id,
    transaction_id,

    -- convert receipt date from text to timestamp
    TRY_TO_TIMESTAMP(receipt_date, 'M/d/yy H:mm') AS receipt_date,

    transaction_date,

    -- remove spaces and hyphens
    REPLACE(TRIM(receipt_number), '-', '') AS receipt_number,

    -- remove unnecessary symbols from product SKU
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(product_sku, '$', ''),
            '<<', ''),
        '*', '')
    ) AS product_sku,

    -- recover missing brand if SKU clearly tells us the brand
    CASE
        WHEN product_brand IS NULL
             AND UPPER(product_sku) LIKE '%UFC%'
            THEN 'UFC'

        WHEN product_brand IS NULL
             AND (
                 UPPER(product_sku) LIKE 'DP %'
                 OR UPPER(product_sku) LIKE '%DPUTI%'
                 OR UPPER(product_sku) LIKE '%DATU PUTI%'
             )
            THEN 'Datu Puti'

        ELSE TRIM(product_brand)
    END AS product_brand,

    quantity,

    -- this column contains the recorded sales amount
    total_unit_price AS recorded_sales,

    TRIM(retailer) AS retailer,

    -- standardize branch names
    UPPER(TRIM(branch)) AS branch

FROM workspace.bronze.transaction_details_raw

-- exclude the 6 invalid transaction rows
WHERE quantity > 0
  AND total_unit_price > 0;



-- Create final clean transaction table
CREATE OR REPLACE TABLE workspace.silver.clean_transactions AS

SELECT
    customer_id,
    transaction_id,
    receipt_date,
    transaction_date,
    receipt_number,
    product_sku,
    product_brand,
    quantity,
    recorded_sales,
    retailer,
    branch,

    -- sales amount divided by quantity
    ROUND(recorded_sales / quantity, 2) AS calculated_unit_price,

    -- month used for sales analysis
    DATE_FORMAT(transaction_date, 'MMM yyyy') AS transaction_month,

    -- keep receipt-date issues but flag them for review
    CASE
        WHEN receipt_date > transaction_date + INTERVAL 1 DAY
            THEN 'Review receipt date'
        ELSE 'Valid'
    END AS data_quality_flag

FROM transactions_step;



-- =========================================================
-- 2. CLEAN LOYALTY CARDHOLDERS
-- =========================================================

-- Validate birthdays first
CREATE OR REPLACE TEMP VIEW loyalty_step AS

SELECT
    user_id,

    CASE
        WHEN birthday IS NULL THEN NULL

        WHEN birthday > DATE(registered_date) THEN NULL

        WHEN FLOOR(
            DATEDIFF(DATE(registered_date), birthday) / 365.25
        ) > 110 THEN NULL

        ELSE birthday
    END AS birthday,

    registered_date

FROM workspace.bronze.loyalty_cardholders_raw;



-- Calculate valid age
CREATE OR REPLACE TEMP VIEW loyalty_age_step AS

SELECT
    user_id,
    birthday,
    registered_date,

    CASE
        WHEN birthday IS NULL THEN NULL

        ELSE FLOOR(
            DATEDIFF(DATE(registered_date), birthday) / 365.25
        )
    END AS age_at_registration

FROM loyalty_step;



-- Create final clean loyalty table
CREATE OR REPLACE TABLE workspace.silver.clean_loyalty AS

SELECT
    user_id,
    birthday,
    registered_date,
    age_at_registration,

    CASE
        WHEN age_at_registration IS NULL THEN 'Unknown/Invalid'
        WHEN age_at_registration < 18 THEN 'Under 18'
        WHEN age_at_registration BETWEEN 18 AND 24 THEN '18-24'
        WHEN age_at_registration BETWEEN 25 AND 34 THEN '25-34'
        WHEN age_at_registration BETWEEN 35 AND 44 THEN '35-44'
        WHEN age_at_registration BETWEEN 45 AND 54 THEN '45-54'
        WHEN age_at_registration BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,

    CASE
        WHEN birthday IS NULL THEN 'Invalid birthday'
        ELSE 'Valid'
    END AS birthday_status

FROM loyalty_age_step;



-- =========================================================
-- 3. VALIDATION
-- =========================================================

-- Check Silver row counts
SELECT
    'Clean Transactions' AS table_name,
    COUNT(*) AS row_count
FROM workspace.silver.clean_transactions

UNION ALL

SELECT
    'Clean Loyalty',
    COUNT(*)
FROM workspace.silver.clean_loyalty;



-- Check receipt-date issues
SELECT
    data_quality_flag,
    COUNT(*) AS row_count
FROM workspace.silver.clean_transactions
GROUP BY data_quality_flag;



-- Check loyalty birthday status
SELECT
    birthday_status,
    COUNT(*) AS row_count
FROM workspace.silver.clean_loyalty
GROUP BY birthday_status;



-- Check if missing brands were recovered
SELECT COUNT(*) AS missing_product_brand
FROM workspace.silver.clean_transactions
WHERE product_brand IS NULL;