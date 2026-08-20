--  SILVER LAYER: TRANSACTIONS DETAILS 

CREATE  OR REPLACE TABLE workspace.sari_silver.clean_transactions AS
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
    -- clean and trim product_sku (remove $, <<, *)
    TRIM(
        REPLACE(
            REPLACE(
                REPLACE(product_sku, '$', ''), 
            '<<', ''), 
        '*', '')
    ) AS cleaned_product_sku,

    -- change 'branch' formatting to upper case (for consistency)
    UPPER(branch) AS branch_upper,

    -- clean 'receipt_number' formatting and remove hyphens (for consistency rin)
    REPLACE(TRIM(receipt_number), '-', '') AS cleaned_receipt_number,

    -- compute unit_price (total_unit_price / quantity using nullif 
    (total_unit_price / NULLIF(quantity, 0)) AS unit_price,

    -- compute transaction month and receipt month
    EXTRACT(MONTH FROM transaction_date) AS transaction_month,
    EXTRACT(MONTH FROM receipt_date) AS receipt_month,
    CASE 
        WHEN product_brand IS NULL AND product_sku LIKE '%DP%' THEN 'Datu Puti'
        WHEN product_brand IS NULL AND product_sku LIKE '%UFC%' THEN 'UFC'
        ELSE product_brand 
    END AS cleaned_product_brand
FROM  workspace.sari_bronze.sari_sari_transactions_raw;


--  SILVER LAYER: LOYALTY CARDHOLDERS
CREATE OR REPLACE TABLE workspace.sari_silver.clean_loyalty AS
    SELECT 
    *, 
    TRY_TO_DATE(birthday, 'dd/MM/yyyy') AS birthday_formatted,
    DATEDIFF(YEAR, TRY_TO_DATE(birthday, 'dd/MM/yyyy'), registered_date) AS age_at_registration
FROM workspace.bronze.loyalty_cardholders_raw;


SELECT COUNT(*)
FROM workspace.sari_silver.clean_transactions;
SELECT COUNT(*)
FROM workspace.sari_silver.clean_loyalty;

SELECT *
FROM workspace.sari_silver.clean_transactions
LIMIT 20;

SELECT *
FROM workspace.sari_silver.clean_loyalty
LIMIT 20;
