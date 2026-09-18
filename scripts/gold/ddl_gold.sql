/*
===============================================================================
Script:         ddl_gold.sql
Layer:          Gold
Purpose:        Create business-ready dimensional models for analytics
                and reporting.

Gold Model:
    - gold.dim_customers
    - gold.dim_products
    - gold.fact_sales

Model Type:
    Star Schema

Notes:
    - Gold objects are created as views over the Silver layer.
    - Dimension views provide descriptive attributes.
    - The fact view contains measurable business events.
    - Surrogate keys are generated using ROW_NUMBER().
      These keys are recalculated when the views are queried and are therefore
      not persistent. In a production warehouse, persisted dimension tables
      with stable surrogate keys would generally be preferred.

Dependencies:
    - Silver layer must be loaded before executing this script.
    - gold.dim_customers and gold.dim_products must exist before creating
      gold.fact_sales.

===============================================================================
*/


/*
===============================================================================
1. Customer Dimension
===============================================================================

Object:     gold.dim_customers
Grain:      One row per customer

Purpose:
    Combines customer information from CRM with additional customer attributes
    from ERP sources to create a single business-friendly customer dimension.

Source Tables:
    - silver.crm_cust_info
    - silver.erp_cust_az12
    - silver.erp_loc_a101

Key Design:
    - customer_key  : Surrogate key generated within the warehouse.
    - customer_id   : Source/business key from CRM.
    - customer_number: Customer business identifier used to link ERP data.

Business Rule:
    CRM is treated as the master source for gender. If CRM gender is
    unavailable ('n/a'), ERP gender is used as a fallback.

===============================================================================
*/

CREATE OR ALTER VIEW gold.dim_customers
AS
SELECT
    -- Surrogate key generated for the Gold dimension.
    -- NOTE: Because this is a view, the key is recalculated when queried.
    ROW_NUMBER() OVER (
        ORDER BY ci.cst_id
    ) AS customer_key,

    -- Business/source identifiers
    ci.cst_id            AS customer_id,
    ci.cst_key           AS customer_number,

    -- Customer descriptive attributes
    ci.cst_firstname     AS first_name,
    ci.cst_lastname      AS last_name,
    ci.cst_marital_status AS marital_status,

    -- CRM is the master source for gender.
    -- ERP gender is used only when CRM gender is unavailable.
    CASE
        WHEN ci.cst_gndr <> 'n/a'
            THEN ci.cst_gndr
        ELSE COALESCE(ca.GEN, 'n/a')
    END AS gender,

    -- Additional customer attributes from ERP
    ca.BDATE             AS birthdate,
    la.CNTRY             AS country,

    -- Warehouse metadata
    ci.cst_create_date   AS create_date

FROM silver.crm_cust_info AS ci

-- Enrich CRM customer data with ERP customer attributes.
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.CID

-- Enrich customer data with location/country information.
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.CID;


/*
===============================================================================
2. Product Dimension
===============================================================================

Object:     gold.dim_products
Grain:      One row per current product

Purpose:
    Creates a business-friendly product dimension by combining CRM product
    information with ERP product category information.

Source Tables:
    - silver.crm_prd_info
    - silver.erp_px_cat_g1v2

Key Design:
    - product_key    : Surrogate key generated within the warehouse.
    - product_id     : Source product identifier.
    - product_number : Business/product key used to link sales transactions.

Business Rule:
    Only the current version of each product is included in the Gold layer.
    Historical product records are excluded using:

        prd_end_dt IS NULL

    This keeps the dimension focused on currently active products.

===============================================================================
*/

CREATE OR ALTER VIEW gold.dim_products
AS
SELECT
    -- Surrogate key generated for the Gold dimension.
    -- NOTE: Because this is a view, the key is recalculated when queried.
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    -- Product identifiers
    pn.prd_id             AS product_id,
    pn.prd_key            AS product_number,

    -- Product descriptive attributes
    pn.prd_nm             AS product_name,
    pn.cat_id              AS category_id,

    -- Product category information from ERP
    pc.cat                AS category,
    pc.subcat             AS subcategory,
    pc.maintenance        AS maintenance,

    -- Product attributes
    pn.prd_cost           AS cost,
    pn.prd_line           AS product_line,

    -- Product lifecycle dates
    pn.prd_start_dt       AS start_date,
    pn.prd_end_dt         AS end_date,

    -- Warehouse metadata
    pn.dwh_create_date    AS create_date

FROM silver.crm_prd_info AS pn

-- Enrich CRM products with ERP category information.
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id

-- Keep only the current product records.
-- Historical versions have a populated prd_end_dt.
WHERE pn.prd_end_dt IS NULL;


/*
===============================================================================
3. Sales Fact
===============================================================================

Object:     gold.fact_sales
Grain:      One row per sales transaction/line item represented in
            silver.crm_sales_details.

Purpose:
    Provides measurable sales transactions linked to the Customer and Product
    dimensions for analytical reporting.

Source Tables:
    - silver.crm_sales_details
    - gold.dim_products
    - gold.dim_customers

Key Design:
    - product_key  : Foreign key to gold.dim_products.
    - customer_key : Foreign key to gold.dim_customers.
    - order_number : Business identifier for the sales order.

Measures:
    - sales
    - quantity
    - price

Dates:
    - order_date
    - ship_date
    - due_date

Important:
    LEFT JOINs are used so that sales records are not automatically removed
    if a matching customer or product dimension record is unavailable.

    Such unmatched records should be investigated through Gold/Silver
    data-quality checks.

===============================================================================
*/

CREATE OR ALTER VIEW gold.fact_sales
AS
SELECT
    -- Business identifier
    sd.sls_ord_num    AS order_number,

    -- Dimension surrogate keys
    pr.product_key,
    cu.customer_key,

    -- Sales transaction dates
    sd.sls_order_dt   AS order_date,
    sd.sls_ship_dt    AS ship_date,
    sd.sls_due_dt     AS due_date,

    -- Sales measures
    sd.sls_sales      AS sales,
    sd.sls_quantity   AS quantity,
    sd.sls_price      AS price

FROM silver.crm_sales_details AS sd

-- Link each sales record to the current product dimension.
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number

-- Link each sales record to the customer dimension.
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
