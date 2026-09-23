/*
===============================================================================
Script:         02_explore_date_range_and_customers.sql
Purpose:        Explore the overall time range of sales data and identify
                the youngest and oldest customers.

Analysis Areas:
    - Sales date range
    - Customer birthdate range
    - Youngest customer
    - Oldest customer

Business Questions:
    - What period does the sales dataset cover?
    - How many years of sales data are available?
    - What is the birthdate range of the customer base?
    - Who are the youngest and oldest customers?

Source Views:
    - gold.fact_sales
    - gold.dim_customers

Notes:
    - Date range calculations are based on non-null order dates.
    - Customer age extremes are determined using birthdate.
    - This script is exploratory and does not modify any data.

===============================================================================
*/


/*
===============================================================================
1. Explore Customer Dimension

Purpose:
    Inspect the available customer records and attributes.

Note:
    SELECT * is useful during initial exploration, but specific columns
    should generally be selected in reusable analytical queries.

===============================================================================
*/

SELECT *
FROM gold.dim_customers;


/*
===============================================================================
2. Determine the Sales Date Range

Purpose:
    Identify the first and last order dates and calculate the approximate
    number of years covered by the sales dataset.

===============================================================================
*/

SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(
        YEAR,
        MIN(order_date),
        MAX(order_date)
    ) AS order_range_years
FROM gold.fact_sales;


/*
===============================================================================
3. Determine the Customer Birthdate Range

Purpose:
    Identify the youngest and oldest birthdates recorded in the
    customer dimension.

Important:
    An earlier birthdate represents an older customer.
    A later birthdate represents a younger customer.

===============================================================================
*/

SELECT
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate
FROM gold.dim_customers;


/*
===============================================================================
4. Identify the Youngest Customer(s)

Purpose:
    Retrieve the complete customer record(s) associated with the latest
    birthdate in the customer dimension.

Note:
    Using a subquery allows us to first determine the maximum birthdate
    and then retrieve the corresponding customer records.

If multiple customers share the same birthdate, all matching customers
    will be returned.

===============================================================================
*/

SELECT
    *
FROM gold.dim_customers
WHERE birthdate = (
    SELECT
        MAX(birthdate)
    FROM gold.dim_customers
);


/*
===============================================================================
5. Identify the Oldest Customer(s)

Purpose:
    Retrieve the complete customer record(s) associated with the earliest
    birthdate in the customer dimension.

If multiple customers share the same birthdate, all matching customers
    will be returned.

===============================================================================
*/

SELECT
    *
FROM gold.dim_customers
WHERE birthdate = (
    SELECT
        MIN(birthdate)
    FROM gold.dim_customers
);


/*
===============================================================================
Key Takeaways
===============================================================================

1. MIN(order_date) and MAX(order_date) establish the overall sales period.

2. DATEDIFF(YEAR, ...) provides an approximate year-based range between
   the first and last order dates.

3. For birthdates:
       MIN(birthdate) → oldest customer
       MAX(birthdate) → youngest customer

4. The subqueries retrieve the complete customer records corresponding
   to the extreme birthdates.

5. If multiple customers have the same oldest or youngest birthdate,
   the queries return all matching customers.

===============================================================================
*/
