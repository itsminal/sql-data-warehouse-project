/*
================================================================================
Script:     ddl_silver.sql
Purpose:    Create Silver Layer tables for the Data Warehouse.

Description:
    This script creates the tables used to store CLEANED and TRANSFORMED data
    from the Bronze layer.

    Unlike the Bronze layer, the Silver layer is responsible for applying
    data quality rules, standardization, and transformations such as:
        - Data type conversions
        - Data cleansing
        - Handling invalid or missing values
        - Standardizing column formats
        - Removing duplicates
        - Deriving additional attributes where required

Source:
    Bronze Layer

Target:
    Silver Layer

Tables Created:
    CRM:
        1. silver.crm_cust_info
        2. silver.crm_prd_info
        3. silver.crm_sales_details

    ERP:
        4. silver.erp_cust_az12
        5. silver.erp_loc_a101
        6. silver.erp_px_cat_g1v2

IMPORTANT:
    - This script DROPS existing Silver tables before recreating them.
    - Any existing data in these tables will be permanently deleted.
    - This script is intended for initializing or resetting the Silver layer.
    - Data transformation and cleansing logic will be applied when loading
      data from Bronze into Silver.

Audit Column:
    dwh_create_date:
        - Stores the date and time when a record is inserted into the
          Silver table.
        - DEFAULT GETDATE() automatically populates this column when
          no value is explicitly provided.

Architecture:

    Source Systems
         |
         v
      Bronze
    (Raw Data)
         |
         |  Cleaning / Standardization
         |  Data Type Conversion
         |  Data Quality Checks
         v
      Silver
    (Cleaned Data)
         |
         v
       Gold
    (Business-Ready Data)

================================================================================
*/


/*==============================================================================
    CRM TABLES
==============================================================================*/


/*------------------------------------------------------------------------------
    1. CRM Customer Information

    Stores cleaned and standardized customer information originating from
    the CRM Bronze table.
------------------------------------------------------------------------------*/

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info
(
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),
    cst_gndr            NVARCHAR(50),
    cst_create_date     DATE,

    -- Audit column: stores the record creation timestamp in the DW.
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO


/*------------------------------------------------------------------------------
    2. CRM Product Information

    Stores cleaned and standardized product information.

    cat_id:
        Derived/standardized category identifier used to associate the
        product with the appropriate product category.
------------------------------------------------------------------------------*/

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info
(
    prd_id              INT,
    cat_id              NVARCHAR(50),
    prd_key             NVARCHAR(50),
    prd_nm              NVARCHAR(50),
    prd_cost            INT,
    prd_line            NVARCHAR(50),
    prd_start_dt        DATE,
    prd_end_dt          DATE,

    -- Audit column: stores the record creation timestamp in the DW.
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO


/*------------------------------------------------------------------------------
    3. CRM Sales Details

    Stores cleaned and standardized sales transaction data.

    NOTE:
        The Bronze layer stores the source date fields as INT.
        In the Silver layer, these fields are converted to DATE as part
        of the data transformation process.
------------------------------------------------------------------------------*/

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details
(
    sls_ord_num         NVARCHAR(50),
    sls_prd_key         NVARCHAR(50),
    sls_cust_id         INT,
    sls_order_dt        DATE,
    sls_ship_dt         DATE,
    sls_due_dt          DATE,
    sls_sales           INT,
    sls_quantity        INT,
    sls_price           INT,

    -- Audit column: stores the record creation timestamp in the DW.
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO



/*==============================================================================
    ERP TABLES
==============================================================================*/


/*------------------------------------------------------------------------------
    4. ERP Customer Information

    Stores cleaned and standardized customer demographic information
    originating from the ERP system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12
(
    CID                 NVARCHAR(50),
    BDATE               DATE,
    GEN                 NVARCHAR(50),

    -- Audit column: stores the record creation timestamp in the DW.
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO


/*------------------------------------------------------------------------------
    5. ERP Location Information

    Stores cleaned and standardized customer location information
    originating from the ERP system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101
(
    CID                 NVARCHAR(50),
    CNTRY               NVARCHAR(50),

    -- Audit column: stores the record creation timestamp in the DW.
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO


/*------------------------------------------------------------------------------
    6. ERP Product Category Information

    Stores cleaned and standardized product category information
    originating from the ERP system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2
(
    ID                  NVARCHAR(50),
    CAT                 NVARCHAR(50),
    SUBCAT              NVARCHAR(50),
    MAINTENANCE         NVARCHAR(50),

    -- Audit column: stores the record creation timestamp in the DW.
    dwh_create_date     DATETIME2 DEFAULT GETDATE()
);
GO


/*==============================================================================
    END OF SILVER LAYER TABLE CREATION
==============================================================================*/
