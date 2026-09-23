/*
===============================================================================
Script:         07_cumulative_analysis.sql
Purpose:        Perform cumulative analysis of yearly sales performance.

Analysis Areas:
    - Yearly total sales
    - Running total sales
    - Running average selling price

Business Questions:
    - How does total sales accumulate over time?
    - How does the cumulative sales performance evolve year by year?
    - How does the average selling price evolve over time?

Source View:
    - gold.fact_sales

SQL Concepts Demonstrated:
    - DATETRUNC()
    - Aggregate functions
    - Window functions
    - Running totals
    - Running averages
    - Derived tables

===============================================================================
*/


/*
===============================================================================
1. Calculate Yearly Sales Metrics

Purpose:
    First aggregate the sales data at the yearly level.

This creates one row per year containing:
    - Total sales
    - Average selling price

The outer query then applies window functions to these yearly results.

===============================================================================
*/

SELECT
    order_year,
    total_sales,

    -- Running total of sales from the first year through the current year
    SUM(total_sales) OVER (
        ORDER BY order_year
    ) AS running_total_sales,

    -- Running average of the yearly average selling price
    AVG(avg_price) OVER (
        ORDER BY order_year
    ) AS running_avg_price

FROM (
    SELECT
        DATETRUNC(YEAR, order_date) AS order_year,
        SUM(sales) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY
        DATETRUNC(YEAR, order_date)
) AS t

ORDER BY
    order_year;


/*
===============================================================================
Key Takeaways
===============================================================================

1. TWO-STEP ANALYSIS

   The inner query first aggregates individual sales transactions into
   yearly metrics.

   The outer query then applies window functions to those yearly results.

2. RUNNING TOTAL

   SUM(total_sales) OVER (ORDER BY order_year)

   adds the current year's sales to all previous years' sales.

   Example:

       Year    Sales    Running Total
       2022    100      100
       2023    150      250
       2024    200      450

3. RUNNING AVERAGE

   AVG(avg_price) OVER (ORDER BY order_year)

   calculates the average of the yearly average prices up to the
   current year.

4. WHY THE SUBQUERY?

   We first need yearly totals before calculating the cumulative metrics.

   This separates the analysis into:

       Transaction-level data
                ↓
       Yearly aggregation
                ↓
       Cumulative calculation

5. DATETRUNC()

   DATETRUNC(YEAR, order_date) converts each order date into its
   corresponding year bucket, allowing the data to be grouped at
   yearly granularity.

===============================================================================
*/
