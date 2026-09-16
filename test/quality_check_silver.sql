/*========================================================================================
    Quality Check Script: quality_check_silver.sql

    Description:
        Performs data quality checks on the Silver layer after the Silver load
        procedure has completed.

    Layer:
        Silver

    Purpose:
        Validate that the Silver layer has been properly:
            - Cleaned
            - Standardized
            - Deduplicated
            - Validated
            - Transformed

    Validation Areas:
        1. NULL / Missing Values
        2. Duplicate Records
        3. Invalid / Unexpected Values
        4. Date Validation
        5. Business Rule Validation
        6. Referential Integrity
        7. Bronze-to-Silver Row Count Comparison

    Important:
        This script is READ-ONLY.
        It does not INSERT, UPDATE, DELETE, or modify any data.

    Usage:
        Run this script after:

            EXEC bronze.load_bronze;
            EXEC silver.load_silver;

    Expected Result:
        Each query should return ZERO rows for checks where invalid
        records are expected to be absent.

========================================================================================*/


USE DataWarehouse;
GO


/*========================================================================================
    1. CRM CUSTOMER INFORMATION
========================================================================================*/


/*----------------------------------------------------------------------------------------
    1.1 Check for NULL Customer IDs

    cst_id is the business identifier for a customer and should not be NULL.
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'CRM CUSTOMER INFORMATION - NULL CHECKS';
PRINT '==========================================';

SELECT
    *
FROM silver.crm_cust_info
WHERE cst_id IS NULL;


/*----------------------------------------------------------------------------------------
    1.2 Check for Duplicate Customer IDs

    Each customer should have only one active/latest record in Silver.

    Expected Result:
        ZERO rows
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for duplicate customer IDs...';

SELECT
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;


/*----------------------------------------------------------------------------------------
    1.3 Check for Missing Customer Keys
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for NULL customer keys...';

SELECT
    *
FROM silver.crm_cust_info
WHERE cst_key IS NULL
   OR TRIM(cst_key) = '';


/*----------------------------------------------------------------------------------------
    1.4 Check for Missing Customer Names
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for NULL customer names...';

SELECT
    *
FROM silver.crm_cust_info
WHERE cst_firstname IS NULL
   OR TRIM(cst_firstname) = ''
   OR cst_lastname IS NULL
   OR TRIM(cst_lastname) = '';


/*----------------------------------------------------------------------------------------
    1.5 Check Standardized Marital Status

    Valid Silver values:
        Single
        Married
        n/a
----------------------------------------------------------------------------------------*/

PRINT '>> Checking marital status values...';

SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN
(
    'Single',
    'Married',
    'n/a'
);


/*----------------------------------------------------------------------------------------
    1.6 Check Standardized Gender

    Valid Silver values:
        Male
        Female
        n/a
----------------------------------------------------------------------------------------*/

PRINT '>> Checking gender values...';

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN
(
    'Male',
    'Female',
    'n/a'
);


/*----------------------------------------------------------------------------------------
    1.7 Check Customer Creation Date
----------------------------------------------------------------------------------------*/

PRINT '>> Checking NULL customer creation dates...';

SELECT
    *
FROM silver.crm_cust_info
WHERE cst_create_date IS NULL;


/*========================================================================================
    2. CRM PRODUCT INFORMATION
========================================================================================*/


/*----------------------------------------------------------------------------------------
    2.1 Check for NULL Product IDs
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'CRM PRODUCT INFORMATION - NULL CHECKS';
PRINT '==========================================';

SELECT
    *
FROM silver.crm_prd_info
WHERE prd_id IS NULL;


/*----------------------------------------------------------------------------------------
    2.2 Check for Duplicate Product IDs

    Expected Result:
        ZERO rows
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for duplicate product IDs...';

SELECT
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;


/*----------------------------------------------------------------------------------------
    2.3 Check Product Keys
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for NULL product keys...';

SELECT
    *
FROM silver.crm_prd_info
WHERE prd_key IS NULL
   OR TRIM(prd_key) = '';


/*----------------------------------------------------------------------------------------
    2.4 Check Product Costs

    The Silver load converts NULL product costs to 0.

    Therefore, NULL values should not exist.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for NULL product costs...';

SELECT
    *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL;


/*----------------------------------------------------------------------------------------
    2.5 Check Product Line Values

    Valid standardized values:
        Mountain
        Road
        Other Sales
        Touring
        n/a
----------------------------------------------------------------------------------------*/

