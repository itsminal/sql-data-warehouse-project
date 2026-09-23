/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    Analyze how much each product category contributes to total sales.

Analysis:
    - Total sales by category
    - Overall sales across all categories
    - Percentage contribution of each category to total sales
===============================================================================
*/


-- ============================================================================
-- 1. Calculate Sales by Category
-- ============================================================================

WITH category_sales AS
(
    SELECT
        p.category,
        SUM(s.sales) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
        ON s.product_key = p.product_key
    GROUP BY p.category
)


-- ============================================================================
-- 2. Calculate Category Contribution to Overall Sales
-- ============================================================================

SELECT
    category,
    total_sales,

    -- Total sales across all categories
    SUM(total_sales) OVER () AS overall_sales,

    -- Percentage contribution of each category to overall sales
    CONCAT(
        ROUND(
            CAST(total_sales AS FLOAT)
            / SUM(total_sales) OVER () * 100,
            2
        ),
        '%'
    ) AS percentage_of_total

FROM category_sales
ORDER BY total_sales DESC;
