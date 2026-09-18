# Gold Layer — Data Catalog

## 1. Overview

The Gold layer represents the **business-ready layer** of the data warehouse.

It is built on top of the cleaned and standardized Silver layer and is designed specifically for:

- Business analytics
- Reporting
- Dashboard development
- KPI calculation
- Data exploration
- Downstream BI tools

Unlike the Bronze layer, which stores raw source data, and the Silver layer, which focuses on cleansing and standardization, the Gold layer organizes the data into a **business-oriented dimensional model**.

The Gold layer in this project follows a **Star Schema** consisting of:

- `gold.dim_customers` — Customer dimension
- `gold.dim_products` — Product dimension
- `gold.fact_sales` — Sales fact

---

# 2. Data Warehouse Architecture

The overall architecture follows a layered approach:

```text
                         SOURCE SYSTEMS
                    ┌─────────────────────┐
                    │                     │
                    │   CRM       ERP     │
                    │                     │
                    └──────────┬──────────┘
                               │
                               ▼
                     ┌───────────────────┐
                     │   BRONZE LAYER    │
                     │                   │
                     │   Raw Data        │
                     │   Source Format   │
                     └────────┬──────────┘
                              │
                              │ Cleaning
                              │ Standardization
                              │ Validation
                              ▼
                     ┌───────────────────┐
                     │   SILVER LAYER    │
                     │                   │
                     │ Cleaned Data      │
                     │ Standardized Data │
                     └────────┬──────────┘
                              │
                              │ Business Modeling
                              │ Integration
                              │ Dimensional Modeling
                              ▼
                     ┌───────────────────┐
                     │    GOLD LAYER     │
                     │                   │
                     │ Business-Ready    │
                     │ Analytical Data   │
                     └────────┬──────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │ Analytics / BI /    │
                    │ Reporting / KPIs    │
                    └─────────────────────┘
````

---

# 3. Gold Layer Data Model

The Gold layer follows a **Star Schema**.

A star schema consists of:

* A central **fact table** containing measurable business events.
* Surrounding **dimension tables** containing descriptive attributes.

The current Gold model contains:

```text
                         ┌──────────────────────┐
                         │   dim_customers      │
                         │                      │
                         │ PK: customer_key     │
                         │                      │
                         │ customer_id          │
                         │ customer_number      │
                         │ first_name           │
                         │ last_name            │
                         │ marital_status       │
                         │ gender               │
                         │ birthdate            │
                         │ create_date          │
                         │ country              │
                         └───────────┬──────────┘
                                     │
                                     │ customer_key
                                     │
                                     ▼
                         ┌──────────────────────┐
                         │     fact_sales       │
                         │                      │
                         │ order_number         │
                         │ FK: product_key      │
                         │ FK: customer_key     │
                         │ order_date           │
                         │ ship_date            │
                         │ due_date             │
                         │ sales                │
                         │ quantity             │
                         │ price                │
                         └───────────┬──────────┘
                                     │
                                     │ product_key
                                     │
                                     ▼
                         ┌──────────────────────┐
                         │    dim_products      │
                         │                      │
                         │ PK: product_key     │
                         │                      │
                         │ product_id           │
                         │ product_number       │
                         │ product_name         │
                         │ category_id          │
                         │ category             │
                         │ subcategory          │
                         │ maintenance          │
                         │ cost                 │
                         │ product_line         │
                         │ start_date           │
                         │ end_date             │
                         │ create_date          │
                         └──────────────────────┘
