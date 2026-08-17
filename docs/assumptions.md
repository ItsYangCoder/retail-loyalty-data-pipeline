# Retail Transactions + Loyalty Customer Data Pipeline

## Assumptions and Engineering Decisions

This document records the assumptions, business rules, and engineering decisions used in the Retail Transactions + Loyalty Customer Data Pipeline.

---

## 1. Data Sources

The pipeline uses two source datasets:

### Transaction Details

The transaction dataset contains sales information such as:

* customer ID
* transaction ID
* receipt date
* transaction date
* receipt number
* product SKU
* product brand
* quantity
* sales amount
* retailer
* branch

The original dataset contains **3,167 transaction rows**.

The grain is:

**One row represents one product line within a transaction.**

A transaction may therefore appear in more than one row when multiple products were purchased.

---

### Loyalty Cardholders

The loyalty dataset contains customer information such as:

* user ID
* birthday
* registered date

The original dataset contains **5,949 registered loyalty members**.

The grain is:

**One row represents one registered loyalty member.**

The main identifier is:

`user_id`

---

## 2. Relationship Between the Two Datasets

The transaction and loyalty datasets are related using:

`transaction.customer_id = loyalty.user_id`

The relationship is:

**Many transaction records → one loyalty member**

The project assumes that `customer_id` in the transaction dataset represents the same customer identifier as `user_id` in the loyalty dataset.

The data was validated and transaction customer IDs were found to match loyalty user IDs.

---

## 3. Bronze Layer

The Bronze layer preserves the source data before cleaning.

Schemas and tables in Bronze should retain the original values as much as possible.

Bronze data should not be manually corrected.

The purpose of Bronze is to provide:

* raw data preservation
* traceability
* troubleshooting
* reprocessing capability

Cleaning rules are applied in Silver instead of directly modifying Bronze.

---

## 4. Transaction Grain

One transaction can contain multiple product rows.

Therefore:

`transaction_id`

alone is not assumed to uniquely identify every physical row.

For product-level analysis, the effective grain is:

**one product line per transaction**

Transaction-level metrics should therefore use distinct transaction IDs where appropriate.

For example:

`COUNT(DISTINCT transaction_id)`

should be used when calculating the number of transactions instead of simply counting rows.

---

## 5. Loyalty Grain

Each loyalty record represents one registered customer.

`user_id`

is treated as the loyalty-member identifier.

Missing or duplicate user IDs should be investigated because they could affect customer-level joins and loyalty calculations.

No duplicate or missing loyalty member IDs were identified in the documented quality checks.

---

## 6. Text Standardization

Text fields may contain inconsistent spacing or formatting.

Text fields such as:

* product SKU
* product brand
* retailer
* branch
* receipt number

should be standardized where appropriate.

Leading and trailing spaces should be removed.

Repeated spaces may also be normalized.

The purpose is to prevent the same value from appearing as multiple categories because of formatting differences.

---

## 7. Product SKU

Product SKUs may contain unnecessary symbols.

Examples may include characters such as:

`$`

`<<`

`*`

These symbols may be removed or standardized when they are clearly formatting artifacts.

The original Bronze value should still remain available.

The cleaned SKU should be created in Silver.

---

## 8. Product Brand

Some transaction records contain missing product brands.

A missing brand should only be filled when the product SKU provides clear evidence of the brand.

For example:

* SKU containing an explicit Datu Puti indicator may be assigned `Datu Puti`.
* SKU containing an explicit UFC indicator may be assigned `UFC`.

The project documentation identified **3 missing brands** that could be filled using deterministic SKU information.

Brands should not be guessed when the SKU does not provide enough evidence.

---

## 9. Quantity and Sales Validation

Quantity and sales are critical measures for analysis.

A normal valid transaction line should have:

`quantity > 0`

and

`sales amount > 0`

Records with zero, negative, missing, or otherwise invalid critical measures should not be included in business KPIs.

The documented data-quality check identified **6 invalid transaction rows** based on these rules.

These rows should be:

* preserved in the raw Bronze data
* recorded or identified in the Quality layer
* excluded from the clean analytical Silver transactions

They should not simply be deleted from the source.

---

## 10. Unit Price

When needed, unit price may be calculated as:

`Sales Amount / Quantity`

Division by zero must be prevented.

Unit price should only be calculated when quantity is greater than zero.

---

## 11. Receipt Date and Transaction Date

The transaction dataset contains both:

* `receipt_date`
* `transaction_date`

