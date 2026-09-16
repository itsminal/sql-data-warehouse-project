/*========================================================================================
    Stored Procedure: silver.load_silver
    Description:
        Loads and transforms data from the Bronze layer into the Silver layer.

    Layer:
        Silver

    Load Strategy:
        FULL LOAD

    Full Load Approach:
        1. Truncate the existing Silver table.
        2. Read the complete dataset from the Bronze layer.
        3. Clean, standardize, validate, and transform the data.
        4. Insert the transformed data into the Silver table.

    Purpose of Silver Layer:
        - Clean and standardize raw Bronze data.
        - Handle missing and invalid values.
        - Standardize text values and formats.
        - Convert data types where required.
        - Remove duplicate customer records.
        - Apply basic business rules and derived transformations.

    Important Note:
        This procedure uses TRUNCATE + INSERT, so every execution reloads
        the complete Silver layer from the Bronze layer.

    Author:      [Your Name]
    Created:     [Date]
========================================================================================*/


CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    /*====================================================================================
        Variable Declarations
        ----------------------------------------------------------------------------------
        @start_time / @end_time:
            Track the duration of loading each individual table.

        @proc_start_time / @proc_end_time:
            Track the total duration of the Silver layer load.
    ====================================================================================*/

    DECLARE
        @start_time      DATETIME,
        @end_time        DATETIME,
        @proc_start_time DATETIME,
        @proc_end_time   DATETIME;


    BEGIN TRY

        /*================================================================================
            Start Silver Layer Load
        =================================================================================*/

        SET @proc_start_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Loading Silver Layer';
        PRINT 'Load Type: FULL LOAD';
        PRINT '==========================================';


        /*================================================================================
            CRM TABLES
        =================================================================================*/

        PRINT '==========================================';
        PRINT 'Loading CRM Tables';
        PRINT '==========================================';


        /*================================================================================
            1. CRM Customer Information
            --------------------------------------------------------------------------------
            Transformations:
                - Remove duplicate customer records using ROW_NUMBER().
                - Keep the latest record based on cst_create_date.
                - Trim leading/trailing spaces from names.
                - Standardize marital status.
                - Standardize gender values.
                - Replace unknown values with 'n/a'.

            Deduplication Logic:
                Customers are partitioned by cst_id and ordered by cst_create_date
                in descending order. The most recent record receives flag_last = 1.
        =================================================================================*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: silver.crm_cust_info';

        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into: silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info
        (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,

            -- Standardize marital status values
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                    THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                    THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,

            -- Standardize gender values
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F'
                    THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M'
                    THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date

        FROM
        (
            SELECT
                *,
                ROW_NUMBER() OVER
                (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last

            FROM bronze.crm_cust_info

            -- Ignore records without a customer ID
            WHERE cst_id IS NOT NULL

        ) AS t

        -- Keep only the latest record for each customer
        WHERE flag_last = 1;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '==========================================';


        /*================================================================================
            2. CRM Product Information
            --------------------------------------------------------------------------------
            Transformations:
                - Derive category ID from product key.
                - Standardize product key format.
                - Replace NULL product cost with 0.
                - Convert product line codes into descriptive values.
                - Convert product start date to DATE.
                - Derive product end date using LEAD().

            Product End Date Logic:
                The next product start date - 1 day is used as the current product's
                end date. This helps represent the validity period of each product
                record.
        =================================================================================*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: silver.crm_prd_info';

        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into: silver.crm_prd_info';

        INSERT INTO silver.crm_prd_info
        (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            -- Extract category ID from product key
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ) AS cat_id,

            -- Extract product-specific portion of product key
            SUBSTRING(
                prd_key,
                7,
                LEN(prd_key)
            ) AS prd_key,

            prd_nm,

            -- Replace missing product cost with 0
            ISNULL(prd_cost, 0) AS prd_cost,

            -- Convert product line codes into descriptive values
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            -- Convert start date to DATE
            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            -- Derive end date from the next product start date
            CAST
            (
                LEAD(prd_start_dt) OVER
                (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt ASC
                ) - 1
                AS DATE
            ) AS prd_end_dt

        FROM bronze.crm_prd_info;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '==========================================';


        /*================================================================================
            3. CRM Sales Details
            --------------------------------------------------------------------------------
            Transformations:
                - Convert integer-based dates into DATE.
                - Handle invalid or missing dates.
                - Validate sales amount.
                - Calculate sales amount when the source value is invalid.
                - Handle invalid or missing prices.
                - Calculate price from sales and quantity when necessary.

            Date Validation:
                Dates with incorrect length or value 0 are converted to NULL.

            Sales Validation:
                If sales is NULL, <= 0, or does not match:
                    quantity * ABS(price)
                then the sales amount is recalculated.

            Price Validation:
                If price is NULL or <= 0, price is recalculated as:
                    sales / quantity

                NULLIF prevents division-by-zero errors.
        =================================================================================*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: silver.crm_sales_details';

        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into: silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details
        (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Convert order date from YYYYMMDD integer format to DATE
            CASE
                WHEN LEN(sls_order_dt) <> 8
                     OR sls_order_dt = 0
                    THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,

            -- Convert ship date from YYYYMMDD integer format to DATE
            CASE
                WHEN LEN(sls_ship_dt) <> 8
                     OR sls_ship_dt = 0
                    THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,

            -- Convert due date from YYYYMMDD integer format to DATE
            CASE
                WHEN LEN(sls_due_dt) <> 8
                     OR sls_due_dt = 0
                    THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,

            -- Validate and recalculate sales amount when necessary
            CASE
                WHEN sls_sales <= 0
                     OR sls_sales IS NULL
                     OR sls_sales <> (sls_quantity * ABS(sls_price))
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Validate and recalculate price when necessary
            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price

        FROM bronze.crm_sales_details;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '==========================================';


        /*================================================================================
            ERP TABLES
        =================================================================================*/

        PRINT '==========================================';
        PRINT 'Loading ERP Tables';
        PRINT '==========================================';


        /*================================================================================
            4. ERP Customer Information
            --------------------------------------------------------------------------------
            Transformations:
                - Remove 'NAS' prefix from customer IDs.
                - Replace future birth dates with NULL.
                - Standardize gender values.
                - Replace unknown gender values with 'n/a'.
        =================================================================================*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: silver.erp_cust_az12';

        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12
        (
            cid,
            bdate,
            gen
        )
        SELECT
            -- Remove 'NAS' prefix from customer ID
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            -- Future birth dates are considered invalid
            CASE
                WHEN bdate > GETDATE()
                    THEN NULL
                ELSE bdate
            END AS bdate,

            -- Standardize gender values
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'n/a'
            END AS gen

        FROM bronze.erp_cust_az12;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '==========================================';


        /*================================================================================
            5. ERP Location Information
            --------------------------------------------------------------------------------
            Transformations:
                - Remove '-' characters from customer IDs.
                - Standardize country names.
                - Convert US/USA variations to 'United States'.
                - Convert DE to 'Germany'.
                - Replace missing countries with 'n/a'.
        =================================================================================*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: silver.erp_loc_a101';

        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101
        (
            cid,
            cntry
        )
        SELECT
            -- Standardize customer ID format
            REPLACE(cid, '-', '') AS cid,

            -- Standardize country values
            CASE
                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'

                WHEN TRIM(cntry) IN ('USA', 'US')
                    THEN 'United States'

                WHEN TRIM(cntry) IS NULL
                     OR TRIM(cntry) = ''
                    THEN 'n/a'

                ELSE TRIM(cntry)
            END AS cntry

        FROM bronze.erp_loc_a101;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '==========================================';


        /*================================================================================
            6. ERP Product Category Information
            --------------------------------------------------------------------------------
            This table currently does not require major transformations.

            The data is transferred from Bronze to Silver while maintaining
            the same business attributes.

            Future transformations can be added here if additional data
            cleansing or standardization is required.
        =================================================================================*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: silver.erp_px_cat_g1v2';

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2
        (
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        )
        SELECT
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE

        FROM bronze.erp_px_cat_g1v2;


        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '==========================================';


        /*================================================================================
            Silver Layer Load Completed
        =================================================================================*/

        SET @proc_end_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Silver Layer Load Completed Successfully';
        PRINT 'Load Type: FULL LOAD';
        PRINT '==========================================';

        PRINT '>> Total Silver Layer Load Duration: '
            + CAST
            (
                DATEDIFF
                (
                    SECOND,
                    @proc_start_time,
                    @proc_end_time
                ) AS NVARCHAR
            )
            + ' seconds';

        PRINT '==========================================';


    END TRY


    /*====================================================================================
        Error Handling
        ----------------------------------------------------------------------------------
        If any error occurs during the load:
            - Display a clear error message.
            - Display the SQL Server error number.
            - Display the error state.
            - Display the line where the error occurred.
            - THROW re-raises the original error for proper debugging/logging.
    ====================================================================================*/

    BEGIN CATCH

        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT '==========================================';

        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);

        PRINT '==========================================';

        -- Re-raise the original error
        THROW;

    END CATCH;

END;
GO


/*========================================================================================
    Execute Silver Layer Load
    ----------------------------------------------------------------------------------------
    IMPORTANT:
        Keep the EXEC statement outside the stored procedure.

        The procedure definition creates the procedure.
        The EXEC statement executes it.

        Keeping EXEC outside prevents the procedure from calling itself recursively.
========================================================================================*/

EXEC silver.load_silver;
GO