```

---

# 4. Gold Layer Objects

| Object               | Type | Role      | Grain                                   |
| -------------------- | ---- | --------- | --------------------------------------- |
| `gold.dim_customers` | View | Dimension | One row per customer                    |
| `gold.dim_products`  | View | Dimension | One row per current product             |
| `gold.fact_sales`    | View | Fact      | One row per sales transaction/line item |

---

# 5. Dimension vs Fact Tables

## 5.1 Dimension Tables

Dimension tables contain descriptive information used to filter, group, and analyze business events.

### Customer Dimension

`gold.dim_customers`

Contains attributes describing customers.

Examples:

* Customer name
* Gender
* Marital status
* Birthdate
* Country

### Product Dimension

`gold.dim_products`

Contains attributes describing products.

Examples:

* Product name
* Category
* Subcategory
* Product line
* Cost

---

## 5.2 Fact Table

The fact table contains measurable business events.

`gold.fact_sales`

Contains sales transactions and numerical measures such as:

* Sales amount
* Quantity
* Price

It also contains foreign keys to the customer and product dimensions.

---

# 6. `gold.dim_customers`

## 6.1 Purpose

`gold.dim_customers` provides a consolidated customer dimension by integrating customer information from both CRM and ERP systems.

The CRM customer table acts as the primary source for customer information, while ERP sources provide additional attributes such as:

* Birthdate
* Country
* Fallback gender information

The resulting dimension provides a single business-friendly representation of customers.

---

## 6.2 Source Tables

| Source                 | Column(s) / Purpose           |
| ---------------------- | ----------------------------- |
| `silver.crm_cust_info` | Primary customer information  |
| `silver.erp_cust_az12` | Birthdate and fallback gender |
| `silver.erp_loc_a101`  | Country                       |

---

## 6.3 Join Logic

The customer dimension uses `LEFT JOIN` to preserve all customers from the CRM customer master.

```sql
silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.CID

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.CID
```

### Join Diagram

```text
silver.crm_cust_info
        │
        │ cst_key = CID
        ▼
silver.erp_cust_az12
        │
        │
        │
silver.erp_loc_a101
```

More precisely:

```text
                         ┌─────────────────────┐
                         │ erp_cust_az12       │
                         │                     │
                         │ CID                 │
                         │ BDATE               │
                         │ GEN                 │
                         └──────────▲──────────┘
                                    │
                                    │ cst_key = CID
                                    │
┌───────────────────────────┐       │
│ crm_cust_info             │───────┘
│                           │
│ cst_id                    │
│ cst_key                   │
│ cst_firstname             │
│ cst_lastname              │
│ cst_marital_status        │
│ cst_gndr                  │
│ cst_create_date           │
└─────────────┬─────────────┘
              │
              │ cst_key = CID
              ▼
┌───────────────────────────┐
│ erp_loc_a101              │
│                           │
│ CID                       │
│ CNTRY                     │
└───────────────────────────┘
```

---

## 6.4 Grain

The grain of `gold.dim_customers` is:

> **One row per customer.**

The customer is identified by the CRM customer ID.

---

## 6.5 Key

### Surrogate Key

`customer_key`

Generated using:

```sql
ROW_NUMBER() OVER (ORDER BY cst_id)
```

The surrogate key provides a warehouse-specific identifier for the customer.

### Business Key

`customer_id`

Derived from:

```sql
ci.cst_id
```

This represents the original customer identifier from the CRM source system.

---

## 6.6 Column Dictionary

| Column            | Data Role          | Source / Derivation     | Description                                    |
| ----------------- | ------------------ | ----------------------- | ---------------------------------------------- |
| `customer_key`    | Surrogate Key      | `ROW_NUMBER()`          | Warehouse-generated unique customer key        |
| `customer_id`     | Business Key       | `ci.cst_id`             | Original CRM customer identifier               |
| `customer_number` | Business Attribute | `ci.cst_key`            | Customer business/reference number             |
| `first_name`      | Attribute          | `ci.cst_firstname`      | Customer first name                            |
| `last_name`       | Attribute          | `ci.cst_lastname`       | Customer last name                             |
| `marital_status`  | Attribute          | `ci.cst_marital_status` | Standardized marital status                    |
| `gender`          | Attribute          | CRM + ERP               | Customer gender using CRM as the master source |
| `birthdate`       | Attribute          | `ca.BDATE`              | Customer date of birth                         |
| `create_date`     | Attribute          | `ci.cst_create_date`    | Customer creation date                         |
| `country`         | Attribute          | `la.CNTRY`              | Customer country                               |

---

# 7. Customer Transformation Rules

## 7.1 Customer Key Generation

A surrogate key is generated using:

```sql
ROW_NUMBER() OVER (ORDER BY cst_id)
```

Example:

```text
customer_id    customer_key
-----------    ------------
101            1
102            2
103            3
104            4
```

The surrogate key is used by the Gold fact table.

---

## 7.2 Gender Source Priority

Gender information exists in both CRM and ERP.

CRM is treated as the **master source**.

The logic is:

```sql
CASE
    WHEN ci.cst_gndr != 'n/a'
        THEN ci.cst_gndr
    ELSE COALESCE(ca.GEN, 'n/a')