PRINT '>> Checking product line values...';

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info
WHERE prd_line NOT IN
(
    'Mountain',
    'Road',
    'Other Sales',
    'Touring',
    'n/a'
);


/*----------------------------------------------------------------------------------------
    2.6 Check Product Start Dates
----------------------------------------------------------------------------------------*/

PRINT '>> Checking NULL product start dates...';

SELECT
    *
FROM silver.crm_prd_info
WHERE prd_start_dt IS NULL;


/*----------------------------------------------------------------------------------------
    2.7 Check Product Date Range

    Product end date should not be earlier than the start date.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid product date ranges...';

SELECT
    *
FROM silver.crm_prd_info
WHERE prd_end_dt IS NOT NULL
  AND prd_end_dt < prd_start_dt;


/*----------------------------------------------------------------------------------------
    2.8 Check Overlapping Product Date Ranges

    For the same product key, validity periods should not overlap.

    The LEAD() transformation in the Silver load is designed to create
    non-overlapping validity periods.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking overlapping product date ranges...';

SELECT
    p1.prd_key,
    p1.prd_start_dt,
    p1.prd_end_dt,
    p2.prd_start_dt AS next_start_dt
FROM silver.crm_prd_info p1
JOIN silver.crm_prd_info p2
    ON p1.prd_key = p2.prd_key
   AND p1.prd_start_dt < p2.prd_start_dt
WHERE p1.prd_end_dt IS NOT NULL
  AND p1.prd_end_dt >= p2.prd_start_dt;


/*========================================================================================
    3. CRM SALES DETAILS
========================================================================================*/


/*----------------------------------------------------------------------------------------
    3.1 Check for NULL Order Numbers
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'CRM SALES DETAILS - NULL CHECKS';
PRINT '==========================================';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL
   OR TRIM(sls_ord_num) = '';


/*----------------------------------------------------------------------------------------
    3.2 Check for NULL Product Keys
----------------------------------------------------------------------------------------*/

PRINT '>> Checking NULL sales product keys...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_prd_key IS NULL
   OR TRIM(sls_prd_key) = '';


/*----------------------------------------------------------------------------------------
    3.3 Check for NULL Customer IDs
----------------------------------------------------------------------------------------*/

PRINT '>> Checking NULL sales customer IDs...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_cust_id IS NULL;


/*----------------------------------------------------------------------------------------
    3.4 Check Sales Dates

    Invalid Bronze date values should have been converted to NULL.

    This check verifies that valid dates exist where expected.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid sales dates...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > GETDATE()
   OR sls_ship_dt > GETDATE()
   OR sls_due_dt > GETDATE();


/*----------------------------------------------------------------------------------------
    3.5 Check Shipping Date

    Ship date should normally be on or after order date.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid order/ship date relationship...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND sls_ship_dt IS NOT NULL
  AND sls_ship_dt < sls_order_dt;


/*----------------------------------------------------------------------------------------
    3.6 Check Due Date

    Due date should normally be on or after order date.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid order/due date relationship...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL
  AND sls_due_dt IS NOT NULL
  AND sls_due_dt < sls_order_dt;


/*----------------------------------------------------------------------------------------
    3.7 Check Sales Amount

    Sales should be greater than zero after Silver transformation.

    Expected Result:
        ZERO rows
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid sales amounts...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_sales <= 0;


/*----------------------------------------------------------------------------------------
    3.8 Check Quantity

    Quantity should be greater than zero.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid quantities...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_quantity IS NULL
   OR sls_quantity <= 0;


/*----------------------------------------------------------------------------------------
    3.9 Check Price

    Price should be greater than zero after transformation.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking invalid prices...';

SELECT
    *
FROM silver.crm_sales_details
WHERE sls_price IS NULL
   OR sls_price <= 0;


/*----------------------------------------------------------------------------------------
    3.10 Validate Sales Calculation

    Business Rule:

        Sales = Quantity × Price

    Allow a small decimal difference using ROUND() for comparison.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking sales calculation...';

SELECT
    *
FROM silver.crm_sales_details
WHERE ROUND(sls_sales, 2)
      <> ROUND(sls_quantity * sls_price, 2);


/*========================================================================================
    4. ERP CUSTOMER INFORMATION
========================================================================================*/


