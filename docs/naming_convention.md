# Naming Conventions

## 1. Overview

This document defines the naming standards used throughout the SQL Data Warehouse project.

Consistent naming improves:

- Readability
- Maintainability
- Collaboration
- Debugging
- Scalability
- Understanding of data lineage and transformations

The naming conventions are applied across database objects, columns, SQL scripts, and project folders.

---

# 2. General Naming Principles

The project follows these general rules:

- Use `snake_case` for SQL object and column names.
- Use lowercase names for database objects.
- Use descriptive names instead of abbreviations whenever practical.
- Avoid spaces and special characters in object names.
- Use singular names for dimension tables.
- Use descriptive prefixes where they provide meaningful source or layer context.
- Keep naming consistent across Bronze, Silver, and Gold layers.
- Use names that describe the business meaning of the object rather than its implementation details.

### Example

```sql
customer_id
product_number
order_date
create_date
````

Instead of:

```sql
CustomerID
ProductNo
OrderDt
CreatedOn
```

---

# 3. Database Naming

## Database

The warehouse database is named:

```text
DataWarehouse
```

### Convention

```text
<DataDomain or Purpose>
```

### Example

```text
DataWarehouse
```

The database name uses PascalCase because it represents the primary database/application-level object.

---

# 4. Schema Naming

The project uses three schemas representing the data warehouse layers:

| Schema   | Purpose                        |
| -------- | ------------------------------ |
| `bronze` | Raw source data                |
| `silver` | Cleaned and standardized data  |
| `gold`   | Business-ready analytical data |

### Convention

```text
bronze
silver
gold
```

Schema names are intentionally short because they are frequently referenced in SQL queries.

### Examples

```sql
bronze.crm_cust_info
silver.crm_cust_info
gold.dim_customers
```

---

# 5. Bronze Layer Naming

The Bronze layer contains raw data loaded from source systems.

Bronze table names preserve the source-system context so that the origin of the data remains clear.

## Table Naming Convention

```text
<source_system>_<entity>
```

### Examples

```text
crm_cust_info
crm_prd_info
crm_sales_details
erp_cust_az12
erp_loc_a101
erp_px_cat_g1v2
```

### Source System Prefixes

| Prefix | Meaning                                 |
| ------ | --------------------------------------- |
| `crm`  | Customer Relationship Management source |
| `erp`  | Enterprise Resource Planning source     |

### Entity Examples

| Name     | Meaning          |
| -------- | ---------------- |
| `cust`   | Customer         |
| `prd`    | Product          |
| `sales`  | Sales            |
| `loc`    | Location         |
| `px_cat` | Product category |

The source naming is retained in the Bronze layer because the primary purpose of Bronze is to represent source data with minimal transformation.

---

# 6. Silver Layer Naming

The Silver layer contains cleaned, standardized, and validated data.

Silver table names generally retain the Bronze source naming to make data lineage easy to understand.

### Examples

```text
silver.crm_cust_info
silver.crm_prd_info
silver.crm_sales_details
silver.erp_cust_az12
silver.erp_loc_a101
silver.erp_px_cat_g1v2
```

### Convention

```text
<source_system>_<source_entity>
```

This makes it easy to trace data:

```text
Bronze
   ↓
silver.crm_cust_info
   ↓
