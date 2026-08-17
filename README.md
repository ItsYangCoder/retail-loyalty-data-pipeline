# Retail Transactions + Loyalty Customer Data Pipeline

## Project Overview

This project builds a repeatable data pipeline in Databricks using SQL.

The pipeline processes two datasets:

- Retail Transaction Details
- Loyalty Cardholders

The objective is to transform raw data into clean, validated, and business-ready data.

### Business Question

> How does purchasing behavior differ by customer age group, retailer, product brand, and month?

---

## Pipeline Architecture

SOURCE  
↓  
BRONZE  
↓  
QUALITY CHECKS  
↓  
SILVER  
↓  
INTEGRATE  
↓  
GOLD  
↓  
VALIDATION  
↓  
DASHBOARD

---

## Bronze Layer

The Bronze layer preserves the original source data.

### Tables

- `workspace.bronze.transaction_details_raw`
- `workspace.bronze.loyalty_cardholders_raw`

### Current Baseline

| Dataset | Row Count |
|---|---:|
| Transaction Details | 3,167 |
| Loyalty Cardholders | 5,949 |

### Grain

**Transaction Details**

One row represents one product line from a transaction.

**Loyalty Cardholders**

One row represents one registered loyalty member.

---

## Quality Layer

The Quality layer stores invalid or suspicious records for review.

### Tables

- `workspace.quality.invalid_transactions`
- `workspace.quality.receipt_date_issues`
- `workspace.quality.invalid_loyalty_birthdays`

### Current Quality Results

| Quality Check | Rows |
|---|---:|
| Invalid Transactions | 6 |
| Receipt Date Issues | 48 |
| Invalid Loyalty Birthdays | 5 |

### Quality Rules

Transactions are considered invalid when:

- Quantity is zero or negative
- Recorded sales value is zero or negative

Receipt dates are flagged when:

- Receipt date is more than one day after the transaction date

Loyalty birthdays are flagged when:

- Calculated customer age is greater than 110 years

---

## Silver Layer

The Silver layer cleans and standardizes the Bronze data.

Expected outputs:

- `workspace.silver.clean_transactions`
- `workspace.silver.clean_loyalty`

Silver transformations may include:

- Standardizing column names
- Standardizing dates
- Removing invalid transaction records
- Handling invalid birthdays
- Creating customer age groups
- Adding data-quality flags

---

## Integration

The transaction and loyalty datasets are connected using:

`customer_id = user_id`

Important keys include:

- `customer_id`
- `user_id`
- `transaction_id`

The integrated data allows purchasing behavior to be analyzed together with customer information.

---

## Gold Layer

The Gold layer contains business-ready aggregated data.

The Gold layer should support analysis by:

- Customer age group
- Retailer
- Product brand
- Month

Possible metrics include:

- Recorded Sales
- Units Purchased
- Transactions
- Purchasing Customers
- Average Basket

---

## Dashboard

The dashboard is the final analytical output of the pipeline.

Possible visualizations include:

- Sales by Age Group
- Sales by Retailer
- Sales by Product Brand
- Monthly Sales Performance
- KPI Cards

The dashboard should use Gold tables rather than querying raw Bronze data directly.

---

## SQL Execution Order

Run the SQL files in this order:

1. `00_setup.sql`
2. `01_bronze.sql`
3. `02_quality_checks.sql`
4. `03_silver.sql`
5. `04_integrate.sql`
6. `05_gold.sql`
7. `06_validation.sql`
8. `07_dashboard_queries.sql`

---

## Repository Structure

```text
retail-loyalty-data-pipeline/
│
├── sql/
│   ├── 00_setup.sql
│   ├── 01_bronze.sql
│   ├── 02_quality_checks.sql
│   ├── 03_silver.sql
│   ├── 04_integrate.sql
│   ├── 05_gold.sql
│   ├── 06_validation.sql
│   └── 07_dashboard_queries.sql
│
├── docs/
│
└── README.md