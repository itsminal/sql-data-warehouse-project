/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    Create a customer-level reporting view containing:
    - Customer demographics
    - Customer age groups
    - Customer segments
    - Sales and order metrics
    - Customer activity and recency
    - Average order value
    - Average monthly spending

Grain:
    One row per customer

Source:
    gold.fact_sales
    gold.dim_customers
===============================================================================
*/

CREATE OR ALTER VIEW gold.report_customer AS


-- ============================================================================
-- 1. Prepare Customer-Level Transaction Data
-- ============================================================================

WITH base_query AS
(
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales,
        f.quantity,

        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,

        -- Calculate completed age rather than simply counting year boundaries
        DATEDIFF(YEAR, c.birthdate, GETDATE())
            - CASE
                WHEN DATEADD(
                    YEAR,
                    DATEDIFF(YEAR, c.birthdate, GETDATE()),
                    c.birthdate
                  ) > GETDATE()
                THEN 1
                ELSE 0
              END AS customer_age

    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
),


-- ============================================================================
-- 2. Aggregate Transaction Data at Customer Level
-- ============================================================================

customer_aggregation AS
(
    SELECT
        customer_key,
        customer_number,
        customer_name,
        customer_age,

        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,

        MAX(order_date) AS last_order,

        -- Number of month boundaries between first and last order
        DATEDIFF(
            MONTH,
            MIN(order_date),
            MAX(order_date)
        ) AS lifespan

    FROM base_query

    GROUP BY
        customer_key,
        customer_number,
        customer_name,
        customer_age
)


-- ============================================================================
-- 3. Create Customer Report
-- ============================================================================

SELECT
    customer_key,
    customer_number,
    customer_name,
    customer_age,

    -- Customer age group
    CASE
        WHEN customer_age < 20 THEN 'Under 20'
        WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
        WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
        WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,

    -- Customer segmentation based on lifespan and spending
    CASE
        WHEN lifespan >= 12
             AND total_sales > 5000
            THEN 'VIP'

        WHEN lifespan >= 12
             AND total_sales <= 5000
            THEN 'Regular'

        ELSE 'New'
    END AS customer_segment,

    -- Customer activity metrics
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    last_order,

    -- Months since the customer's most recent order
    DATEDIFF(
        MONTH,
        last_order,
        GETDATE()
    ) AS recency,

    lifespan,

    -- Average revenue generated per order
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE CAST(total_sales AS DECIMAL(18, 2))
             / total_orders
    END AS avg_order_value,

    -- Average monthly spending during the customer's lifespan
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE CAST(total_sales AS DECIMAL(18, 2))
             / lifespan
    END AS avg_monthly_spend

FROM customer_aggregation;