END
```

### Business Rule

```text
                CRM Gender
                    │
             Is it valid?
              /        \
            YES         NO
             │           │
             ▼           ▼
       Use CRM       Check ERP
                        │
                 Is ERP available?
                    /       \
                  YES        NO
                   │          │
                   ▼          ▼
              Use ERP       'n/a'
```

This ensures that CRM remains the authoritative source when valid information exists.

---

## 7.3 ERP Data Enrichment

Customer information from CRM is enriched with ERP attributes.

```text
CRM
│
├── Customer ID
├── Customer Name
├── Marital Status
├── Gender
└── Create Date
       +
ERP Customer
│
├── Birthdate
└── Gender fallback
       +
ERP Location
│
└── Country
       │
       ▼
Gold Customer Dimension
```

---

# 8. `gold.dim_products`

## 8.1 Purpose

`gold.dim_products` provides a business-friendly product dimension.

It combines product information from CRM with product category information from ERP.

Only the **current product records** are included in the Gold dimension.

Historical product records are excluded.

---

## 8.2 Source Tables

| Source                   | Purpose                              |
| ------------------------ | ------------------------------------ |
| `silver.crm_prd_info`    | Product master information           |
| `silver.erp_px_cat_g1v2` | Category and subcategory information |

---

## 8.3 Join Logic

The product dimension joins CRM product information with ERP category information.

```sql
silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
```

---

## 8.4 Grain

The grain of `gold.dim_products` is:

> **One row per current product.**

---

## 8.5 Historical Product Handling

The Silver layer may contain multiple records for the same product because product attributes can change over time.

The Gold layer filters these records using:

```sql
WHERE pn.prd_end_dt IS NULL
```

This means only the currently active product record is included.

```text
Silver Product History
        │
        ├── Product Version 1
        ├── Product Version 2
        ├── Product Version 3
        │
        └── Current Product Version
                    │
                    ▼
            Gold Product Dimension
```

---

## 8.6 Key

### Surrogate Key

`product_key`

Generated using:

```sql
ROW_NUMBER() OVER
(
    ORDER BY pn.prd_start_dt,
             pn.prd_key
)
```

### Business Key

`product_id`

Derived from:

```sql
pn.prd_id
```

The `product_number` is derived from:

```sql
pn.prd_key
```

---

# 9. Product Column Dictionary

| Column           | Data Role            | Source / Derivation  | Description                              |
| ---------------- | -------------------- | -------------------- | ---------------------------------------- |
| `product_key`    | Surrogate Key        | `ROW_NUMBER()`       | Warehouse-generated product key          |
| `product_id`     | Business Key         | `pn.prd_id`          | Original product identifier              |
| `product_number` | Business Attribute   | `pn.prd_key`         | Product business/reference number        |
| `product_name`   | Attribute            | `pn.prd_nm`          | Product name                             |
| `category_id`    | Foreign/Business Key | `pn.cat_id`          | Product category identifier              |
| `category`       | Attribute            | `pc.cat`             | Product category                         |
| `subcategory`    | Attribute            | `pc.subcat`          | Product subcategory                      |
| `maintenance`    | Attribute            | `pc.maintenance`     | Product maintenance classification       |
| `cost`           | Measure/Attribute    | `pn.prd_cost`        | Product cost                             |
| `product_line`   | Attribute            | `pn.prd_line`        | Standardized product line                |
| `start_date`     | Attribute            | `pn.prd_start_dt`    | Start date of product validity           |
| `end_date`       | Attribute            | `pn.prd_end_dt`      | End date of product validity             |
| `create_date`    | Metadata             | `pn.dwh_create_date` | Data warehouse record creation timestamp |

---

# 10. Product Transformation Rules

## 10.1 Current Product Filter

Historical products are excluded using:

```sql
WHERE pn.prd_end_dt IS NULL
```

Therefore:

* `prd_end_dt IS NULL` → Current product
* `prd_end_dt IS NOT NULL` → Historical product

---

## 10.2 Category Enrichment

Product category information comes from the ERP category table.

```text
CRM Product
     │
     │ cat_id
     ▼
ERP Category
     │
     ├── Category
     ├── Subcategory
     └── Maintenance
