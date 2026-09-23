/*
===============================================================================
Script:         01_explore_dimensions.sql
Purpose:        Explore key categorical attributes in the Gold dimensions.

Analysis Areas:
    - Customer countries
    - Product categories and subcategories

Business Questions:
    - Which countries are represented in the customer base?
    - What product categories and subcategories exist?
    - Which products belong to each category/subcategory?

Source Views:
    - gold.dim_customers
    - gold.dim_products

Notes:
    DISTINCT is used to return unique combinations of the selected attributes.
    This script is exploratory and does not modify any data.

===============================================================================
*/


/*
===============================================================================
1. Explore Customer Countries

Purpose:
    Identify the distinct countries represented in the customer dimension.

Business Use:
    - Understand the geographic coverage of the customer base.
    - Identify available countries for further geographic analysis.

===============================================================================
*/

SELECT DISTINCT
    country
FROM gold.dim_customers
ORDER BY
    country;


/*
===============================================================================
2. Explore Product Categories and Subcategories

Purpose:
    Identify the unique combinations of product category, subcategory,
    and product name.

Business Use:
    - Understand the product hierarchy.
    - Explore the product catalog.
    - Identify which products belong to each category and subcategory.

===============================================================================
*/

SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY
    category,
    subcategory,
    product_name;


/*
===============================================================================
Key Takeaways
===============================================================================

1. DISTINCT helps identify the unique categorical values available in
   the Gold dimensions.

2. The customer query provides the geographic dimension of the dataset.

3. The product query explores the product hierarchy:
       Category → Subcategory → Product

4. These results can be used as a starting point for deeper EDA such as:
       - Customer distribution by country
       - Sales by country
       - Sales by category
       - Sales by subcategory
       - Top-performing products

===============================================================================
*/
