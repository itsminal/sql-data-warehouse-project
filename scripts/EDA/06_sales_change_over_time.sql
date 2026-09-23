/*
===============================================================================
Script:         06_sales_change_over_time.sql
Purpose:        Analyze changes in sales performance over time.

Analysis Areas:
    - Monthly sales
    - Monthly active customers
    - Monthly quantity sold

Business Questions:
    - How have sales changed over time?
    - How many customers placed orders each month?
    - How has the quantity sold changed over time?
    - Are there noticeable trends or fluctuations in sales activity?

Source View:
    - gold.fact_sales

Analysis Approaches:
    1. YEAR() + MONTH()
    2. DATETRUNC()
    3. FORMAT()

Notes:
    All three approaches produce monthly aggregations but demonstrate
    different SQL techniques.

    DATETRUNC() is generally preferred for analytical date grouping because
    it preserves the date data type and is more suitable for further
    date-based calculations.

===============================================================================
*/


/*
===============================================================================
1. Monthly Sales Trend Using YEAR() and MONTH()

Purpose:
    Aggregate sales metrics by year and month.

Output:
    - Order year
    - Order month
    - Total sales
    - Number of distinct customers
    - Total quantity sold

Note:
    Both YEAR() and MONTH() are used in GROUP BY because the analysis
    requires a separate year-month combination.
===============================================================================
*/

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY
    order_year,
    order_month;


/*
===============================================================================
2. Monthly Sales Trend Using DATETRUNC()

Purpose:
    Group sales data into monthly date buckets using DATETRUNC().

Advantages:
    - Produces a proper DATE/DATETIME value.
    - Easier to use in further date calculations.
    - Keeps the year and month together as a single date value.
    - More convenient for time-series analysis.

===============================================================================
*/

SELECT
    DATETRUNC(MONTH, order_date) AS order_month,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    DATETRUNC(MONTH, order_date)
ORDER BY
    order_month;


/*
===============================================================================
3. Monthly Sales Trend Using FORMAT()

Purpose:
    Format the month as a readable year-month label.

Example:
    2025-Jan
    2025-Feb
    2025-Mar

Important:
    FORMAT() returns a string, making this approach more suitable for
    presentation than for further date calculations.

===============================================================================
*/

SELECT
    FORMAT(order_date, 'yyyy-MMM') AS order_month,
    SUM(sales) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    FORMAT(order_date, 'yyyy-MMM')
ORDER BY
    order_month;


/*
===============================================================================
Key Takeaways
===============================================================================

1. YEAR() + MONTH()
   Useful when year and month need to be returned as separate columns.

2. DATETRUNC()
   Preferred for analytical date grouping because the result remains
   date-based and can easily be used in additional date calculations.

3. FORMAT()
   Useful when a human-readable month label is required, but the result
   is a string rather than a date.

4. All three approaches calculate the same monthly business metrics:
       - Total Sales
       - Total Customers
       - Total Quantity

5. For the main EDA analysis, DATETRUNC() is the most reusable approach.

===============================================================================
*/