```

This enriches the product dimension with additional descriptive attributes.

---

# 11. `gold.fact_sales`

## 11.1 Purpose

`gold.fact_sales` contains sales transactions used for business analysis and reporting.

It combines:

* Sales transaction information from CRM
* Product surrogate keys from `dim_products`
* Customer surrogate keys from `dim_customers`

The fact table contains both:

### Foreign Keys

* `product_key`
* `customer_key`

### Measures

* `sales`
* `quantity`
* `price`

### Dates

* `order_date`
* `ship_date`
* `due_date`

---

# 12. Fact Table Grain

The grain of `gold.fact_sales` is:

> **One row per sales transaction/line item represented in `silver.crm_sales_details`.**

The fact table does not aggregate sales.

Each source sales record is represented as an individual row in the Gold fact view.

This allows users to perform aggregations such as:

```sql
SUM(sales)
SUM(quantity)
AVG(price)
COUNT(order_number)
```

---

# 13. Fact Table Source

| Source                     | Purpose                |
| -------------------------- | ---------------------- |
| `silver.crm_sales_details` | Sales transaction data |
| `gold.dim_products`        | Product surrogate key  |
| `gold.dim_customers`       | Customer surrogate key |

---

# 14. Fact Table Join Logic

The fact table joins sales transactions with the Gold dimensions.

```sql
silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id
```

---

## 14.1 Product Relationship

```text
fact_sales.sls_prd_key
          │
          ▼
dim_products.product_number
          │
          ▼
dim_products.product_key
```

The resulting `product_key` is stored in the fact view.

---

## 14.2 Customer Relationship

```text
fact_sales.sls_cust_id
          │
          ▼
dim_customers.customer_id
          │
          ▼
dim_customers.customer_key
```

The resulting `customer_key` is stored in the fact view.

---

# 15. Fact Sales Column Dictionary

| Column         | Data Role           | Source / Derivation | Description                                    |
| -------------- | ------------------- | ------------------- | ---------------------------------------------- |
| `order_number` | Business Identifier | `sd.sls_ord_num`    | Sales order number                             |
| `product_key`  | Foreign Key         | `pr.product_key`    | Surrogate key referencing `gold.dim_products`  |
| `customer_key` | Foreign Key         | `cu.customer_key`   | Surrogate key referencing `gold.dim_customers` |
| `order_date`   | Date                | `sd.sls_order_dt`   | Date the order was placed                      |
| `ship_date`    | Date                | `sd.sls_ship_dt`    | Date the order was shipped                     |
| `due_date`     | Date                | `sd.sls_due_dt`     | Expected/due date of the order                 |
| `sales`        | Measure             | `sd.sls_sales`      | Sales amount                                   |
| `quantity`     | Measure             | `sd.sls_quantity`   | Quantity sold                                  |
| `price`        | Measure             | `sd.sls_price`      | Unit selling price                             |

---

# 16. Fact Table Measures

The fact table contains three primary numerical measures.

## 16.1 Sales

Column:

```text
sales
```

Represents the total sales amount associated with the transaction.

Example aggregation:

```sql
SELECT
    SUM(sales) AS total_sales
FROM gold.fact_sales;
```

---

## 16.2 Quantity

Column:

```text
quantity
```

Represents the number of units sold.

Example:

```sql
SELECT
    SUM(quantity) AS total_quantity
FROM gold.fact_sales;
```

---

## 16.3 Price

Column:

```text
price
```

Represents the unit selling price associated with the transaction.

Average selling price can be calculated using:

```sql
SELECT
    AVG(price) AS average_price
FROM gold.fact_sales;
```

---

# 17. Gold Layer Relationships

The fact table connects the two dimensions using surrogate keys.

```text
                       DIMENSION
                  gold.dim_customers
                         │
                         │
                  customer_key
                         │
                         │
                         ▼
                 ┌───────────────┐
                 │               │
                 │ fact_sales    │
                 │               │
                 └───────────────┘
                         ▲
                         │
                    product_key
                         │
                         │
                  gold.dim_products
                       DIMENSION
```

---

# 18. Star Schema

The complete Gold star schema can be represented as:

```text
                         ┌───────────────────────┐
                         │   gold.dim_customers  │
                         │───────────────────────│
                         │ PK customer_key       │
                         │    customer_id        │
                         │    customer_number    │
                         │    first_name         │
                         │    last_name          │
                         │    marital_status     │
                         │    gender             │
                         │    birthdate          │
                         │    create_date        │
                         │    country            │
                         └───────────┬───────────┘
                                     │
                                     │
                                     │ customer_key
                                     │
                                     ▼
                         ┌───────────────────────┐
                         │    gold.fact_sales    │
                         │───────────────────────│
                         │ order_number          │
                         │ FK product_key        │
                         │ FK customer_key       │
                         │ order_date            │
                         │ ship_date             │
                         │ due_date              │
                         │ sales                 │
                         │ quantity              │
                         │ price                 │
                         └───────────┬───────────┘
                                     │
                                     │
                                     │ product_key
                                     │
                                     ▼
                         ┌───────────────────────┐
                         │   gold.dim_products   │
                         │───────────────────────│
                         │ PK product_key        │
                         │    product_id         │
                         │    product_number     │
                         │    product_name       │
                         │    category_id        │
                         │    category           │
                         │    subcategory        │
                         │    maintenance        │
                         │    cost               │
                         │    product_line       │
                         │    start_date         │
                         │    end_date           │
                         │    create_date        │
                         └───────────────────────┘
