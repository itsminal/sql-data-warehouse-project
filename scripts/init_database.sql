/*
================================================================================
Script:     init_database.sql
Purpose:    Initialize the DataWarehouse database and create the Bronze, Silver,
            and Gold schemas.

Description:
    This script:
      1. Checks whether the 'DataWarehouse' database already exists.
      2. Drops the existing database after terminating active connections.
      3. Creates a fresh 'DataWarehouse' database.
      4. Creates the following schemas:
           - bronze: Raw/source data
           - silver: Cleaned and transformed data
           - gold: Business-ready/analytical data

WARNING:
    This script is DESTRUCTIVE.
    If the 'DataWarehouse' database already exists, it will be permanently
    deleted along with all its data, tables, views, and other objects.

Prerequisites:
    - Microsoft SQL Server
    - Appropriate permissions to create and drop databases
    - Execute this script in SQL Server Management Studio (SSMS) or
      another SQL Server-compatible client.

Usage:
    Run this script when setting up the data warehouse from scratch or when
    you intentionally want to reset the development environment.

Architecture:
    Source Systems
          ↓
       Bronze
          ↓
       Silver
          ↓
        Gold
          ↓
    BI / Analytics

================================================================================
*/

USE master;
GO

-- Drop and recreate 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
