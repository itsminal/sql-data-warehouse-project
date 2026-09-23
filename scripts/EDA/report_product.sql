/*
===============================================================================
Product Report
===============================================================================
Purpose:
    Create a product-level reporting view containing:
    - Product details and hierarchy
    - Sales and order metrics
    - Customer reach
    - Product lifespan and recency
    - Average selling price
    - Product performance segmentation
    - Average order revenue
    - Average monthly revenue

Grain:
    One row per product

Source:
    gold.fact_sales
    gold.dim_products
===============================================================================
*/

CREATE OR ALTER VIEW gold.report_product AS


-- ============================================================================
-- 1. Prepare Product-Level Transaction Data
-- ============================================================================

WITH base_query AS
(
    SELECT
        p.product_key,
        p.product_id,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost,

        s.sales,
        s.price,
        s.quantity,
        s.order_date,
        s.order_number,
        s.customer_key

    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
        ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
),


-- ============================================================================
-- 2. Aggregate Transaction Data at Product Level
-- ============================================================================

product_aggregation AS
(
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,

        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales) AS total_sales,
        SUM(quantity) AS total_quantity_sold,
        COUNT(DISTINCT customer_key) AS total_customers,

        -- Number of month boundaries between first and last sale
        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan,

        MAX(order_date) AS last_sale_date,

        -- Average actual selling price per unit
        ROUND(
            AVG(
                CAST(sales AS FLOAT)
                / NULLIF(quantity, 0)
            ),
            1
        ) AS avg_selling_price

    FROM base_query

    GROUP BY
        product_key,
        product_name,
        category,
        subcategory,
        cost
)


-- ============================================================================
-- 3. Create Product Report
-- ============================================================================

SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,

    -- Activity metrics
    last_sale_date,
    total_orders,
    total_sales,
    total_quantity_sold,
    total_customers,

    lifespan,
    avg_selling_price,

    -- Months since the product's most recent sale
    DATEDIFF(
        MONTH,
        last_sale_date,
        GETDATE()
    ) AS recency,

    -- Product performance segmentation
    CASE
        WHEN total_sales > 50000
            THEN 'High-Performer'

        WHEN total_sales >= 10000
            THEN 'Mid-Range'

        ELSE 'Low-Performer'
    END AS product_segment,

    -- Average revenue generated per order
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE CAST(total_sales AS DECIMAL(18, 2))
             / total_orders
    END AS avg_order_revenue,

    -- Average monthly revenue during product lifespan
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE CAST(total_sales AS DECIMAL(18, 2))
             / lifespan
    END AS avg_monthly_revenue

FROM product_aggregation;