```

---

# 19. Source-to-Gold Mapping

## Customer Data

```text
CRM
└── silver.crm_cust_info
    ├── cst_id
    ├── cst_key
    ├── cst_firstname
    ├── cst_lastname
    ├── cst_marital_status
    ├── cst_gndr
    └── cst_create_date
             │
             │
             ├───────────────┐
             │               │
             ▼               ▼
ERP Customer           ERP Location
silver.erp_cust_az12   silver.erp_loc_a101
    │                       │
    ├── BDATE               └── CNTRY
    └── GEN
             │
             ▼
    gold.dim_customers
```

---

## Product Data

```text
CRM
└── silver.crm_prd_info
    ├── prd_id
    ├── prd_key
    ├── prd_nm
    ├── cat_id
    ├── prd_cost
    ├── prd_line
    ├── prd_start_dt
    └── prd_end_dt
             │
             │
             ▼
ERP Category
silver.erp_px_cat_g1v2
    ├── ID
    ├── CAT
    ├── SUBCAT
    └── MAINTENANCE
             │
             ▼
    gold.dim_products
```

---

## Sales Data

```text
CRM
└── silver.crm_sales_details
    ├── sls_ord_num
    ├── sls_prd_key
    ├── sls_cust_id
    ├── sls_order_dt
    ├── sls_ship_dt
    ├── sls_due_dt
    ├── sls_sales
    ├── sls_quantity
    └── sls_price
             │
             │
             ├──────────────► gold.dim_products
             │                   │
             │                   └── product_key
             │
             └──────────────► gold.dim_customers
                                 │
                                 └── customer_key
             │
             ▼
       gold.fact_sales
```

---

# 20. Data Transformation Summary

The major transformations performed across the data warehouse are:

| Layer  | Transformation                        |
| ------ | ------------------------------------- |
| Bronze | Raw data loaded from CSV source files |
| Silver | Data cleansing                        |
| Silver | Standardization                       |
| Silver | Duplicate removal                     |
| Silver | Invalid value handling                |
| Silver | Data type conversion                  |
| Silver | Date validation                       |
| Silver | Business rule validation              |
| Gold   | CRM and ERP integration               |
| Gold   | Dimensional modeling                  |
| Gold   | Surrogate key generation              |
| Gold   | Current product filtering             |
| Gold   | Fact/dimension relationships          |

---

# 21. Business Rules in Gold Layer

## Customer

### Gender Priority

```text
CRM Gender
    ↓
If valid → CRM
    ↓
If 'n/a' → ERP
    ↓
If ERP unavailable → 'n/a'
```

---

## Product

### Current Product Rule

```text
prd_end_dt IS NULL
        ↓
Current Product
        ↓
Include in Gold
```

```text
prd_end_dt IS NOT NULL
        ↓
Historical Product
        ↓
Exclude from Gold
```

---

## Sales

Sales transactions are enriched with:

```text
Customer Surrogate Key
+
Product Surrogate Key
+
Sales Measures
+
Transaction Dates
```

---

# 22. Why Surrogate Keys Are Used

The Gold dimensions use warehouse-generated surrogate keys:

```text
customer_key
product_key
```

instead of directly using source-system identifiers as the primary analytical keys.

For example:

```text
Source Customer ID
        │
        ▼
customer_id = 101
        │
        ▼
Warehouse Surrogate Key
        │
        ▼
