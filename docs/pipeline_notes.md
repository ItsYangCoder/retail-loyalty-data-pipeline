# Retail Transactions + Loyalty Customer Data Pipeline

## Pipeline Notes

## 1. Project Objective

The objective of this project is to build a repeatable Databricks SQL data pipeline that transforms raw retail transaction and loyalty-customer data into reliable business-ready tables and dashboard visualizations.

The final pipeline follows:

`SOURCE → BRONZE → QUALITY → SILVER → INTEGRATION → GOLD → VALIDATION → DASHBOARD`

The project uses the Medallion Architecture to separate raw, cleaned, and analytical data.

---

## 2. Source Data

Two source datasets are used.

### Transaction Details

Original records:

**3,167 rows**

Grain:

**One product line per transaction**

Important fields include:

* customer_id
* transaction_id
* receipt_date
* transaction_date
* receipt_number
* product_sku
* product_brand
* quantity
* sales amount
* retailer
* branch

### Loyalty Cardholders

Original records:

**5,949 registered members**

Grain:

**One row per registered loyalty member**

Important fields include:

* user_id
* birthday
* registered_date

### Relationship

The two datasets are connected through:

`transaction.customer_id = loyalty.user_id`

The relationship is many transaction product lines to one loyalty member.

---

# Pipeline Stages

## 3. `00_setup.sql` — Project Setup

Purpose:

Prepare the schemas used throughout the pipeline.

The project uses:

```text
workspace
│
├── bronze
├── silver
├── quality
└── gold
```

### Bronze

Raw source data.

### Silver

Cleaned and standardized data.

### Quality

Rejected, suspicious, or validation records.

### Gold

Business-ready analytical tables.

This setup separates the different responsibilities of each data layer.

---

## 4. `01_bronze.sql` — Bronze Ingestion

Purpose:

Load and preserve both source datasets.

Expected Bronze data:

```text
Bronze
├── transaction_details_raw
└── loyalty_cardholders_raw
```

The Bronze layer should contain source values before analytical cleaning.

### Bronze principle

**Do not clean the source directly.**

Bronze exists so the team can always compare transformed records with the original source.

### Transaction grain

One row represents one product line within a transaction.

### Loyalty grain

One row represents one registered loyalty member.

---

## 5. `02_quality_checks.sql` — Data Quality Profiling

Purpose:

Identify data-quality issues before building the clean Silver layer.

### Transaction checks

Quality checks should investigate:

* missing identifiers
* invalid quantity
* invalid sales values
* missing product brands
* text-formatting inconsistencies
* receipt-number formatting
* suspicious receipt dates
* duplicate or unusual transaction records

### Loyalty checks

Quality checks should investigate:

* missing user IDs
* duplicate user IDs
* invalid birthdays
* birthdays after registration date
* unrealistic customer ages

### Known quality findings

The documented project checks identified:

* **6 transaction rows** with invalid critical sales/quantity measures
* **48 transaction rows** requiring receipt-date review
* **3 missing product brands** that could be deterministically completed
* **5 invalid or implausible loyalty birthdays**

These records should be handled using explicit rules rather than manual source editing.

---

## 6. `03_silver.sql` — Silver Cleaning

Purpose:

Transform Bronze data into cleaned and standardized datasets.

Expected Silver outputs include:

```text
Silver
├── clean_transactions
└── clean_loyalty
```

### Transaction cleaning

The transaction cleaning process may include:

* trimming text
* standardizing product SKU
* standardizing branch and retailer values
* preserving receipt number as text
* validating quantity
* validating sales
* calculating unit price
* completing product brand when supported by SKU
* creating transaction month
* flagging receipt-date issues
* excluding invalid critical transaction rows

The **6 invalid transaction rows** should remain traceable through the Quality layer instead of being silently removed.

### Loyalty cleaning

The loyalty cleaning process includes:

* validating user IDs
* parsing birthday
* validating birthday against registration date
* checking realistic age
* deriving cleaned age
* creating customer age groups
* retaining customers even when birthday cannot be safely repaired

For invalid birthday values, the birthday may become NULL while the member remains in the dataset.

---

## 7. `04_integrate.sql` — Integration

Purpose:

Combine cleaned transaction records with cleaned loyalty data.

Join condition:

```sql
transaction.customer_id = loyalty.user_id
```

This enriches each valid transaction product line with customer information.

Possible integrated fields include:

```text
customer_id
transaction_id
transaction_date
receipt_date
receipt_number
product_sku
product_brand
quantity
sales
retailer
branch
birthday
age
age_group
```

### Join validation

Before accepting the integrated table, check:

* number of Silver transaction rows before join
* number of rows after join
* unmatched customer IDs
* unexpected row multiplication

The expected relationship is:

```text
Many Transaction Rows
        ↓
customer_id
        =
user_id
        ↓
One Loyalty Member
```

The integration should enrich transaction records without unnecessarily duplicating them.

---

## 8. `05_gold.sql` — Gold Business Tables

Purpose:

Convert the integrated clean data into tables designed for business analysis.

The main business question is:

**How does purchasing behavior differ by customer age group, retailer, product brand, and month?**

Suggested Gold outputs include:

```text
gold.kpi_summary
gold.monthly_performance
gold.brand_performance
gold.retailer_performance
gold.age_group_performance
```

Additional tables may be created when useful.

### KPI Summary

Possible metrics:

