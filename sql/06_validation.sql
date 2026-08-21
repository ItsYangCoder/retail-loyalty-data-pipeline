-- 06_validation.sql

USE CATALOG workspace;


-- Row counts
SELECT
    'Bronze Transactions' AS dataset,
    COUNT(*) AS row_count
FROM workspace.bronze.transaction_details_raw

UNION ALL

SELECT
    'Invalid Transactions',
    COUNT(*)
FROM workspace.quality.invalid_transactions

UNION ALL

SELECT
    'Silver Transactions',
    COUNT(*)
FROM workspace.silver.clean_transactions

UNION ALL

SELECT
    'Gold Transactions',
    COUNT(*)
FROM workspace.gold.gold_customer_transactions;


-- Loyalty counts
SELECT
    'Bronze Loyalty' AS dataset,
    COUNT(*) AS row_count
FROM workspace.bronze.loyalty_cardholders_raw

UNION ALL

SELECT
    'Silver Loyalty',
    COUNT(*)
FROM workspace.silver.clean_loyalty_cardholders;


-- Check Gold totals
SELECT
    ROUND(SUM(recorded_sales), 2) AS total_sales,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS purchasing_members
FROM workspace.gold.gold_customer_transactions;


-- Check unmatched customers
SELECT COUNT(*) AS unmatched_customers
FROM workspace.gold.gold_customer_transactions
WHERE registered_date IS NULL;


-- Check receipt-date issues
SELECT COUNT(*) AS receipt_date_issues
FROM workspace.quality.receipt_date_issues;


-- Check duplicate loyalty IDs
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM workspace.silver.clean_loyalty_cardholders
GROUP BY user_id
HAVING COUNT(*) > 1;