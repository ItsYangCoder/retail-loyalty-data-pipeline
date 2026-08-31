-- 04 INTEGRATION
-- Combines cleaned transaction data with loyalty customer information.
-- The transaction rows and sales totals should stay the same after the join.

USE CATALOG workspace;
USE SCHEMA silver;


-- Join transactions with matching loyalty members
CREATE OR REPLACE TEMP VIEW integrated_step AS

SELECT
    t.customer_id,
    t.transaction_id,
    t.receipt_date,
    t.transaction_date,
    t.receipt_number,
    t.product_sku,
    t.product_brand,
    t.quantity,
    t.recorded_sales,
    t.calculated_unit_price,
    t.retailer,
    t.branch,
    t.transaction_month,
    t.data_quality_flag,

    l.user_id AS loyalty_user_id,
    l.birthday,
    l.registered_date,
    l.age_at_registration,
    l.birthday_status,

    -- Calculate customer age when the purchase happened
    CASE
        WHEN l.birthday IS NULL THEN NULL
        ELSE FLOOR(
            DATEDIFF(DATE(t.transaction_date), l.birthday) / 365.25
        )
    END AS age_at_purchase,

    -- Show if the transaction has a matching loyalty member
    CASE
        WHEN l.user_id IS NULL THEN 'Not matched'
        ELSE 'Matched'
    END AS loyalty_match_status

FROM workspace.silver.clean_transactions t

LEFT JOIN workspace.silver.clean_loyalty l
    ON t.customer_id = l.user_id;


-- Create the final integrated transaction table
CREATE OR REPLACE TABLE workspace.silver.integrated_transactions AS

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
    calculated_unit_price,
    retailer,
    branch,
    transaction_month,
    data_quality_flag,

    loyalty_user_id,
    birthday,
    registered_date,
    age_at_registration,
    age_at_purchase,

    -- Group customers based on their age during purchase
    CASE
        WHEN loyalty_user_id IS NULL THEN 'No Loyalty Match'
        WHEN age_at_purchase IS NULL THEN 'Unknown/Invalid'
        WHEN age_at_purchase < 18 THEN 'Under 18'
        WHEN age_at_purchase BETWEEN 18 AND 24 THEN '18-24'
        WHEN age_at_purchase BETWEEN 25 AND 34 THEN '25-34'
        WHEN age_at_purchase BETWEEN 35 AND 44 THEN '35-44'
        WHEN age_at_purchase BETWEEN 45 AND 54 THEN '45-54'
        WHEN age_at_purchase BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group,

    birthday_status,
    loyalty_match_status

FROM integrated_step;


-- Check that no transaction rows were lost or duplicated
SELECT
    'Clean Transactions' AS table_name,
    COUNT(*) AS row_count
FROM workspace.silver.clean_transactions

UNION ALL

SELECT
    'Integrated Transactions',
    COUNT(*)
FROM workspace.silver.integrated_transactions;


-- Check how many transactions matched loyalty members
SELECT
    loyalty_match_status,
    COUNT(*) AS row_count
FROM workspace.silver.integrated_transactions
GROUP BY loyalty_match_status;


-- Check the distribution of customer age groups
SELECT
    age_group,
    COUNT(*) AS row_count
FROM workspace.silver.integrated_transactions
GROUP BY age_group
ORDER BY age_group;


-- Check that total sales did not change after integration
SELECT
    'Before Integration' AS stage,
    ROUND(SUM(recorded_sales), 2) AS total_sales
FROM workspace.silver.clean_transactions

UNION ALL

SELECT
    'After Integration',
    ROUND(SUM(recorded_sales), 2)
FROM workspace.silver.integrated_transactions;


-- Check for duplicate loyalty member IDs
SELECT
    user_id,
    COUNT(*) AS record_count
FROM workspace.silver.clean_loyalty
GROUP BY user_id
HAVING COUNT(*) > 1;


-- Preview the integrated data
SELECT *
FROM workspace.silver.integrated_transactions
LIMIT 20;