customer_key = 1
```

The fact table stores:

```text
customer_key = 1
```

rather than the source customer identifier.

This creates a clear separation between:

* Source-system identifiers
* Warehouse identifiers

and allows the dimensional model to remain independent from the source-system key structure.

---

# 23. Why the Gold Layer Uses Views

The current Gold objects are implemented as SQL Server views:

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

The views provide a business-friendly interface over the Silver layer.

Benefits include:

* No need to duplicate the underlying Silver data.
* Business logic is centralized.
* Analysts can query simplified structures.
* Complex joins are hidden from end users.
* The Gold layer provides a consistent analytical interface.

For this project, the Gold views are therefore the **consumption layer** over the Silver data.

---

# 24. Data Quality Expectations

The Gold layer should satisfy the following quality expectations.

## Customer Dimension

Expected:

* One row per customer.
* `customer_id` should not be NULL.
* `customer_key` should be unique within the dimension.
* Gender should contain standardized values.
* Customer information should be properly enriched where ERP data exists.

---

## Product Dimension

Expected:

* One row per current product.
* `product_key` should be unique.
* `product_number` should identify the product.
* Historical product records should not appear.
* Category information should be populated where a valid category relationship exists.

---

## Sales Fact

Expected:

* Each fact row should represent a valid sales transaction.
* `product_key` should map to a product dimension record.
* `customer_key` should map to a customer dimension record.
* Sales should be valid.
* Quantity should be positive.
* Price should be valid.
* Transaction dates should be logically consistent.

---

# 25. Example Analytical Queries

The Gold layer is designed to make analytical queries simple.

## 25.1 Total Sales

```sql
SELECT
    SUM(sales) AS total_sales
FROM gold.fact_sales;
```

---

## 25.2 Sales by Customer

```sql
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY
    total_sales DESC;
```

---

## 25.3 Sales by Country

```sql
SELECT
    c.country,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY
    c.country
ORDER BY
    total_sales DESC;
```

---

## 25.4 Sales by Product

```sql
SELECT
    p.product_name,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name
ORDER BY
    total_sales DESC;
```

---

## 25.5 Sales by Category

```sql
SELECT
    p.category,
    SUM(f.sales) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.category
ORDER BY
    total_sales DESC;
```

---

## 25.6 Quantity Sold by Product

```sql
SELECT
    p.product_name,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales f
JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY
    p.product_name
ORDER BY
    total_quantity DESC;
```

---

# 26. Gold Layer Usage Guidelines

When querying the warehouse for analytics, users should generally use the Gold layer instead of directly querying the Bronze or Silver layers.

### Recommended

```sql
SELECT *
FROM gold.fact_sales;
```

### Avoid for Business Reporting

```sql
SELECT *
FROM bronze.crm_sales_details;
```

or

```sql
SELECT *
FROM silver.crm_sales_details;
```

The Bronze and Silver layers are primarily intended for data ingestion, cleansing, transformation, and engineering processes.

The Gold layer is designed for business consumption.

---

# 27. Layer Responsibilities

| Layer          | Main Responsibility                | Typical User                                |
| -------------- | ---------------------------------- | ------------------------------------------- |
| Bronze         | Raw data ingestion                 | Data Engineer                               |
| Silver         | Cleansing and transformation       | Data Engineer                               |
| Gold           | Business modeling and analytics    | Data Analyst / BI Developer / Data Engineer |
| BI / Reporting | Visualization and decision support | Business Users / Analysts                   |

---

# 28. Gold Layer Design Summary

The Gold layer converts the technically structured Silver data into a business-oriented analytical model.

### Customer

```text
CRM Customer
      +
ERP Customer
      +
ERP Location
      ↓
dim_customers
```

### Product

```text
CRM Product
      +
ERP Category
      ↓
Current Product Dimension
```

### Sales

```text
CRM Sales
      +
Customer Surrogate Key
      +
Product Surrogate Key
      ↓
fact_sales
```

The resulting star schema provides a simple and efficient structure for answering questions such as:

* How much did we sell?
* Which products generate the most sales?
* Which product categories perform best?
* How many units were sold?
* Which countries generate the most sales?
* How much has each customer purchased?
* What is the average selling price?
* How do sales vary over time?

---

# 29. Final Gold Layer Structure

```text
                           GOLD LAYER
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       dim_customers     fact_sales       dim_products
              │                │                │
              │                │                │
       Customer Data      Sales Data       Product Data
              │                │                │
              │          ┌─────┴─────┐          │
              │          │           │          │
              └──────────┤           ├──────────┘
                         │           │
                   customer_key   product_key
```

## Gold Objects

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

These objects form the analytical foundation of the data warehouse and provide a business-ready interface for reporting, analytics, and downstream BI workloads.