The project uses **transaction_date as the primary date for time-based sales analysis**.

The documented quality check identified **48 records** where the receipt date was more than one day away from the transaction date.

These records should not automatically be deleted.

Instead:

* keep the transaction
* use transaction_date for sales-period analysis
* flag the receipt-date issue for review

The pipeline should not invent a replacement receipt date.

---

## 12. Receipt Number

Receipt numbers should be treated carefully because they may contain:

* hyphens
* spaces
* leading zeroes
* long numeric-looking identifiers

Receipt numbers should be treated as text rather than mathematical values.

Formatting may be standardized in Silver, but the original Bronze value should remain unchanged.

---

## 13. Loyalty Birthday Validation

Birthday is used to derive customer age.

A birthday is considered valid only if it:

* can be parsed as a valid date
* occurs before the registration date
* produces a realistic age

The project uses a maximum reasonable age of **110 years** for validation.

The quality checks identified **5 invalid or implausible birthdays**.

For these records:

* retain the loyalty member
* do not invent a new birthday
* set the cleaned birthday to NULL when it cannot be trusted
* classify age information as Unknown or Invalid when necessary

Removing the entire loyalty member is not required simply because birthday data is invalid.

---

## 14. Customer Age

Customer age should be calculated from valid birthday information.

For purchasing-behavior analysis, customer age should represent age at the relevant transaction or analysis date, depending on the agreed implementation.

Age groups should be standardized so the same ranges are used throughout the project.

Example groups include:

* Under 18
* 18–24
* 25–34
* 35–44
* 45–54
* 55–64
* 65+

Customers whose birthday cannot be safely validated should not be assigned a fabricated age.

---

## 15. Silver Layer

The Silver layer contains cleaned and standardized data.

Expected Silver outputs include cleaned versions of:

* transaction data
* loyalty/customer data

Silver is responsible for:

* data type conversion
* text normalization
* validation of quantities and sales
* product-brand completion when supported by evidence
* birthday validation
* date preparation
* data-quality flags
* removal of analytically invalid transaction lines

Bronze remains unchanged.

---

## 16. Integration

The cleaned transaction and loyalty datasets are joined using:

`customer_id = user_id`

The integrated dataset combines sales information with customer attributes.

After the join, a transaction record may contain:

* transaction information
* product information
* retailer information
* customer birthday
* customer age
* customer age group

The join must not unnecessarily increase the number of transaction product lines.

A row-count comparison should be performed before and after integration.

---

## 17. Gold Layer

Gold contains business-ready analytical tables.

Gold should use cleaned and integrated data rather than raw Bronze records.

The main analytical question is:

**How does purchasing behavior differ by customer age group, retailer, product brand, and month?**

Gold may therefore summarize:

* recorded sales
* units sold
* unique transactions
* average basket value
* age-group performance
* retailer performance
* brand performance
* monthly performance

---

## 18. Metric Definitions

### Recorded Sales

The sales value recorded for valid transaction product lines.

### Units Sold

`SUM(quantity)`

using valid transaction records.

### Transactions

`COUNT(DISTINCT transaction_id)`

because one transaction can contain multiple product lines.

### Average Basket

`Recorded Sales / Unique Transactions`

The same metric definition should be used consistently throughout Gold and the dashboard.

---

## 19. Quality Layer

The Quality layer stores or identifies records requiring investigation.

Examples include:

* invalid transaction quantities
* invalid sales values
* unusual receipt dates
* invalid loyalty birthdays
* other rejected or suspicious records

Quality records are preserved for auditability rather than silently discarded.

---

## 20. Validation

The pipeline should be validated at each major stage.

Validation should include:

* Bronze source row counts
* Silver row counts
* number of excluded invalid transactions
* loyalty-member counts
* join match rate
* null checks
* duplicate checks
* Silver-to-Gold sales reconciliation
* transaction-count reconciliation

Unexpected differences should be investigated before the dashboard is considered final.

---

## 21. Repeatability

The pipeline should be reusable when new source records arrive.

The expected process is:

`New Source Data → Bronze → Quality Checks → Silver → Integration → Gold → Validation → Dashboard`

Cleaning should be implemented through SQL rules rather than manual editing of source records.

This allows the same transformations and validations to be applied consistently to future batches.

---

## 22. General Engineering Principle

The pipeline follows:

**Preserve → Validate → Clean → Integrate → Transform → Validate → Present**

This ensures that the analysis is:

* traceable
* repeatable
* explainable
* auditable
* reliable