Gold
gold.dim_customers
```

---

# 7. Gold Layer Naming

The Gold layer contains business-ready data designed for analytics and reporting.

Unlike Bronze and Silver, Gold objects use business-oriented names rather than source-system names.

Gold follows a dimensional modeling approach using:

* Dimensions
* Facts

---

## 7.1 Dimension Naming

Dimension objects use the prefix:

```text
dim_
```

### Convention

```text
dim_<business_entity>
```

### Examples

```text
dim_customers
dim_products
```

### Why `dim_`?

The prefix clearly identifies an object as a dimension table/view within the analytical model.

---

## 7.2 Fact Naming

Fact objects use the prefix:

```text
fact_
```

### Convention

```text
fact_<business_process>
```

### Example

```text
fact_sales
```

The name represents the business process being measured.

---

# 8. Column Naming

Column names use lowercase `snake_case`.

### Examples

```text
customer_id
customer_number
first_name
last_name
birthdate
order_date
ship_date
due_date
product_key
quantity
```

Avoid:

```text
CustomerID
customerID
Customer_Id
customer id
```

---

# 9. Key Naming

Keys follow a consistent naming pattern to distinguish surrogate keys from business/source keys.

## 9.1 Surrogate Keys

Surrogate keys use the suffix:

```text
_key
```

### Examples

```text
customer_key
product_key
```

These keys are generated within the data warehouse and are used to establish relationships between fact and dimension objects.

---

## 9.2 Business / Source Keys

Business keys generally use the suffix:

```text
_id
```

or, where the source system uses a different concept:

```text
_number
```

### Examples

```text
customer_id
product_id
order_number
```

The distinction is:

```text
customer_key   → Warehouse surrogate key
customer_id    → Source/business identifier
```

---

# 10. Date Column Naming

Date columns use names that clearly describe the business meaning of the date.

### Convention

```text
<event>_date
```

### Examples

```text
order_date
ship_date
due_date
start_date
end_date
create_date
birthdate
```

Avoid ambiguous names such as:

```text
dt
date1
date2
created
```

unless the meaning is already obvious from the context.

---

# 11. Measure Naming

Measures use business-friendly names that describe what is being measured.

### Examples

```text
sales
quantity
price
cost
```

Avoid unnecessarily technical names such as:

```text
sales_amt
qty_val
prd_cost_value
```

unless the distinction is required by the business model.

---

# 12. Source Column Naming

Raw source column names are generally preserved in the Bronze layer.

For example:

```text
cst_id
cst_key
cst_firstname
cst_lastname
cst_marital_status
cst_gndr
```

This helps preserve source-system lineage.

The Silver layer may retain source names while applying cleaning and standardization.

The Gold layer converts them into business-friendly names.

### Example

```text
Bronze / Silver
cst_id

        ↓

Gold
customer_id
```

---

# 13. Source-System Prefixes

Source-system prefixes are used primarily in Bronze and Silver layers.

| Prefix | Source     |
| ------ | ---------- |
| `crm_` | CRM system |
| `erp_` | ERP system |

### Example

```text
crm_cust_info
erp_cust_az12
```

These prefixes make it possible to identify the origin of the data without inspecting the table definition.

---

# 14. Stored Procedure Naming

Stored procedures use a naming convention based on the layer and operation.

### Convention

```text
<layer>.load_<layer>
```

### Examples

```sql
bronze.load_bronze
silver.load_silver
```

The `load_` prefix indicates that the procedure is responsible for loading data into the respective layer.

---

# 15. View Naming

Gold analytical views use the same dimensional modeling naming convention as Gold tables.

### Dimension views

```text
gold.dim_<entity>
```

### Fact views

```text
gold.fact_<business_process>
```

### Examples

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

---

# 16. SQL Script Naming

SQL scripts are named according to their purpose.

### Initialization

```text
init_database.sql
```

Used to create/reset the warehouse database and schemas.

### DDL Scripts

```text
ddl_bronze.sql
ddl_silver.sql
ddl_gold.sql
```

`ddl_` indicates Data Definition Language scripts responsible for creating database objects.

### Load Scripts

```text
load_bronze.sql
load_silver.sql
```

`load_` indicates data loading and transformation logic.

### Quality Checks

```text
quality_check_silver.sql
```

`quality_check_` identifies scripts used for data-quality validation.

---

# 17. Folder Naming

Project folders use lowercase names.

### Examples

```text
datasets/
scripts/
bronze/
silver/
gold/
```

Folder names should describe the responsibility or layer rather than a specific implementation.

---

# 18. SQL Keyword Formatting

SQL keywords are written in uppercase for readability.

### Preferred

```sql
SELECT
    customer_id,
    first_name