/*----------------------------------------------------------------------------------------
    4.1 Check for NULL Customer IDs
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'ERP CUSTOMER INFORMATION';
PRINT '==========================================';

SELECT
    *
FROM silver.erp_cust_az12
WHERE cid IS NULL
   OR TRIM(cid) = '';


/*----------------------------------------------------------------------------------------
    4.2 Check Future Birth Dates

    The Silver transformation converts future birth dates to NULL.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking future birth dates...';

SELECT
    *
FROM silver.erp_cust_az12
WHERE bdate > CAST(GETDATE() AS DATE);


/*----------------------------------------------------------------------------------------
    4.3 Check Standardized Gender Values
----------------------------------------------------------------------------------------*/

PRINT '>> Checking ERP gender values...';

SELECT DISTINCT
    gen
FROM silver.erp_cust_az12
WHERE gen NOT IN
(
    'Male',
    'Female',
    'n/a'
);


/*========================================================================================
    5. ERP LOCATION INFORMATION
========================================================================================*/


/*----------------------------------------------------------------------------------------
    5.1 Check for NULL Customer IDs
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'ERP LOCATION INFORMATION';
PRINT '==========================================';

SELECT
    *
FROM silver.erp_loc_a101
WHERE cid IS NULL
   OR TRIM(cid) = '';


/*----------------------------------------------------------------------------------------
    5.2 Check Country Values

    Verify that country values have been standardized correctly.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking NULL / blank country values...';

SELECT
    *
FROM silver.erp_loc_a101
WHERE cntry IS NULL
   OR TRIM(cntry) = '';


/*----------------------------------------------------------------------------------------
    5.3 Check for Unclean Country Codes

    DE, US, and USA should have been standardized during Silver loading.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking for unstandardized country codes...';

SELECT
    *
FROM silver.erp_loc_a101
WHERE UPPER(TRIM(cntry)) IN
(
    'DE',
    'US',
    'USA'
);


/*========================================================================================
    6. ERP PRODUCT CATEGORY INFORMATION
========================================================================================*/


/*----------------------------------------------------------------------------------------
    6.1 Check for NULL Category IDs
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'ERP PRODUCT CATEGORY INFORMATION';
PRINT '==========================================';

SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE ID IS NULL
   OR TRIM(ID) = '';


/*----------------------------------------------------------------------------------------
    6.2 Check for NULL Category / Subcategory Values
----------------------------------------------------------------------------------------*/

PRINT '>> Checking NULL category values...';

SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE CAT IS NULL
   OR TRIM(CAT) = ''
   OR SUBCAT IS NULL
   OR TRIM(SUBCAT) = '';


/*========================================================================================
    7. REFERENTIAL INTEGRITY CHECKS
========================================================================================*/


/*----------------------------------------------------------------------------------------
    7.1 Sales → Customer

    Every sales record should ideally have a matching customer in the customer
    master data.

    Note:
        This check identifies orphan records. Depending on the source system,
        an orphan may be legitimate, so investigate before treating it as an error.
----------------------------------------------------------------------------------------*/

PRINT '==========================================';
PRINT 'REFERENTIAL INTEGRITY CHECKS';
PRINT '==========================================';

PRINT '>> Checking sales records without matching customers...';

SELECT
    s.sls_cust_id,
    COUNT(*) AS sales_record_count
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_cust_info c
    ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL
GROUP BY s.sls_cust_id;


/*----------------------------------------------------------------------------------------
    7.2 Sales → Product

    Every sales product key should ideally have a corresponding product
    in the Silver product master.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking sales records without matching products...';

SELECT
    s.sls_prd_key,
    COUNT(*) AS sales_record_count
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL
GROUP BY s.sls_prd_key;


/*----------------------------------------------------------------------------------------
    7.3 Product → Category

    Every product category should ideally exist in the ERP category table.

    This assumes the category ID formats between these tables are intended
    to match.
----------------------------------------------------------------------------------------*/

