/*
===============================================================================
Script:         00_explore_gold_schema.sql
Purpose:        Explore the structure and metadata of the Gold layer.

Use Cases:
    - Identify available tables and views.
    - Inspect column names, data types, and metadata.
    - Understand the structure of the analytical model before performing EDA.

System Views:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS

Notes:
    INFORMATION_SCHEMA views provide metadata about database objects.

    These queries are read-only and do not modify any database objects or data.

===============================================================================
*/


/*
===============================================================================
1. Explore Database Tables and Views

Purpose:
    Returns the tables and views available in the current database.

Useful for:
    - Understanding the available data model.
    - Identifying Gold-layer objects before starting analysis.
    - Checking whether expected tables/views exist.

===============================================================================
*/

SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
ORDER BY
    TABLE_SCHEMA,
    TABLE_NAME;


/*
===============================================================================
2. Explore Columns of the Customer Dimension

Purpose:
    Inspect the structure of gold.dim_customers.

Returns information such as:
    - Column name
    - Data type
    - Maximum character length
    - Numeric precision and scale
    - Nullable status

===============================================================================
*/

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'dim_customers'
ORDER BY
    ORDINAL_POSITION;


/*
===============================================================================
Notes
===============================================================================

INFORMATION_SCHEMA is useful for general database metadata exploration.

For SQL Server-specific metadata and more detailed object information,
system catalog views such as:

    sys.tables
    sys.columns
    sys.views
    sys.schemas

can also be used.

For this project, INFORMATION_SCHEMA is sufficient for basic schema
documentation and exploration.

===============================================================================
*/
