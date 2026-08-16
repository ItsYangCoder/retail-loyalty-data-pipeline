-- ============================================================
-- SARI-SARI STORE DATA PIPELINE
-- 02 - DATA QUALITY CHECKS
-- ============================================================

USE CATALOG workspace;
USE SCHEMA sari_quality;


-- ============================================================
-- 1. CHECK TOTAL NUMBER OF BRONZE RECORDS
-- ============================================================

SELECT COUNT(*) AS total_bronze_rows
FROM workspace.sari_bronze.sari_sari_transactions_raw;


-- ============================================================
-- 2. CHECK MISSING TRANSACTION ID
-- ============================================================

SELECT COUNT(*) AS missing_transaction_id
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Transaction_ID IS NULL
   OR Transaction_ID = '';


-- ============================================================
-- 3. CHECK MISSING DATE
-- ============================================================

SELECT COUNT(*) AS missing_date
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Date IS NULL
   OR Date = '';


-- ============================================================
-- 4. CHECK MISSING ITEM
-- ============================================================

SELECT COUNT(*) AS missing_item
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Item IS NULL
   OR Item = '';


-- ============================================================
-- 5. CHECK MISSING QUANTITY
-- ============================================================

SELECT COUNT(*) AS missing_quantity
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Quantity IS NULL
   OR Quantity = '';


-- ============================================================
-- 6. CHECK MISSING UNIT PRICE
-- ============================================================

SELECT COUNT(*) AS missing_unit_price
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Unit_Price IS NULL
   OR Unit_Price = '';


-- ============================================================
-- 7. CHECK MISSING TOTAL AMOUNT
-- ============================================================

SELECT COUNT(*) AS missing_total_amount
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Total_Amount IS NULL
   OR Total_Amount = '';


-- ============================================================
-- 8. CHECK MISSING PAYMENT METHOD
-- ============================================================

SELECT COUNT(*) AS missing_payment_method
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Payment_Method IS NULL
   OR Payment_Method = '';


-- ============================================================
-- 9. CHECK MISSING CUSTOMER TYPE
-- ============================================================

SELECT COUNT(*) AS missing_customer_type
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Customer_Type IS NULL
   OR Customer_Type = '';


-- ============================================================
-- 10. CHECK DUPLICATE TRANSACTION IDs
-- ============================================================

SELECT
    Transaction_ID,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
GROUP BY Transaction_ID
HAVING COUNT(*) > 1
ORDER BY Transaction_ID;


-- ============================================================
-- 11. COUNT HOW MANY TRANSACTION IDs ARE DUPLICATED
-- ============================================================

SELECT COUNT(*) AS duplicated_transaction_ids
FROM (
    SELECT Transaction_ID
    FROM workspace.sari_bronze.sari_sari_transactions_raw
    GROUP BY Transaction_ID
    HAVING COUNT(*) > 1
);


-- ============================================================
-- 12. CHECK ALL QUANTITY VALUES
-- ============================================================

SELECT
    Quantity,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
GROUP BY Quantity
ORDER BY Quantity;


-- ============================================================
-- 13. CHECK INVALID QUANTITY VALUE 'two'
-- ============================================================

SELECT COUNT(*) AS invalid_quantity_two
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Quantity = 'two';


-- ============================================================
-- 14. CHECK SUSPICIOUSLY HIGH QUANTITY
-- ============================================================

SELECT
    Transaction_ID,
    Item,
    Quantity,
    Unit_Price,
    Total_Amount
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Quantity = '353';


-- ============================================================
-- 15. CHECK NEGATIVE OR ZERO UNIT PRICE
-- ============================================================

SELECT
    Transaction_ID,
    Item,
    Unit_Price
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE CAST(Unit_Price AS DOUBLE) <= 0;


-- ============================================================
-- 16. COUNT NEGATIVE OR ZERO UNIT PRICE
-- ============================================================

SELECT COUNT(*) AS invalid_unit_price
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE CAST(Unit_Price AS DOUBLE) <= 0;


-- ============================================================
-- 17. CHECK VERY HIGH UNIT PRICE
-- ============================================================