FROM silver.crm_cust_info
WHERE customer_id IS NOT NULL;
```

### Avoid

```sql
select customer_id, first_name
from silver.crm_cust_info
where customer_id is not null;
```

---

# 19. Table Aliases

Table aliases should be short but meaningful.

### Examples

```sql
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.CID
```

Common aliases in the project include:

| Alias | Meaning                            |
| ----- | ---------------------------------- |
| `ci`  | Customer Information               |
| `ca`  | Customer Additional / ERP customer |
| `la`  | Location                           |
| `pn`  | Product                            |
| `pc`  | Product Category                   |
| `sd`  | Sales Details                      |
| `pr`  | Product Dimension                  |
| `cu`  | Customer Dimension                 |

Avoid meaningless aliases such as:

```sql
a
b
x
y
```

unless they are used in a very small and obvious query.

---

# 20. Transformation Naming

Derived columns should be named according to their resulting business meaning.

### Example

```sql
CASE
    WHEN cst_gndr = 'F' THEN 'Female'
    WHEN cst_gndr = 'M' THEN 'Male'
    ELSE 'n/a'
END AS gender
```

The output column is named:

```text
gender
```

rather than:

```text
transformed_gender
new_gender_value
gender_case
```

---

# 21. Metadata Columns

Warehouse metadata columns use descriptive names.

### Example

```text
dwh_create_date
```

### Convention

```text
dwh_<metadata_description>
```

The `dwh_` prefix indicates that the column is maintained by the data warehouse rather than originating from the source system.

---

# 22. Naming by Layer

The overall naming strategy can be summarized as follows:

| Layer  | Naming Focus                 | Example                |
| ------ | ---------------------------- | ---------------------- |
| Bronze | Source-system oriented       | `bronze.crm_cust_info` |
| Silver | Source-system + cleaned data | `silver.crm_cust_info` |
| Gold   | Business-oriented            | `gold.dim_customers`   |
| Gold   | Business process             | `gold.fact_sales`      |

This intentionally creates a transition from **source-oriented naming** to **business-oriented naming** as data moves through the warehouse.

---

# 23. Complete Naming Examples

### Bronze

```text
bronze.crm_cust_info
bronze.crm_prd_info
bronze.crm_sales_details
bronze.erp_cust_az12
bronze.erp_loc_a101
bronze.erp_px_cat_g1v2
```

### Silver

```text
silver.crm_cust_info
silver.crm_prd_info
silver.crm_sales_details
silver.erp_cust_az12
silver.erp_loc_a101
silver.erp_px_cat_g1v2
```

### Gold

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

### Procedures

```text
bronze.load_bronze
silver.load_silver
```

### Scripts

```text
init_database.sql
ddl_bronze.sql
load_bronze.sql
ddl_silver.sql
load_silver.sql
quality_check_silver.sql
ddl_gold.sql
```

---

# 24. Naming Checklist

Before creating a new database object, verify:

* [ ] Name uses lowercase `snake_case` where applicable.
* [ ] Name is descriptive and business-readable.
* [ ] No spaces or unnecessary special characters are used.
* [ ] Source-system prefixes are used in Bronze/Silver where appropriate.
* [ ] Gold dimensions use the `dim_` prefix.
* [ ] Gold facts use the `fact_` prefix.
* [ ] Surrogate keys use the `_key` suffix.
* [ ] Business/source identifiers use `_id` or an appropriate business-specific suffix.
* [ ] Date columns use descriptive date names such as `_date`.
* [ ] Warehouse metadata columns use the `dwh_` prefix.
* [ ] Naming is consistent with existing objects.

---

# 25. Final Naming Philosophy

The naming convention follows a simple principle:

> **Preserve source-system context in Bronze and Silver, then use clear business terminology in Gold.**

This makes the warehouse easier to understand from both technical and business perspectives while maintaining clear data lineage from source systems to analytical outputs.

```

This fits nicely with your existing `data_catalog.md`: **`naming_convention.md` explains *how things are named*, while `data_catalog.md` explains *what each Gold object and column means*.**
```
