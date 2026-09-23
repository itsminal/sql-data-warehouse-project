/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    Segment products and customers into meaningful business categories
    to support pricing analysis and customer profiling.

Analyses:
    1. Product segmentation by cost range
    2. Customer segmentation by lifespan and total spending
===============================================================================
*/


-- ============================================================================
-- 1. Product Segmentation by Cost Range
-- ============================================================================

WITH product_segment AS
(
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)

SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC;


-- ============================================================================
-- 2. Customer Segmentation by Spending and Lifespan
-- ============================================================================

WITH customer_spending AS
(
    SELECT
        c.customer_key,
        SUM(s.sales) AS total_spending,
        MIN(s.order_date) AS first_order,
        MAX(s.order_date) AS last_order,
        DATEDIFF(
            MONTH,
            MIN(s.order_date),
            MAX(s.order_date)
        ) AS lifespan
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c
        ON s.customer_key = c.customer_key
    GROUP BY c.customer_key
)

SELECT
    CASE
        WHEN lifespan >= 12 AND total_spending > 5000
            THEN 'VIP'
        WHEN lifespan >= 12 AND total_spending <= 5000
            THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,

    COUNT(customer_key) AS total_customers
FROM customer_spending
GROUP BY
    CASE
        WHEN lifespan >= 12 AND total_spending > 5000
            THEN 'VIP'
        WHEN lifespan >= 12 AND total_spending <= 5000
            THEN 'Regular'
        ELSE 'New'
    END
ORDER BY total_customers DESC;
