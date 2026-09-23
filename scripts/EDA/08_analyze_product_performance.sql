/*
===============================================================================
Script:         08_analyze_product_performance.sql
Purpose:        Analyze yearly product performance by comparing each product's
                sales against its historical average and previous-year sales.

Analysis Areas:
    - Yearly product sales
    - Product performance vs. historical average
    - Year-over-year sales comparison
    - Performance classification

Business Questions:
    - How much revenue did each product generate each year?
    - How does a product's current-year sales compare with its average sales?
    - How did each product perform compared with the previous year?
    - Which products are increasing or decreasing in performance?

Source Views:
    - gold.fact_sales
    - gold.dim_products

SQL Concepts Demonstrated:
    - CTE (Common Table Expression)
    - GROUP BY
    - Window functions
    - PARTITION BY
    - LAG()
    - CASE expressions
    - Year-over-year analysis

===============================================================================
*/


/*
===============================================================================
1. Calculate Yearly Sales for Each Product
===============================================================================

Purpose:
    Aggregate sales at the product-year level.

Grain:
    One row per product per year.

Example:

    Year    Product        Current Sales
    2023    Product A      100,000
    2024    Product A      120,000
    2025    Product A      150,000

The CTE provides the base dataset for the performance analysis below.

===============================================================================
*/

WITH yearly_product_sales AS (
    SELECT
        YEAR(s.order_date) AS order_year,
        p.product_name,
        SUM(s.sales) AS current_sales
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_products AS p
        ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY
        YEAR(s.order_date),
        p.product_name
)


/*
===============================================================================
2. Analyze Product Performance
===============================================================================
*/

SELECT
    order_year,
    product_name,
    current_sales,


    /*
    ---------------------------------------------------------------------------
    Average Sales
    ---------------------------------------------------------------------------
    Calculates the average yearly sales for each product across all available
    years.

    PARTITION BY product_name means each product gets its own average.
    ---------------------------------------------------------------------------
    */

    AVG(current_sales) OVER (
        PARTITION BY product_name
    ) AS avg_sales,


    /*
    ---------------------------------------------------------------------------
    Difference from Average
    ---------------------------------------------------------------------------
    Measures how far the current year's sales are above or below the
    product's historical average.
    ---------------------------------------------------------------------------
    */

    current_sales
        - AVG(current_sales) OVER (
            PARTITION BY product_name
        ) AS diff_avg,


    /*
    ---------------------------------------------------------------------------
    Performance vs. Average
    ---------------------------------------------------------------------------
    Classifies the current year's sales relative to the product's
    historical average.
    ---------------------------------------------------------------------------
    */

    CASE
        WHEN current_sales
            - AVG(current_sales) OVER (
                PARTITION BY product_name
              ) > 0
            THEN 'Above Average'

        WHEN current_sales
            - AVG(current_sales) OVER (
                PARTITION BY product_name
              ) < 0
            THEN 'Below Average'

        ELSE 'Average'
    END AS avg_change,


    /*
    ---------------------------------------------------------------------------
    Previous-Year Sales
    ---------------------------------------------------------------------------
    LAG() retrieves the previous available year's sales for the same product.

    PARTITION BY product_name
        → Creates a separate sequence for each product.

    ORDER BY order_year
        → Determines which year is considered the previous year.
    ---------------------------------------------------------------------------
    */

    LAG(current_sales) OVER (
        PARTITION BY product_name
        ORDER BY order_year
    ) AS previous_year_sales,


    /*
    ---------------------------------------------------------------------------
    Year-over-Year Difference
    ---------------------------------------------------------------------------
    Calculates the difference between the current year's sales and the
    previous available year's sales.
    ---------------------------------------------------------------------------
    */

    current_sales
        - LAG(current_sales) OVER (
            PARTITION BY product_name
            ORDER BY order_year
        ) AS diff_previous_year,


    /*
    ---------------------------------------------------------------------------
    Year-over-Year Performance
    ---------------------------------------------------------------------------
    Classifies whether sales increased, decreased, or remained unchanged
    compared with the previous available year.
    ---------------------------------------------------------------------------
    */

    CASE
        WHEN current_sales
            - LAG(current_sales) OVER (
                PARTITION BY product_name
                ORDER BY order_year
              ) > 0
            THEN 'Increase'

        WHEN current_sales
            - LAG(current_sales) OVER (
                PARTITION BY product_name
                ORDER BY order_year
              ) < 0
            THEN 'Decrease'

        ELSE 'No Change'
    END AS change_previous_year

FROM yearly_product_sales

ORDER BY
    product_name,
    order_year;


/*
===============================================================================
Key Takeaways
===============================================================================

1. PRODUCT-YEAR GRAIN
   The CTE creates one row for each product in each year.

2. HISTORICAL AVERAGE
   AVG(current_sales) OVER (PARTITION BY product_name)
   calculates the average yearly sales for each individual product.

3. DIFFERENCE FROM AVERAGE
   current_sales - avg_sales
   shows whether the product is performing above or below its historical
   average.

4. LAG()
   LAG(current_sales) retrieves the previous available sales value for
   the same product.

5. YEAR-OVER-YEAR ANALYSIS
   Comparing current sales with previous-year sales identifies whether
   product performance increased or decreased.

6. FIRST AVAILABLE YEAR
   For the first available year of a product, LAG() returns NULL because
   there is no previous sales record to compare against.

7. IMPORTANT
   "Previous year" here means the previous available year in the dataset.
   If a product has no sales record for a particular year, LAG() skips
   that missing year rather than automatically treating it as zero.

===============================================================================
*/
