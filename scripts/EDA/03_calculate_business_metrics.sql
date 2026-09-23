/*
===============================================================================
Script:         03_calculate_business_metrics.sql
Purpose:        Calculate high-level business metrics from the Gold layer.

Analysis Areas:
    - Total sales
    - Total quantity sold
    - Average selling price
    - Total number of orders
    - Total number of products
    - Total number of customers
    - Customers with orders

Business Questions:
    - What is the overall sales volume?
    - How many products and customers are represented?
    - How many orders have been placed?
    - How many customers have actually made a purchase?
    - What is the average selling price?

Source Views:
    - gold.fact_sales
    - gold.dim_products
    - gold.dim_customers

Notes:
    The final UNION ALL query presents all metrics in a single result set,
    making it easier to review or export the overall business KPIs.

===============================================================================
*/


/*
===============================================================================
1. Individual Business Metrics
===============================================================================

These queries calculate each KPI separately.

They are useful during exploratory analysis when individual metrics need
to be inspected or validated independently.
===============================================================================
*/


-- Total Sales
SELECT
    SUM(sales) AS total_sales
FROM gold.fact_sales;


-- Total Quantity Sold
SELECT
    SUM(quantity) AS total_quantity
FROM gold.fact_sales;


-- Average Selling Price
SELECT
    AVG(price) AS average_price
FROM gold.fact_sales;


-- Total Number of Orders
SELECT
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;


-- Total Number of Products
SELECT
    COUNT(DISTINCT product_name) AS total_products
FROM gold.dim_products;


-- Total Number of Customers
SELECT
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers;


-- Number of Customers with at Least One Order
SELECT
    COUNT(DISTINCT customer_key) AS customers_with_orders
FROM gold.fact_sales;


/*
===============================================================================
2. Consolidated Business Metrics
===============================================================================

Purpose:
    Combine all major KPIs into a single result set.

UNION ALL is used because each SELECT returns a different metric and we want
to preserve every metric as a separate row.

Result Structure:

    measure_name                    | measure_value
    --------------------------------|--------------
    Total Sales                     | ...
    Total Quantity                  | ...
    Average Price                   | ...
    Total No. Of Orders             | ...
    Total No. Of Products           | ...
    Total No. Of Customers          | ...
    Total No. Of Customers with Orders | ...

===============================================================================
*/

SELECT
    'Total Sales' AS measure_name,
    SUM(sales) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Total Quantity' AS measure_name,
    SUM(quantity) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Average Price' AS measure_name,
    AVG(price) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Total No. Of Orders' AS measure_name,
    COUNT(DISTINCT order_number) AS measure_value
FROM gold.fact_sales

UNION ALL

SELECT
    'Total No. Of Products' AS measure_name,
    COUNT(DISTINCT product_name) AS measure_value
FROM gold.dim_products

UNION ALL

SELECT
    'Total No. Of Customers' AS measure_name,
    COUNT(customer_key) AS measure_value
FROM gold.dim_customers

UNION ALL

SELECT
    'Total No. Of Customers with Orders' AS measure_name,
    COUNT(DISTINCT customer_key) AS measure_value
FROM gold.fact_sales;


/*
===============================================================================
Key Takeaways
===============================================================================

1. FACT TABLE METRICS
   - Total Sales
   - Total Quantity
   - Average Price
   - Total Orders
   - Customers with Orders

2. DIMENSION METRICS
   - Total Products
   - Total Customers

3. CUSTOMER COVERAGE
   Comparing:
       Total Customers
       vs.
       Customers with Orders

   helps identify how many customers in the customer dimension have
   corresponding sales activity.

4. UNION ALL
   The consolidated query transforms multiple KPI calculations into a
   simple two-column metric/value structure that can be easily consumed
   by dashboards or reporting tools.

===============================================================================
*/