SELECT
    Transaction_ID,
    Item,
    Unit_Price,
    Quantity,
    Total_Amount
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE CAST(Unit_Price AS DOUBLE) > 500;


-- ============================================================
-- 18. CHECK NEGATIVE OR ZERO TOTAL AMOUNT
-- ============================================================

SELECT
    Transaction_ID,
    Item,
    Quantity,
    Unit_Price,
    Total_Amount
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE CAST(Total_Amount AS DOUBLE) <= 0;


-- ============================================================
-- 19. COUNT NEGATIVE OR ZERO TOTAL AMOUNT
-- ============================================================

SELECT COUNT(*) AS invalid_total_amount
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE CAST(Total_Amount AS DOUBLE) <= 0;


-- ============================================================
-- 20. CHECK WHETHER TOTAL AMOUNT MATCHES
--     QUANTITY × UNIT PRICE
-- ============================================================

SELECT
    Transaction_ID,
    Item,
    Quantity,
    Unit_Price,
    Total_Amount,
    ROUND(
        TRY_CAST(Quantity AS DOUBLE) *
        TRY_CAST(Unit_Price AS DOUBLE),
        2
    ) AS calculated_total

FROM workspace.sari_bronze.sari_sari_transactions_raw

WHERE TRY_CAST(Quantity AS DOUBLE) IS NOT NULL
  AND TRY_CAST(Unit_Price AS DOUBLE) IS NOT NULL
  AND TRY_CAST(Total_Amount AS DOUBLE) IS NOT NULL

  AND ROUND(
        TRY_CAST(Quantity AS DOUBLE) *
        TRY_CAST(Unit_Price AS DOUBLE),
        2
      )
      <>
      ROUND(
        TRY_CAST(Total_Amount AS DOUBLE),
        2
      );


-- ============================================================
-- 21. COUNT RECORDS WITH WRONG TOTAL AMOUNT
-- ============================================================

SELECT COUNT(*) AS incorrect_total_amount
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE TRY_CAST(Quantity AS DOUBLE) IS NOT NULL
  AND TRY_CAST(Unit_Price AS DOUBLE) IS NOT NULL
  AND TRY_CAST(Total_Amount AS DOUBLE) IS NOT NULL
  AND ROUND(
        TRY_CAST(Quantity AS DOUBLE) *
        TRY_CAST(Unit_Price AS DOUBLE),
        2
      )
      <>
      ROUND(
        TRY_CAST(Total_Amount AS DOUBLE),
        2
      );


-- ============================================================
-- 22. CHECK PAYMENT METHOD VALUES
-- ============================================================

SELECT
    Payment_Method,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
GROUP BY Payment_Method
ORDER BY number_of_records DESC;


-- ============================================================
-- 23. CHECK INVALID PAYMENT METHODS
-- ============================================================

SELECT
    Payment_Method,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Payment_Method NOT IN ('Cash', 'GCash', 'PayMaya')
  AND Payment_Method IS NOT NULL
GROUP BY Payment_Method;


-- ============================================================
-- 24. CHECK CUSTOMER TYPE VALUES
-- ============================================================

SELECT
    Customer_Type,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
GROUP BY Customer_Type
ORDER BY number_of_records DESC;


-- ============================================================
-- 25. CHECK INVALID CUSTOMER TYPES
-- ============================================================

SELECT
    Customer_Type,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
WHERE Customer_Type NOT IN ('Walk-in', 'Neighbor', 'Regular')
  AND Customer_Type IS NOT NULL
GROUP BY Customer_Type;


-- ============================================================
-- 26. CHECK ITEM VALUES
-- ============================================================

SELECT
    Item,
    COUNT(*) AS number_of_records
FROM workspace.sari_bronze.sari_sari_transactions_raw
GROUP BY Item
ORDER BY number_of_records DESC;


-- ============================================================
-- 27. CHECK DATE RANGE
-- ============================================================

SELECT
    MIN(Date) AS earliest_date,
    MAX(Date) AS latest_date
FROM workspace.sari_bronze.sari_sari_transactions_raw;