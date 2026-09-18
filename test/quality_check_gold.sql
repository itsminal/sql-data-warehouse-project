/*
===============================================================================
Script:         quality_check_gold.sql
Layer:          Gold
Purpose:        Validate the quality, consistency, and integrity of the
                business-ready Gold layer.

Gold Objects:
    - gold.dim_customers
    - gold.dim_products
    - gold.fact_sales

Validation Areas:
    1. Customer Dimension
    2. Product Dimension
    3. Sales Fact
    4. Referential Integrity
    5. Duplicate / Grain Checks
    6. Business Rule Checks
    7. Row Count Summary

Expected Result:
    Most validation queries should return ZERO rows.

Important:
    These checks are read-only and do not modify any data.

===============================================================================
*/


/*
===============================================================================
1. CUSTOMER DIMENSION
===============================================================================

Grain:
    One row per customer.

Checks:
    - NULL customer keys
    - NULL customer IDs
    - Duplicate customer IDs
    - NULL customer numbers
    - NULL names
    - Invalid gender values
    - Invalid marital status values

===============================================================================
*/


-- Check for NULL surrogate keys.
SELECT *
FROM gold.dim_customers
WHERE customer_key IS NULL;


-- Check for NULL business/customer IDs.
SELECT *
FROM gold.dim_customers
WHERE customer_id IS NULL;


-- Check for duplicate customers.
-- Expected result: ZERO rows.
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check for NULL customer numbers.
SELECT *
FROM gold.dim_customers
WHERE customer_number IS NULL;


-- Check for NULL customer names.
SELECT *
FROM gold.dim_customers
WHERE first_name IS NULL
   OR last_name IS NULL;


-- Check for invalid gender values.
SELECT DISTINCT
    gender
FROM gold.dim_customers
WHERE gender NOT IN ('Male', 'Female', 'n/a')
   OR gender IS NULL;


-- Check for invalid marital status values.
SELECT DISTINCT
    marital_status
FROM gold.dim_customers
WHERE marital_status NOT IN ('Married', 'Single', 'n/a')
   OR marital_status IS NULL;


/*
===============================================================================
2. PRODUCT DIMENSION
===============================================================================

Grain:
    One row per current product.

Checks:
    - NULL surrogate keys
    - NULL product IDs
    - Duplicate product numbers
    - NULL product numbers
    - Historical products accidentally included
    - NULL product names
    - Invalid product lines
    - Invalid product costs
    - NULL category IDs

===============================================================================
*/


-- Check for NULL surrogate keys.
SELECT *
FROM gold.dim_products
WHERE product_key IS NULL;


-- Check for NULL product IDs.
SELECT *
FROM gold.dim_products
WHERE product_id IS NULL;


-- Check for duplicate product numbers.
-- Expected result: ZERO rows.
SELECT
    product_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;


-- Check for NULL product numbers.
SELECT *
FROM gold.dim_products
WHERE product_number IS NULL;


-- Verify that only current products exist in the Gold dimension.
-- Historical records should have been filtered out by prd_end_dt IS NULL.
SELECT *
FROM gold.dim_products
WHERE end_date IS NOT NULL;


-- Check for NULL product names.
SELECT *
FROM gold.dim_products
WHERE product_name IS NULL;


-- Check for invalid product line values.
SELECT DISTINCT
    product_line
FROM gold.dim_products
WHERE product_line NOT IN (
    'Mountain',
    'Road',
    'Other Sales',
    'Touring',
    'n/a'
)
OR product_line IS NULL;


-- Check for invalid product costs.
SELECT *
FROM gold.dim_products
WHERE cost < 0
   OR cost IS NULL;


-- Check for NULL category IDs.
SELECT *
FROM gold.dim_products
WHERE category_id IS NULL;


/*
===============================================================================
3. SALES FACT
===============================================================================

Grain:
    One row per sales transaction/line item represented in
    silver.crm_sales_details.

Checks:
    - NULL order numbers
    - NULL dimension keys
    - Invalid dates
    - Invalid sales values
    - Invalid quantities
    - Invalid prices
    - Sales calculation consistency

===============================================================================
*/


-- Check for NULL order numbers.
SELECT *
FROM gold.fact_sales
WHERE order_number IS NULL;


-- Check for NULL product surrogate keys.
-- A NULL value indicates that the sales product could not be matched
-- to gold.dim_products.
SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;


-- Check for NULL customer surrogate keys.
-- A NULL value indicates that the sales customer could not be matched
-- to gold.dim_customers.
SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL;


-- Check for NULL order dates.
SELECT *
FROM gold.fact_sales
WHERE order_date IS NULL;


-- Check for future order dates.
SELECT *
FROM gold.fact_sales
WHERE order_date > GETDATE();


-- Check for invalid shipping dates.
-- Ship date should not be earlier than the order date.
SELECT *
FROM gold.fact_sales
WHERE ship_date < order_date;


-- Check for invalid due dates.
-- Due date should not be earlier than the order date.
SELECT *
FROM gold.fact_sales
WHERE due_date < order_date;