PRINT '>> Checking products without matching categories...';

SELECT
    p.cat_id,
    COUNT(*) AS product_count
FROM silver.crm_prd_info p
LEFT JOIN silver.erp_px_cat_g1v2 c
    ON p.cat_id = c.ID
WHERE c.ID IS NULL
GROUP BY p.cat_id;


/*========================================================================================
    8. BRONZE → SILVER ROW COUNT COMPARISON
========================================================================================

    Purpose:
        Identify unexpected record loss during Silver transformation.

    Important:
        Row counts do not always have to be identical.

        Example:
            crm_cust_info can have fewer Silver records because duplicate
            customer IDs are intentionally removed.

        Therefore, differences should be investigated rather than automatically
        treated as failures.
========================================================================================*/

PRINT '==========================================';
PRINT 'BRONZE → SILVER ROW COUNT COMPARISON';
PRINT '==========================================';


SELECT
    'crm_cust_info' AS table_name,
    (SELECT COUNT(*) FROM bronze.crm_cust_info) AS bronze_count,
    (SELECT COUNT(*) FROM silver.crm_cust_info) AS silver_count,
    (SELECT COUNT(*) FROM bronze.crm_cust_info)
        - (SELECT COUNT(*) FROM silver.crm_cust_info) AS difference

UNION ALL

SELECT
    'crm_prd_info',
    (SELECT COUNT(*) FROM bronze.crm_prd_info),
    (SELECT COUNT(*) FROM silver.crm_prd_info),
    (SELECT COUNT(*) FROM bronze.crm_prd_info)
        - (SELECT COUNT(*) FROM silver.crm_prd_info)

UNION ALL

SELECT
    'crm_sales_details',
    (SELECT COUNT(*) FROM bronze.crm_sales_details),
    (SELECT COUNT(*) FROM silver.crm_sales_details),
    (SELECT COUNT(*) FROM bronze.crm_sales_details)
        - (SELECT COUNT(*) FROM silver.crm_sales_details)

UNION ALL

SELECT
    'erp_cust_az12',
    (SELECT COUNT(*) FROM bronze.erp_cust_az12),
    (SELECT COUNT(*) FROM silver.erp_cust_az12),
    (SELECT COUNT(*) FROM bronze.erp_cust_az12)
        - (SELECT COUNT(*) FROM silver.erp_cust_az12)

UNION ALL

SELECT
    'erp_loc_a101',
    (SELECT COUNT(*) FROM bronze.erp_loc_a101),
    (SELECT COUNT(*) FROM silver.erp_loc_a101),
    (SELECT COUNT(*) FROM bronze.erp_loc_a101)
        - (SELECT COUNT(*) FROM silver.erp_loc_a101)

UNION ALL

SELECT
    'erp_px_cat_g1v2',
    (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2),
    (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2),
    (SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2)
        - (SELECT COUNT(*) FROM silver.erp_px_cat_g1v2);


/*========================================================================================
    9. SILVER TABLE ROW COUNTS
========================================================================================

    Provides a quick overview of the current Silver layer after loading.
========================================================================================*/

PRINT '==========================================';
PRINT 'SILVER LAYER ROW COUNTS';
PRINT '==========================================';

SELECT
    'crm_cust_info' AS table_name,
    COUNT(*) AS row_count
FROM silver.crm_cust_info

UNION ALL

SELECT
    'crm_prd_info',
    COUNT(*)
FROM silver.crm_prd_info

UNION ALL

SELECT
    'crm_sales_details',
    COUNT(*)
FROM silver.crm_sales_details

UNION ALL

SELECT
    'erp_cust_az12',
    COUNT(*)
FROM silver.erp_cust_az12

UNION ALL

SELECT
    'erp_loc_a101',
    COUNT(*)
FROM silver.erp_loc_a101

UNION ALL

SELECT
    'erp_px_cat_g1v2',
    COUNT(*)
FROM silver.erp_px_cat_g1v2;


/*========================================================================================
    QUALITY CHECK COMPLETED
========================================================================================*/

PRINT '==========================================';
PRINT 'SILVER LAYER QUALITY CHECK COMPLETED';
PRINT '==========================================';