* total recorded sales
* units sold
* unique transactions
* average basket value
* purchasing loyalty members
* registered loyalty members
* active loyalty rate

### Monthly Performance

Grain:

**One row per month**

Possible measures:

* recorded sales
* units sold
* unique transactions
* average basket

### Brand Performance

Grain:

**One row per product brand**

Possible measures:

* recorded sales
* units sold
* transactions
* sales share

### Retailer Performance

Grain:

**One row per retailer**

Possible measures:

* recorded sales
* units sold
* transactions
* average basket

### Age Group Performance

Grain:

**One row per customer age group**

Possible measures:

* recorded sales
* units sold
* transactions
* purchasing members
* average basket

Gold tables should read from cleaned/integrated data rather than directly from raw Bronze tables.

---

## 9. Metric Logic

### Recorded Sales

Sum of valid transaction sales values.

### Units Sold

```text
SUM(quantity)
```

### Unique Transactions

```text
COUNT(DISTINCT transaction_id)
```

A distinct count is important because a transaction may contain several product rows.

### Average Basket

```text
Recorded Sales / Unique Transactions
```

### Active Loyalty Rate

When required:

```text
Purchasing Loyalty Members
--------------------------- × 100
Registered Loyalty Members
```

The denominator should represent the registered loyalty population.

---

## 10. `06_validation.sql` — Pipeline Validation

Purpose:

Confirm that transformations produced trustworthy results.

Validation should include:

### Source validation

```text
Transaction Bronze count
Loyalty Bronze count
```

### Silver validation

Check:

* invalid quantity records
* invalid sales records
* duplicate identifiers
* null critical fields
* birthday validation
* cleaned categories

### Integration validation

Check:

* matching customer IDs
* unmatched loyalty members where relevant
* row-count changes after join
* accidental duplicate rows

### Gold reconciliation

Compare:

```text
Silver / Integrated Sales
          =
Gold Sales
```

and:

```text
Silver Unique Transactions
          =
Gold Unique Transactions
```

when the Gold table represents the same analytical population.

Differences must be explained before dashboard publication.

---

## 11. `07_dashboard_queries.sql` — Dashboard

Purpose:

Provide dashboard-ready queries from Gold tables.

Recommended KPI cards include:

* Total Recorded Sales
* Units Sold
* Unique Transactions
* Average Basket

Recommended visualizations include:

### Monthly Sales Trend

Business question:

**How does purchasing behavior change over time?**

### Brand Performance

Business question:

**Which product brands generate the most sales?**

### Retailer Performance

Business question:

**Which retail partners contribute the most sales?**

### Customer Age Group Performance

Business question:

**Which customer age groups contribute the most purchasing activity?**

The dashboard should use Gold outputs whenever possible.

---

# 12. Data Flow

The complete pipeline is:

```text
SOURCE DATA
│
├── Transaction Details
└── Loyalty Cardholders
        │
        ▼
      BRONZE
│
├── transaction_details_raw
└── loyalty_cardholders_raw
        │
        ▼
   QUALITY CHECKS
        │
        ▼
      SILVER
│
├── clean_transactions
└── clean_loyalty
        │
        ▼
    INTEGRATION
 customer_id = user_id
        │
        ▼
       GOLD
│
├── KPI Summary
├── Monthly Performance
├── Brand Performance
├── Retailer Performance
└── Age Group Performance
        │
        ▼
    VALIDATION
        │
        ▼
     DASHBOARD
```

---

## 13. Repeatability

The pipeline is designed so that new data can pass through the same processing rules.

Example:

```text
New transaction data
New loyalty data
        ↓
Bronze ingestion
        ↓
Quality checks
        ↓
Silver cleaning
        ↓
Customer integration
        ↓
Gold aggregation
        ↓
Validation
        ↓
Dashboard refresh
```

The team should not manually rebuild the analysis whenever new records arrive.

The SQL pipeline should contain the logic required to repeat the transformation.

---

## 14. Git Collaboration Workflow

The repository uses `main` for approved project code.

Members should work using separate feature branches.

Standard workflow:

```text
main
 ↓
Pull
 ↓
Create feature branch
 ↓
Edit assigned SQL file
 ↓
Test
 ↓
Commit
 ↓
Push
 ↓
Pull Request
 ↓
Review
 ↓
Merge into main
```

After another member's work is merged:

```text
Switch to main
↓
Pull
↓
Create the next branch from the updated main
```

This prevents members from overwriting each other's changes.

---

## 15. File Order

The SQL files should normally be executed in this order:

```text
00_setup.sql
      ↓
01_bronze.sql
      ↓
02_quality_checks.sql
      ↓
03_silver.sql
      ↓
04_integrate.sql
      ↓
05_gold.sql
      ↓
06_validation.sql
      ↓
07_dashboard_queries.sql
```

Later stages depend on the successful completion of earlier stages.

---

## 16. Engineering Principle

The pipeline follows:

**Preserve → Profile → Clean → Integrate → Aggregate → Validate → Present**

### Preserve

Keep original source data.

### Profile

Find data-quality issues.

### Clean

Apply consistent and documented rules.

### Integrate

Connect transactions with loyalty customers.

### Aggregate

Build business-ready metrics.

### Validate

Confirm totals and relationships.

### Present

Use Gold data in the dashboard.

The goal is not only to create a dashboard, but to create a pipeline that another person can understand, rerun, and trust.
