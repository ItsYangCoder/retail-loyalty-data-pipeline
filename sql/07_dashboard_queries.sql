-- 07_dashboard_queries.sql

USE CATALOG workspace;


-- 1. KPI CARDS

SELECT
    ROUND(SUM(recorded_sales), 2) AS total_sales,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS purchasing_members,
    ROUND(
        SUM(recorded_sales) / COUNT(DISTINCT transaction_id),
        2
    ) AS average_basket
FROM workspace.gold.gold_customer_transactions;



-- 2. MONTHLY SALES TREND

SELECT
    DATE_TRUNC('MONTH', transaction_date) AS sales_month,
    ROUND(SUM(recorded_sales), 2) AS total_sales,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(quantity) AS units_sold
FROM workspace.gold.gold_customer_transactions
GROUP BY DATE_TRUNC('MONTH', transaction_date)
ORDER BY sales_month;



-- 3. TOP PRODUCTS

SELECT
    product_sku,
    ROUND(SUM(recorded_sales), 2) AS total_sales,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT transaction_id) AS transactions
FROM workspace.gold.gold_customer_transactions
WHERE product_sku IS NOT NULL
GROUP BY product_sku
ORDER BY total_sales DESC
LIMIT 10;



-- 4. RETAILER PERFORMANCE

SELECT
    retailer,
    ROUND(SUM(recorded_sales), 2) AS total_sales,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(quantity) AS units_sold
FROM workspace.gold.gold_customer_transactions
WHERE retailer IS NOT NULL
GROUP BY retailer
ORDER BY total_sales DESC;



-- 5. BRAND PERFORMANCE

SELECT
    product_brand,
    ROUND(SUM(recorded_sales), 2) AS total_sales,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT transaction_id) AS transactions
FROM workspace.gold.gold_customer_transactions
WHERE product_brand IS NOT NULL
GROUP BY product_brand
ORDER BY total_sales DESC;