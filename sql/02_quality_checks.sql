-- ============================================================
-- RETAIL TRANSACTIONS + LOYALTY CUSTOMER DATA PIPELINE
-- 02 - DATA QUALITY CHECKS
-- ============================================================
--
-- PURPOSE:
-- Identify records that should be:
--
-- 1. Excluded from the clean transaction table
-- 2. Retained but flagged for review
-- 3. Retained as loyalty members but with invalid birthdays
--
-- Quality outputs:
-- workspace.quality.invalid_transactions
-- workspace.quality.receipt_date_issues
-- workspace.quality.invalid_loyalty_birthdays
-- ============================================================


USE CATALOG workspace;
USE SCHEMA quality;


-- ============================================================
-- 1. INVALID TRANSACTIONS
-- ============================================================
--
-- Business rule:
-- A transaction line cannot be used for sales analysis when:
--
--     quantity <= 0
-- OR
--     total_unit_price <= 0
--
-- These records are quarantined in Quality and excluded
-- from the Silver clean transaction table.
--
-- Expected result: 6 rows
-- ============================================================

CREATE OR REPLACE TABLE workspace.quality.invalid_transactions AS

SELECT

    `# customer_id` AS customer_id,
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

        WHEN quantity IS NULL
            THEN 'Invalid quantity'

        WHEN quantity <= 0
            THEN 'Quantity <= 0'

        WHEN total_unit_price IS NULL
            THEN 'Invalid recorded sales'

        WHEN total_unit_price <= 0
            THEN 'Recorded sales <= 0'

        ELSE 'Unknown'

    END AS exclusion_reason

FROM workspace.bronze.transaction_details_raw

WHERE quantity IS NULL
   OR quantity <= 0
   OR total_unit_price IS NULL
   OR total_unit_price <= 0;


-- ============================================================
-- 2. VALIDATE INVALID TRANSACTION COUNT
-- ============================================================
--
-- Expected:
-- 6 rows total
--
-- Quantity <= 0       = 2
-- Recorded sales <= 0 = 4
-- ============================================================

SELECT
    exclusion_reason,
    COUNT(*) AS row_count

FROM workspace.quality.invalid_transactions

GROUP BY exclusion_reason

ORDER BY row_count DESC;


-- ============================================================
-- 3. RECEIPT DATE QUALITY ISSUES
-- ============================================================
--
-- receipt_date is stored as STRING in Bronze.
--
-- Some source values use:
-- M/d/yy H:mm
--
-- Example:
-- 7/11/24 14:50
--
-- Engineering decision:
-- A receipt date more than 1 day AFTER the transaction date
-- is suspicious.
--
-- Unlike invalid quantity/sales records, these rows are NOT
-- removed. They are retained and flagged for review.
--
-- Only otherwise-valid transaction records are checked.
--
-- Expected result: 48 rows
-- ============================================================

CREATE OR REPLACE TABLE workspace.quality.receipt_date_issues AS

SELECT

    `# customer_id` AS customer_id,
    transaction_id,

    TRY_TO_TIMESTAMP(
        receipt_date,
        'M/d/yy H:mm'
    ) AS receipt_date,

    transaction_date,
    receipt_number,
    product_sku,
    product_brand,
    quantity,

    -- Source field is the recorded value of the transaction line
    total_unit_price AS recorded_sales,

    retailer,
    branch,

    'Receipt date is more than 1 day after transaction date'
        AS quality_issue

FROM workspace.bronze.transaction_details_raw

WHERE quantity > 0
  AND total_unit_price > 0

  AND TRY_TO_TIMESTAMP(
        receipt_date,
        'M/d/yy H:mm'
      ) > transaction_date + INTERVAL 1 DAY;


-- ============================================================
-- 4. VALIDATE RECEIPT DATE ISSUES
-- ============================================================
--
-- Expected result: 48
-- ============================================================

SELECT
    COUNT(*) AS receipt_date_issue_rows

FROM workspace.quality.receipt_date_issues;


-- ============================================================
-- 5. INVALID LOYALTY BIRTHDAYS
-- ============================================================
--
-- Loyalty members should NOT be deleted just because their
-- birthday is incorrect.
--
-- Instead:
--     preserve the member
--     identify the bad birthday
--     clean/null the birthday later in Silver
--
-- Business rule:
-- Age greater than 110 is considered unreasonable.
--
-- Expected result: 5 rows
-- ============================================================

CREATE OR REPLACE TABLE workspace.quality.invalid_loyalty_birthdays AS

SELECT

    user_id,

    birthday AS original_birthday,

    registered_date,

    CASE

        WHEN birthday IS NULL
            THEN 'Missing birthday'

        WHEN birthday > CAST(registered_date AS DATE)
            THEN 'Birthday after registration date'

        WHEN FLOOR(
            MONTHS_BETWEEN(
                CAST(registered_date AS DATE),
                birthday
            ) / 12
        ) > 110
            THEN 'Age over 110'

        ELSE 'Invalid birthday'

    END AS quality_issue

FROM workspace.bronze.loyalty_cardholders_raw

WHERE birthday IS NULL

   OR birthday > CAST(registered_date AS DATE)

   OR FLOOR(
        MONTHS_BETWEEN(
            CAST(registered_date AS DATE),
            birthday
        ) / 12
      ) > 110;


-- ============================================================
-- 6. VALIDATE INVALID LOYALTY BIRTHDAYS
-- ============================================================
--
-- Expected result:
--
-- Age over 110 = 5
-- ============================================================

SELECT
    quality_issue,
    COUNT(*) AS row_count

FROM workspace.quality.invalid_loyalty_birthdays

GROUP BY quality_issue

ORDER BY row_count DESC;


-- ============================================================
-- 7. QUALITY SUMMARY
-- ============================================================
--
-- Expected current baseline:
--
-- Invalid Transactions      = 6
-- Receipt Date Issues       = 48
-- Invalid Loyalty Birthdays = 5
-- ============================================================

SELECT
    'Invalid Transactions' AS quality_check,
    COUNT(*) AS row_count
FROM workspace.quality.invalid_transactions

UNION ALL

SELECT
    'Receipt Date Issues' AS quality_check,
    COUNT(*) AS row_count
FROM workspace.quality.receipt_date_issues

UNION ALL

SELECT
    'Invalid Loyalty Birthdays' AS quality_check,
    COUNT(*) AS row_count
FROM workspace.quality.invalid_loyalty_birthdays;