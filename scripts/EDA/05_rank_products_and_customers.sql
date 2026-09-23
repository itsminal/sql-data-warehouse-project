/*
===============================================================================
Script:         05_rank_products_and_customers.sql
Purpose:        Rank products and customers based on sales performance
                and order activity.

Analysis Areas:
    - Top 5 products by revenue
    - Bottom 5 products by revenue
    - Top 5 products using ROW_NUMBER()
    - Bottom 3 customers by number of orders
    - Top 10 customers by revenue

Business Questions:
    - Which products generate the most revenue?
    - Which products generate the least revenue?
    - Which customers place the most orders?
    - Which customers generate the most revenue?

Source Views:
    - gold.fact_sales
    - gold.dim_products
    - gold.dim_customers

SQL Concepts Demonstrated:
    - TOP
    - ORDER BY
    - GROUP BY
    - ROW_NUMBER()
    - Subqueries / Derived Tables
    - Aggregate functions
    - Fact-to-dimension joins

===============================================================================
*/


/*
===============================================================================
1. Top 5 Products by Revenue

Purpose:
    Identify the five products generating the highest total revenue.

===============================================================================
*/

SELECT TOP 5
    p.product_name,
    SUM(s.sales) AS total_revenue
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
    ON p.product_key = s.product_key
GROUP BY
    p.product_name
ORDER BY
    total_revenue DESC;


/*
===============================================================================
2. Bottom 5 Products by Revenue

Purpose:
    Identify the five products generating the lowest total revenue.

Note:
    ASC is used so that products with the smallest revenue appear first.

===============================================================================
*/

SELECT TOP 5
    p.product_name,
    SUM(s.sales) AS total_revenue
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_products AS p
    ON p.product_key = s.product_key
GROUP BY
    p.product_name
ORDER BY
    total_revenue ASC;


/*
===============================================================================
3. Top 5 Products Using ROW_NUMBER()

Purpose:
    Demonstrate how a window function can be used to rank products.

Why use ROW_NUMBER()?
    Unlike TOP, ROW_NUMBER() assigns an explicit ranking value to each
    product. This makes the ranking available as a column and allows
    additional filtering or analysis.

The derived table is required because the ranking is calculated first,
then filtered in the outer query.

===============================================================================
*/

SELECT
    product_name,
    total_revenue,
    rank
FROM (
    SELECT
        p.product_name,
        SUM(s.sales) AS total_revenue,
        ROW_NUMBER() OVER (
            ORDER BY SUM(s.sales) DESC
        ) AS rank
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
        ON p.product_key = s.product_key
    GROUP BY
        p.product_name
) AS t
WHERE rank <= 5
ORDER BY
    rank;


/*
===============================================================================
4. Bottom 3 Customers by Number of Orders

Purpose:
    Identify the three customers with the fewest distinct orders.

Note:
    COUNT(DISTINCT order_number) counts unique orders rather than individual
    sales line items.

ROW_NUMBER() ranks customers from the lowest order count to the highest.

===============================================================================
*/

SELECT
    customer_key,
    first_name,
    last_name,
    total_orders,
    rank
FROM (
    SELECT
        c.customer_key,
        c.first_name,
        c.last_name,
        COUNT(DISTINCT s.order_number) AS total_orders,
        ROW_NUMBER() OVER (
            ORDER BY COUNT(DISTINCT s.order_number) ASC
        ) AS rank
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON c.customer_key = s.customer_key
    GROUP BY
        c.customer_key,
        c.first_name,
        c.last_name
) AS t
WHERE rank <= 3
ORDER BY
    rank;


/*
===============================================================================
5. Top 10 Customers by Revenue

Purpose:
    Identify the ten customers generating the highest total revenue.

===============================================================================
*/

SELECT
    customer_number,
    first_name,
    last_name,
    total_revenue,
    rank
FROM (
    SELECT
        c.customer_number,
        c.first_name,
        c.last_name,
        SUM(s.sales) AS total_revenue,
        ROW_NUMBER() OVER (
            ORDER BY SUM(s.sales) DESC
        ) AS rank
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c
        ON c.customer_key = s.customer_key
    GROUP BY
        c.customer_number,
        c.first_name,
        c.last_name
) AS t
WHERE rank <= 10
ORDER BY
    rank;


/*
===============================================================================
Key Takeaways
===============================================================================

1. TOP + ORDER BY
   Provides a simple way to retrieve the highest or lowest N records.

2. ROW_NUMBER()
   Assigns a sequential ranking to each row based on the specified metric.

3. DERIVED TABLE
   The ranking is calculated inside the subquery and then filtered outside.

4. REVENUE RANKING
   SUM(sales) is used to identify high- and low-performing products
   and high-value customers.

5. ORDER RANKING
   COUNT(DISTINCT order_number) measures customer order activity without
   counting multiple line items from the same order separately.

6. ROW_NUMBER() AND TIES
   ROW_NUMBER() always assigns a unique sequential rank.

   If two products have the same revenue, they will still receive
   different row numbers.

   If tied values should receive the same rank, RANK() or DENSE_RANK()
   would be more appropriate.

===============================================================================
*/
