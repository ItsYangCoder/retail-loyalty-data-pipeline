-- ============================================================
-- VALIDATION LAYER
-- Sari-Sari Retail + Loyalty Pipeline
-- ============================================================

USE CATALOG workspace;

-- ============================================================
-- RECORD COUNT RECONCILIATION
-- ============================================================

SELECT
    'Raw Transactions' AS dataset,
    COUNT(*) AS records
FROM workspace.sari_bronze.sari_sari_transactions_raw

UNION ALL

SELECT
    'Clean Transactions',
    COUNT(*)
FROM workspace.sari_silver.clean_transactions

UNION ALL

SELECT
    'Raw Loyalty',
    COUNT(*)
FROM workspace.bronze.loyalty_cardholders_raw

UNION ALL

SELECT
    'Clean Loyalty',
    COUNT(*)
FROM workspace.sari_silver.clean_loyalty;

-- ============================================================
-- TRANSACTIONS DATA QUALITY CHECKS
-- ============================================================

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN product_sku IS NULL THEN 1 ELSE 0 END) AS null_product_sku,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity,
    SUM(CASE WHEN total_unit_price IS NULL THEN 1 ELSE 0 END) AS null_total_unit_price,
    SUM(CASE WHEN total_unit_price <= 0 THEN 1 ELSE 0 END) AS invalid_total_unit_price,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price
FROM workspace.sari_silver.clean_transactions;

-- ============================================================
-- LOYALTY DATA QUALITY CHECKS
-- ============================================================

SELECT
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN birthday IS NULL THEN 1 ELSE 0 END) AS null_birthday,
    SUM(CASE WHEN birthday_formatted IS NULL THEN 1 ELSE 0 END) AS invalid_birthday,
    SUM(CASE WHEN registered_date IS NULL THEN 1 ELSE 0 END) AS null_registered_date,
    SUM(CASE WHEN age_at_registration < 0 THEN 1 ELSE 0 END) AS invalid_age
FROM workspace.sari_silver.clean_loyalty;

-- ============================================================
-- DUPLICATE CHECKS
-- ============================================================

SELECT
    transaction_id,
    product_sku,
    COUNT(*) AS duplicate_count
FROM workspace.sari_silver.clean_transactions
GROUP BY transaction_id, product_sku
HAVING COUNT(*) > 1;

SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM workspace.sari_silver.clean_loyalty
GROUP BY user_id
HAVING COUNT(*) > 1;

-- ============================================================
-- BUSINESS RULE VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS transaction_before_receipt
FROM workspace.sari_silver.clean_transactions
WHERE transaction_date > receipt_date;

SELECT
    COUNT(*) AS mismatched_months
FROM workspace.sari_silver.clean_transactions
WHERE transaction_month <> receipt_month;

SELECT
    COUNT(*) AS missing_brand_after_cleaning
FROM workspace.sari_silver.clean_transactions
WHERE cleaned_product_brand IS NULL;

-- ============================================================
-- CLEANING RULE VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS uncleaned_sku_records
FROM workspace.sari_silver.clean_transactions
WHERE cleaned_product_sku LIKE '%$%'
   OR cleaned_product_sku LIKE '%*%'
   OR cleaned_product_sku LIKE '%<<%';

SELECT
    COUNT(*) AS uncleaned_receipt_numbers
FROM workspace.sari_silver.clean_transactions
WHERE cleaned_receipt_number LIKE '%-%';

SELECT
    COUNT(*) AS non_uppercase_branches
FROM workspace.sari_silver.clean_transactions
WHERE branch_upper <> UPPER(branch_upper);

-- ============================================================
-- AGE VALIDATION
-- ============================================================

SELECT
    MIN(age_at_registration) AS minimum_age,
    MAX(age_at_registration) AS maximum_age
FROM workspace.sari_silver.clean_loyalty
WHERE age_at_registration IS NOT NULL;

-- ============================================================
-- SAMPLE DATA REVIEW
-- ============================================================

SELECT *
FROM workspace.sari_silver.clean_transactions
LIMIT 20;

SELECT *
FROM workspace.sari_silver.clean_loyalty
LIMIT 20;