-- Check for invalid sales values.
SELECT *
FROM gold.fact_sales
WHERE sales <= 0
   OR sales IS NULL;


-- Check for invalid quantities.
SELECT *
FROM gold.fact_sales
WHERE quantity <= 0
   OR quantity IS NULL;


-- Check for invalid prices.
SELECT *
FROM gold.fact_sales
WHERE price <= 0
   OR price IS NULL;


-- Verify sales calculation.
-- Expected relationship:
--     sales = quantity * price
--
-- ROUND is used to avoid false failures caused by decimal precision.
SELECT *
FROM gold.fact_sales
WHERE ROUND(sales, 2) <> ROUND(quantity * price, 2);


/*
===============================================================================
4. REFERENTIAL INTEGRITY
===============================================================================

Purpose:
    Verify that fact records successfully reference their corresponding
    dimension records.

Expected Result:
    ZERO orphaned records.

===============================================================================
*/


-- Check for sales records without a matching product.
SELECT
    fs.product_key
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_products AS dp
    ON fs.product_key = dp.product_key
WHERE dp.product_key IS NULL
GROUP BY fs.product_key;


-- Check for sales records without a matching customer.
SELECT
    fs.customer_key
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_customers AS dc
    ON fs.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL
GROUP BY fs.customer_key;


/*
===============================================================================
5. DIMENSION KEY UNIQUENESS
===============================================================================

Purpose:
    Verify that surrogate keys are unique within each dimension.

Important:
    The current Gold dimensions use ROW_NUMBER() to generate surrogate keys.
    These checks validate uniqueness within the current query result.

===============================================================================
*/


-- Customer surrogate key uniqueness.
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- Product surrogate key uniqueness.
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


/*
===============================================================================
6. FACT GRAIN CHECK
===============================================================================

Purpose:
    Verify the expected grain of the sales fact.

Note:
    The source sales data may contain multiple rows for the same order number.
    Therefore, order_number alone is NOT necessarily unique.

    The following check identifies exact duplicate combinations of the
    dimensional keys and transaction attributes.

Expected Result:
    ZERO rows unless duplicate source transactions are intentionally allowed.

===============================================================================
*/


SELECT
    order_number,
    product_key,
    customer_key,
    order_date,
    sales,
    quantity,
    price,
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY
    order_number,
    product_key,
    customer_key,
    order_date,
    sales,
    quantity,
    price
HAVING COUNT(*) > 1;


/*
===============================================================================
7. BUSINESS RULE CHECKS
===============================================================================

These checks validate relationships and business rules that should hold
across the Gold model.

===============================================================================
*/


-- Check whether customer birthdates are in the future.
SELECT *
FROM gold.dim_customers
WHERE birthdate > GETDATE();


-- Check whether product start dates occur after end dates.
-- This should normally return ZERO rows.
SELECT *
FROM gold.dim_products
WHERE end_date IS NOT NULL
  AND start_date > end_date;


-- Check whether sales reference products that are not present
-- in the current product dimension.
--
-- This can occur if a product was retired and is therefore no longer
-- represented in dim_products because Gold contains current products only.
SELECT
    fs.product_key,
    COUNT(*) AS sales_count
FROM gold.fact_sales AS fs
LEFT JOIN gold.dim_products AS dp
    ON fs.product_key = dp.product_key
WHERE dp.product_key IS NULL
GROUP BY fs.product_key;


/*
===============================================================================
8. ROW COUNT SUMMARY
===============================================================================

Purpose:
    Provide a quick overview of the current Gold layer population.

This is an informational check rather than a pass/fail validation.

===============================================================================
*/


SELECT
    'dim_customers' AS object_name,
    COUNT(*) AS row_count
FROM gold.dim_customers

UNION ALL

SELECT
    'dim_products' AS object_name,
    COUNT(*) AS row_count
FROM gold.dim_products

UNION ALL

SELECT
    'fact_sales' AS object_name,
    COUNT(*) AS row_count
FROM gold.fact_sales;


/*
===============================================================================
9. GOLD LAYER SUMMARY
===============================================================================

Purpose:
    Quick high-level metrics for validating the Gold model.

===============================================================================
*/


SELECT
    COUNT(DISTINCT customer_key) AS total_customers,
    COUNT(DISTINCT product_key) AS products_referenced_in_sales,
    SUM(quantity) AS total_quantity,
    SUM(sales) AS total_sales,
    AVG(price) AS average_price
FROM gold.fact_sales;


/*
===============================================================================
END OF QUALITY CHECKS
===============================================================================

Expected Outcome:
    - No NULL dimension/business keys where not permitted.
    - No duplicate dimension business keys.
    - No invalid dimension attribute values.
    - No invalid sales measures.
    - No invalid transaction dates.
    - No orphaned fact records.
    - No unexpected historical products in dim_products.
    - Fact grain remains consistent.

If a check returns rows:
    1. Identify the affected records.
    2. Trace the data back to the Silver layer.
    3. Determine whether the issue is caused by source data,
       transformation logic, or Gold-layer modeling.
    4. Correct the appropriate upstream layer rather than manually
       modifying Gold data.

===============================================================================
*/
