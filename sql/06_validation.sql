-- 06 VALIDATION
-- Checks row counts, data quality, duplicates, and integration results.
USE CATALOG workspace;
-- Check row counts across the pipeline
SELECT
    'Raw Transactions' AS dataset,
    COUNT(*) AS records
FROM workspace.bronze.transaction_details_raw
UNION ALL
SELECT
    'Current Transactions',
    COUNT(*)
FROM workspace.bronze.transaction_details_current
UNION ALL
SELECT
    'Clean Transactions',
    COUNT(*)
FROM workspace.silver.clean_transactions
UNION ALL
SELECT
    'Integrated Transactions',
    COUNT(*)
FROM workspace.silver.integrated_transactions
UNION ALL
SELECT
    'Raw Loyalty',
    COUNT(*)
FROM workspace.bronze.loyalty_cardholders_raw
UNION ALL
SELECT
    'Clean Loyalty',
    COUNT(*)
FROM workspace.silver.clean_loyalty;
-- Check quality issue counts
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
-- Check important fields in clean transactions
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity,
    SUM(CASE WHEN recorded_sales IS NULL THEN 1 ELSE 0 END) AS null_recorded_sales,
    SUM(CASE WHEN recorded_sales <= 0 THEN 1 ELSE 0 END) AS invalid_recorded_sales,
    SUM(CASE WHEN calculated_unit_price IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN product_sku IS NULL THEN 1 ELSE 0 END) AS null_product_sku,
    SUM(CASE WHEN product_brand IS NULL THEN 1 ELSE 0 END) AS null_product_brand
FROM workspace.silver.clean_transactions;
-- Check important fields in clean loyalty data
SELECT
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN registered_date IS NULL THEN 1 ELSE 0 END) AS null_registered_date,
    SUM(CASE WHEN birthday IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_birthday,
    SUM(CASE WHEN age_at_registration < 0 THEN 1 ELSE 0 END) AS invalid_age
FROM workspace.silver.clean_loyalty;
-- Check transaction duplicate keys
SELECT
    transaction_id,
    product_sku,
    COUNT(*) AS duplicate_count
FROM workspace.silver.clean_transactions
GROUP BY
    transaction_id,
    product_sku
HAVING COUNT(*) > 1;
-- Check duplicate loyalty member IDs
SELECT
    user_id,
    COUNT(*) AS duplicate_count
FROM workspace.silver.clean_loyalty
GROUP BY user_id
HAVING COUNT(*) > 1;
-- Check if unwanted SKU symbols still exist
SELECT
    COUNT(*) AS uncleaned_sku_records
FROM workspace.silver.clean_transactions
WHERE product_sku LIKE '%$%'
   OR product_sku LIKE '%<<%'
   OR product_sku LIKE '%*%';
-- Check if receipt numbers still contain hyphens
SELECT
    COUNT(*) AS uncleaned_receipts
FROM workspace.silver.clean_transactions
WHERE receipt_number LIKE '%-%';
-- Check if branch names are standardized to uppercase
SELECT
    COUNT(*) AS non_uppercase_branches
FROM workspace.silver.clean_transactions
WHERE branch <> UPPER(branch);
-- Check if any product brands are still missing
SELECT
    COUNT(*) AS missing_product_brands
FROM workspace.silver.clean_transactions
WHERE product_brand IS NULL;
-- Review product brand distribution
SELECT
    product_brand,
    COUNT(*) AS records
FROM workspace.silver.clean_transactions
GROUP BY product_brand
ORDER BY records DESC;
-- Check receipt date quality flags
SELECT
    data_quality_flag,
    COUNT(*) AS records
FROM workspace.silver.clean_transactions
GROUP BY data_quality_flag;
-- Check birthday status
SELECT
    birthday_status,
    COUNT(*) AS records
FROM workspace.silver.clean_loyalty
GROUP BY birthday_status;
-- Check age range
SELECT
    MIN(age_at_registration) AS minimum_age,
    MAX(age_at_registration) AS maximum_age
FROM workspace.silver.clean_loyalty
WHERE age_at_registration IS NOT NULL;
-- Check that integration kept the same number of transactions
SELECT
    'Clean Transactions' AS dataset,
    COUNT(*) AS records
FROM workspace.silver.clean_transactions
UNION ALL
SELECT
    'Integrated Transactions',
    COUNT(*)
FROM workspace.silver.integrated_transactions;
-- Check that sales did not change after integration
SELECT
    'Before Integration' AS stage,
    ROUND(SUM(recorded_sales), 2) AS total_sales
FROM workspace.silver.clean_transactions
UNION ALL
SELECT
    'After Integration',
    ROUND(SUM(recorded_sales), 2)
FROM workspace.silver.integrated_transactions;
-- Check loyalty matches after integration
SELECT
    loyalty_match_status,
    COUNT(*) AS records
FROM workspace.silver.integrated_transactions
GROUP BY loyalty_match_status;
-- Preview final integrated data
SELECT *
FROM workspace.silver.integrated_transactions
LIMIT 20; 