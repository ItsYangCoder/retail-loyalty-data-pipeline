-- ============================================================
-- 04_gold.sql
-- GOLD LAYER
--
-- Purpose:
-- Join cleaned transaction and loyalty data
-- into one business-ready table for reporting.
-- ============================================================

USE CATALOG workspace;
USE SCHEMA gold;



-- 1. CREATE GOLD CUSTOMER TRANSACTIONS


CREATE OR REPLACE TABLE workspace.gold.gold_customer_transactions AS

SELECT
    -- Transaction information
    t.customer_id,
    t.transaction_id,
    t.receipt_date,
    t.transaction_date,
    t.receipt_number,

    -- Product information
    t.product_sku,
    t.product_brand,

    -- Sales information
    t.quantity,
    t.recorded_sales,
    t.calculated_unit_price,

    -- Store information
    t.retailer,
    t.branch,

    -- Time information
    t.transaction_month,

    -- Loyalty information
    c.birthday,
    c.registered_date,

    -- Calculate customer age at time of purchase
    CASE
        WHEN c.birthday IS NULL THEN NULL

        ELSE FLOOR(
            DATEDIFF(
                DATE(t.transaction_date),
                c.birthday
            ) / 365.25
        )
    END AS age_at_purchase,

    -- Transaction quality status
    t.data_quality_flag

FROM workspace.silver.clean_transactions t

LEFT JOIN workspace.silver.clean_loyalty_cardholders c
    ON t.customer_id = c.user_id;



-- 2. ADD AGE GROUP


CREATE OR REPLACE TABLE workspace.gold.gold_customer_transactions AS

SELECT
    *,

    CASE
        WHEN age_at_purchase IS NULL THEN 'Unknown/Invalid'
        WHEN age_at_purchase < 18 THEN 'Under 18'
        WHEN age_at_purchase BETWEEN 18 AND 24 THEN '18-24'
        WHEN age_at_purchase BETWEEN 25 AND 34 THEN '25-34'
        WHEN age_at_purchase BETWEEN 35 AND 44 THEN '35-44'
        WHEN age_at_purchase BETWEEN 45 AND 54 THEN '45-54'
        WHEN age_at_purchase BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_group

FROM workspace.gold.gold_customer_transactions;




-- 3. CHECK GOLD ROW COUNT

SELECT
    COUNT(*) AS gold_rows
FROM workspace.gold.gold_customer_transactions;




-- 4. CHECK FOR UNMATCHED LOYALTY CUSTOMERS

SELECT
    COUNT(*) AS unmatched_customers
FROM workspace.gold.gold_customer_transactions
WHERE registered_date IS NULL;




-- 5. CHECK MAIN BUSINESS TOTALS


SELECT
    ROUND(SUM(recorded_sales), 2) AS total_recorded_sales,

    COUNT(DISTINCT transaction_id) AS total_transactions,

    SUM(quantity) AS total_units_sold,

    COUNT(DISTINCT customer_id) AS purchasing_members,

    ROUND(
        SUM(recorded_sales)
        / COUNT(DISTINCT transaction_id),
        2
    ) AS average_basket

FROM workspace.gold.gold_customer_transactions;



-- 6. CHECK GOLD DATA


SELECT *
FROM workspace.gold.gold_customer_transactions
LIMIT 20;