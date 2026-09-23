# Data Warehouse and Analytics Project

Welcome to the **Data Warehouse and Analytics Project** repository! 🚀  
This project demonstrates an end-to-end data warehousing and analytics solution, from ingesting raw data and building a modern data warehouse to performing exploratory data analysis and generating business-ready reports.

Designed as a portfolio project, it highlights practical concepts in **SQL Server, data engineering, data modeling, data quality, exploratory data analysis, and analytics**.

---

## 🏗️ Data Architecture

The data architecture follows the **Medallion Architecture**, consisting of **Bronze, Silver, and Gold** layers, followed by an **Exploratory Data Analysis (EDA)** layer for analytical exploration.

```text
                    Source Systems
                 (CRM & ERP CSV Files)
                         │
                         ▼
                ┌─────────────────┐
                │  Bronze Layer   │
                │   Raw Data      │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │  Silver Layer   │
                │ Clean &          │
                │ Standardized     │
                └────────┬────────┘
                         │
                         ▼
                ┌─────────────────┐
                │   Gold Layer    │
                │ Star Schema &   │
                │ Business Models │
                └────────┬────────┘
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
      ┌───────────────┐     ┌────────────────┐
      │     EDA       │     │    Reporting   │
      │ Exploratory   │     │ Customer &     │
      │ Analysis      │     │ Product Views  │
      └───────┬───────┘     └───────┬────────┘
              │                     │
              └──────────┬──────────┘
                         ▼
                Business Insights
````

### Layers

1. **Bronze Layer**: Stores raw data as-is from the source systems. Data is ingested from CSV files into SQL Server.
2. **Silver Layer**: Performs data cleansing, standardization, validation, and transformation to prepare the data for analytical use.
3. **Gold Layer**: Contains business-ready data modeled using a star schema with fact and dimension views.
4. **EDA Layer**: Uses the Gold layer to explore data, identify trends and patterns, analyze business metrics, segment customers and products, and generate insights.
5. **Reporting Layer**: Provides reusable customer- and product-level reporting views containing business KPIs and performance metrics.

---

## 📖 Project Overview

This project covers the following areas:

1. **Data Architecture**: Designing a modern data warehouse using Medallion Architecture.
2. **ETL Pipelines**: Extracting, transforming, and loading data from CRM and ERP source systems into SQL Server.
3. **Data Quality & Validation**: Identifying and resolving data quality issues throughout the Bronze, Silver, and Gold layers.
4. **Data Modeling**: Developing fact and dimension models optimized for analytical queries.
5. **Exploratory Data Analysis**: Using SQL to explore customer behavior, product performance, sales trends, segmentation, and business metrics.
6. **Analytics & Reporting**: Creating reusable SQL reporting views for customer- and product-level analysis.
7. **Business Insights**: Translating analytical findings into meaningful insights that can support business decision-making.

---

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

#### Objective

Develop a modern data warehouse using SQL Server to consolidate sales data, enabling analytical reporting and informed decision-making.

#### Specifications

* **Data Sources**: Import data from two source systems (ERP and CRM) provided as CSV files.
* **Data Quality**: Cleanse, standardize, and resolve data quality issues prior to analysis.
* **Integration**: Combine both source systems into a single, user-friendly data model designed for analytical queries.
* **Scope**: Focus on the latest dataset only; historization of data is not required.
* **Data Modeling**: Build a star schema consisting of fact and dimension models.
* **Documentation**: Provide clear documentation of the data model, naming conventions, and data definitions.

---

### 📊 Exploratory Data Analysis (EDA)

#### Objective

Explore the business data using SQL to understand patterns, trends, customer behavior, and product performance before generating business reports and insights.

The EDA layer is built on top of the **Gold layer** and includes analyses such as:

* **Database & Schema Exploration**
* **Dimension Exploration**
* **Date Range & Customer Analysis**
* **Business Metrics & KPIs**
* **Customer & Product Dimension Analysis**
* **Product and Customer Ranking**
* **Sales Trends Over Time**
* **Cumulative Sales Analysis**
* **Product Performance Analysis**
* **Customer & Product Segmentation**
* **Part-to-Whole Analysis**

The EDA scripts demonstrate practical SQL concepts including:

* Aggregations and `GROUP BY`
* Common Table Expressions (CTEs)
* Window functions
* Ranking functions
* Date functions
* Conditional logic using `CASE`
* Running totals
* Year-over-year analysis
* Customer and product segmentation
* Percentage-of-total calculations
* Multi-table joins

The goal of the EDA layer is to transform the modeled warehouse data into **meaningful analytical findings** that can be used for reporting and business decision-making.

---

### 📈 BI: Analytics & Reporting (Data Analysis)

#### Objective

Develop reusable SQL-based reporting views that provide detailed customer- and product-level insights.

The reporting layer includes:

* **Customer Report**

  * Customer demographics
  * Age groups
  * Customer segmentation
  * Total orders and sales
  * Product count
  * Customer lifespan
  * Recency
  * Average order value
  * Average monthly spending

* **Product Report**

  * Product hierarchy
  * Total orders and sales
  * Quantity sold
  * Customer reach
  * Product lifespan
  * Recency
  * Average selling price
  * Product performance segmentation
  * Average order revenue
  * Average monthly revenue

These reporting views provide a reusable foundation for dashboards, BI tools, and further analytical work.

---

## 📂 Repository Structure

```text
data-warehouse-project/
│
├── datasets/                           # Raw datasets used for the project
│   ├── source_crm/
│   └── source_erp/
│
├── docs/                               # Project documentation
│   ├── data_catalog.md                 # Data definitions and metadata
│   ├── naming-conventions.md           # Naming conventions
│   └── requirements.md                 # Project requirements
│
├── scripts/                            # SQL scripts
│   │
│   ├── init_database.sql               # Database and schema initialization
│   │
│   ├── bronze/                         # Raw data ingestion
│   │   ├── ddl_bronze.sql              # Bronze table definitions
│   │   └── load_bronze.sql             # Bronze data loading procedures
│   │
│   ├── silver/                         # Data cleansing and transformation
│   │   ├── ddl_silver.sql              # Silver table definitions
│   │   ├── load_silver.sql             # Silver transformation procedures
│   │   └── quality_check_silver.sql    # Silver data quality checks
│   │
│   ├── gold/                           # Business-ready analytical layer
│   │   ├── ddl_gold.sql                # Gold dimension and fact views
│   │   ├── quality_check_gold.sql      # Gold data quality checks
│   │   ├── data_catalog.md             # Gold data catalog
│   │   ├── naming_convention.md        # Gold naming conventions
│   │   ├── report_customer.sql         # Customer reporting view
│   │   └── report_product.sql          # Product reporting view
│   │
│   └── EDA/                            # Exploratory Data Analysis
│       ├── 00_explore_gold_schema.sql
│       ├── 01_explore_dimensions.sql
│       ├── 02_explore_date_range_and_customers.sql
│       ├── 03_calculate_business_metrics.sql
│       ├── 04_analyze_dimensions.sql
│       ├── 05_rank_products_and_customers.sql
│       ├── 06_sales_change_over_time.sql
│       ├── 07_cumulative_analysis.sql
│       ├── 08_analyze_product_performance.sql
│       ├── 09_data_segmentation.sql
│       └── 10_part_to_whole_analysis.sql
│
├── tests/                              # Additional test scripts
│
├── README.md                           # Project overview and instructions
├── LICENSE                             # License information
├── .gitignore                          # Files and directories ignored by Git
└── requirements.txt                    # Project dependencies
```

---

## 🔄 End-to-End Workflow

The overall project workflow can be summarized as:

```text
CSV Source Data
      │
      ▼
Bronze Layer
Raw Data Ingestion
      │
      ▼
Silver Layer
Cleaning & Transformation
      │
      ▼
Gold Layer
Star Schema & Business-Ready Data
      │
      ├──────────────────┐
      ▼                  ▼
     EDA             Reporting
      │                  │
      ▼                  ▼
Exploration &       Customer &
Business Analysis   Product KPIs
      │                  │
      └─────────┬────────┘
                ▼
        Business Insights
```

---

## 🛡️ License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.
