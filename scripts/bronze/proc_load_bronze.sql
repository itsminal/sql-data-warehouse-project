/*
================================================================================
Script:     load_bronze.sql
Purpose:    Load raw data from CRM and ERP CSV files into the Bronze layer.

Description:
    This stored procedure performs the initial data ingestion into the
    Data Warehouse Bronze layer.

    The procedure follows a FULL LOAD approach. Before loading new data,
    each Bronze table is completely truncated and then reloaded with the
    latest data from the source CSV files.

Load Strategy:
    FULL LOAD

    For every execution:
        1. Existing data in the Bronze table is removed using TRUNCATE TABLE.
        2. The complete source dataset is loaded using BULK INSERT.
        3. The load duration is measured and printed.

    This means the Bronze tables always contain a fresh copy of the
    complete source datasets after a successful execution.

Source Systems:
    - CRM (Customer Relationship Management)
    - ERP (Enterprise Resource Planning)

Tables Loaded:
    CRM:
        - bronze.crm_cust_info
        - bronze.crm_prd_info
        - bronze.crm_sales_details

    ERP:
        - bronze.erp_cust_az12
        - bronze.erp_loc_a101
        - bronze.erp_px_cat_g1v2

IMPORTANT:
    - This procedure uses TRUNCATE TABLE before every load.
    - Existing data in the Bronze tables will be deleted and replaced.
    - This is a FULL LOAD implementation, NOT an incremental load.
    - BULK INSERT reads files from the SQL Server machine. The specified
      file paths must therefore be accessible by the SQL Server service/account.
    - This implementation is suitable for small-to-medium datasets and
      learning/development environments.
    - For large production datasets, an incremental loading strategy may
      be preferred to avoid reloading the entire dataset every time.

Full Load vs Incremental Load:

    FULL LOAD:
        Source → TRUNCATE Target → Load Entire Dataset

    INCREMENTAL LOAD:
        Source → Identify New/Changed Records → Load Only Changes

Architecture:

    CRM CSV Files ─────┐
                       │
                       ├──> Bronze Layer ──> Silver Layer ──> Gold Layer
                       │
    ERP CSV Files ─────┘

================================================================================
*/


/*==============================================================================
    CREATE / ALTER STORED PROCEDURE
==============================================================================*/

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    /*--------------------------------------------------------------------------
        Variable Declaration
    --------------------------------------------------------------------------*/

    DECLARE
        @start_time      DATETIME,
        @end_time        DATETIME,
        @proc_start_time DATETIME,
        @proc_end_time   DATETIME;


    /*============================================================================
        TRY BLOCK
    ============================================================================*/

    BEGIN TRY

        /*----------------------------------------------------------------------
            Start Procedure Timer
        ----------------------------------------------------------------------*/

        SET @proc_start_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Loading Bronze Layer';
        PRINT 'Load Type: FULL LOAD';
        PRINT '==========================================';


        /*======================================================================
            CRM TABLES
        ======================================================================*/

        PRINT '==========================================';
        PRINT 'Loading CRM Tables';
        PRINT '==========================================';


        /*----------------------------------------------------------------------
            1. Load CRM Customer Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: bronze.crm_cust_info';

        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting Data Into: bronze.crm_cust_info';

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\ADMIN\Downloads\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*----------------------------------------------------------------------
            2. Load CRM Product Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: bronze.crm_prd_info';

        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting Data Into: bronze.crm_prd_info';

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\ADMIN\Downloads\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*----------------------------------------------------------------------
            3. Load CRM Sales Details
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: bronze.crm_sales_details';

        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting Data Into: bronze.crm_sales_details';

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\ADMIN\Downloads\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*======================================================================
            ERP TABLES
        ======================================================================*/

        PRINT '==========================================';
        PRINT 'Loading ERP Tables';
        PRINT '==========================================';


        /*----------------------------------------------------------------------
            4. Load ERP Customer Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: bronze.erp_cust_az12';

        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Inserting Data Into: bronze.erp_cust_az12';

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\ADMIN\Downloads\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*----------------------------------------------------------------------
            5. Load ERP Location Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: bronze.erp_loc_a101';

        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting Data Into: bronze.erp_loc_a101';

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\ADMIN\Downloads\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*----------------------------------------------------------------------
            6. Load ERP Product Category Information
        ----------------------------------------------------------------------*/

        SET @start_time = GETDATE();

        PRINT '>> Truncating table: bronze.erp_px_cat_g1v2';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\ADMIN\Downloads\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';


        /*======================================================================
            COMPLETION LOG
        ======================================================================*/

        SET @proc_end_time = GETDATE();

        PRINT '==========================================';
        PRINT 'Bronze Layer Load Completed Successfully';
        PRINT 'Load Type: FULL LOAD';
        PRINT '==========================================';

        PRINT '>> Total Bronze Layer Load Duration: '
            + CAST(
                DATEDIFF(
                    SECOND,
                    @proc_start_time,
                    @proc_end_time
                ) AS NVARCHAR
              )
            + ' seconds';

        PRINT '==========================================';


    /*============================================================================
        ERROR HANDLING
    ============================================================================*/

    END TRY

    BEGIN CATCH

        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER LOAD';
        PRINT '==========================================';

        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);

        PRINT '==========================================';

        -- Re-raise the error so the calling process knows the load failed.
        THROW;

    END CATCH;

END;
GO


/*==============================================================================
    EXECUTE STORED PROCEDURE

    IMPORTANT:
    Keep the EXEC statement OUTSIDE the procedure definition.

    The procedure uses a FULL LOAD strategy:
        TRUNCATE → BULK INSERT → Complete Dataset

    Do NOT place EXEC bronze.load_bronze inside the procedure itself,
    otherwise the procedure will call itself recursively.
==============================================================================*/

EXEC bronze.load_bronze;
GO
