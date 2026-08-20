-- ============================================================
-- RETAIL TRANSACTIONS + LOYALTY CUSTOMER DATA PIPELINE
-- 06 - VALIDATION
-- ============================================================

USE CATALOG workspace;

-- ============================================================
-- RECORD COUNT RECONCILIATION
-- ============================================================

SELECT
    'Raw Transactions' AS dataset,
    COUNT(*) AS records
FROM workspace.bronze.transaction_details_raw

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
-- QUALITY TABLE RECONCILIATION
-- ============================================================

SELECT
    'Invalid Transactions' AS quality_check,
    COUNT(*) AS records
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

-- ============================================================
-- CLEAN TRANSACTIONS VALIDATION
-- ============================================================

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity,
    SUM(CASE WHEN total_unit_price IS NULL THEN 1 ELSE 0 END) AS null_total_unit_price,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN cleaned_product_sku IS NULL THEN 1 ELSE 0 END) AS null_cleaned_product_sku,
    SUM(CASE WHEN cleaned_product_brand IS NULL THEN 1 ELSE 0 END) AS null_cleaned_product_brand
FROM workspace.sari_silver.clean_transactions;

-- ============================================================
-- CLEAN LOYALTY VALIDATION
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
-- CLEANING RULE VALIDATION
-- ============================================================

-- SKU cleanup validation

SELECT COUNT(*) AS uncleaned_sku_records
FROM workspace.sari_silver.clean_transactions
WHERE cleaned_product_sku LIKE '%$%'
   OR cleaned_product_sku LIKE '%<<%'
   OR cleaned_product_sku LIKE '%*%';

-- Receipt number cleanup validation

SELECT COUNT(*) AS uncleaned_receipts
FROM workspace.sari_silver.clean_transactions
WHERE cleaned_receipt_number LIKE '%-%';

-- Branch standardization validation

SELECT COUNT(*) AS non_uppercase_branches
FROM workspace.sari_silver.clean_transactions
WHERE branch_upper <> UPPER(branch_upper);

-- Product brand enrichment validation

SELECT
    cleaned_product_brand,
    COUNT(*) AS records
FROM workspace.sari_silver.clean_transactions
GROUP BY cleaned_product_brand
ORDER BY records DESC;

-- ============================================================
-- DATE VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS receipt_after_transaction_more_than_1_day
FROM workspace.sari_silver.clean_transactions
WHERE TRY_TO_TIMESTAMP(receipt_date, 'M/d/yy H:mm')
      > transaction_date + INTERVAL 1 DAY;

-- ============================================================
-- AGE VALIDATION
-- ============================================================

SELECT
    MIN(age_at_registration) AS minimum_age,
    MAX(age_at_registration) AS maximum_age
FROM workspace.sari_silver.clean_loyalty
WHERE age_at_registration IS NOT NULL;

-- ============================================================
-- SAMPLE REVIEW
-- ============================================================

SELECT *
FROM workspace.sari_silver.clean_transactions
LIMIT 20;

SELECT *
FROM workspace.sari_silver.clean_loyalty
LIMIT 20;
