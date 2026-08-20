USE CATALOG workspace;
USE SCHEMA gold;

-- GOLD LAYER: INTEGRATED LOYALTY TRANSACTIONS

CREATE OR REPLACE TABLE workspace.gold.loyalty_transactions AS
SELECT
    -- Transaction details
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
-- Loyalty details
    loyalty_user_id,
    birthday,
    registered_date,
    age_at_registration,
    age_at_purchase,
    age_group,
    birthday_status,
    loyalty_match_status
FROM workspace.silver.integrated_transactions;
