/*
================================================================================
Script:     ddl_bronze.sql
Purpose:    Create Bronze Layer tables for the Data Warehouse.

Description:
    This script creates the physical tables used to store raw data from
    CRM and ERP source systems in the Bronze layer.

    The Bronze layer stores data as close to the source format as possible.
    Minimal transformation or business logic should be applied at this stage.

Source Systems:
    - CRM (Customer Relationship Management)
    - ERP (Enterprise Resource Planning)

Tables Created:
    CRM:
        1. bronze.crm_cust_info
        2. bronze.crm_prd_info
        3. bronze.crm_sales_details

    ERP:
        4. bronze.erp_cust_az12
        5. bronze.erp_loc_a101
        6. bronze.erp_px_cat_g1v2

IMPORTANT:
    - This script DROPS the existing Bronze tables before recreating them.
    - Any existing data in these tables will be permanently deleted.
    - Run this script only when initializing or intentionally resetting
      the Bronze layer.
    - Data types are designed based on the expected source CSV structure.

Architecture:
    
    Source Systems
         |
         v
      Bronze
    (Raw Data)
         |
         v
      Silver
    (Cleaned Data)
         |
         v
       Gold
    (Business Data)

================================================================================
*/


/*==============================================================================
    CRM TABLES
==============================================================================*/


/*------------------------------------------------------------------------------
    1. CRM Customer Information

    Stores customer master data received from the CRM source system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info
(
    cst_id              INT,
    cst_key             NVARCHAR(50),
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status   NVARCHAR(50),
    cst_gndr             NVARCHAR(50),
    cst_create_date      DATE
);
GO


/*------------------------------------------------------------------------------
    2. CRM Product Information

    Stores product master data received from the CRM source system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info
(
    prd_id          INT,
    prd_key         NVARCHAR(50),
    prd_nm          NVARCHAR(50),
    prd_cost        INT,
    prd_line        NVARCHAR(50),
    prd_start_dt    DATETIME,
    prd_end_dt      DATETIME
);
GO


/*------------------------------------------------------------------------------
    3. CRM Sales Details

    Stores sales transaction data received from the CRM source system.

    NOTE:
    The date fields are currently stored as INT because the source data
    represents dates in numeric format. These values can be converted and
    validated later during the Silver-layer transformation.
------------------------------------------------------------------------------*/

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details
(
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    INT,
    sls_ship_dt     INT,
    sls_due_dt      INT,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT
);
GO



/*==============================================================================
    ERP TABLES
==============================================================================*/


/*------------------------------------------------------------------------------
    4. ERP Customer Information

    Stores customer demographic information received from the ERP system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12
(
    CID     NVARCHAR(50),
    BDATE   DATE,
    GEN     NVARCHAR(50)
);
GO


/*------------------------------------------------------------------------------
    5. ERP Location Information

    Stores customer location/country information received from the ERP system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101
(
    CID     NVARCHAR(50),
    CNTRY   NVARCHAR(50)
);
GO


/*------------------------------------------------------------------------------
    6. ERP Product Category Information

    Stores product category, subcategory, and maintenance information
    received from the ERP system.
------------------------------------------------------------------------------*/

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2
(
    ID            NVARCHAR(50),
    CAT           NVARCHAR(50),
    SUBCAT        NVARCHAR(50),
    MAINTENANCE   NVARCHAR(50)
);
GO


/*==============================================================================
    END OF BRONZE LAYER TABLE CREATION
==============================================================================*/
