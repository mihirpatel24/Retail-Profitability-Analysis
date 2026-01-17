/* ============================================================
   PROJECT: Superstore (E-commerce) Profitability Analysis
   PURPOSE: Import cleaned CSV into MySQL and run core analyses:
            - Discount vs Profit/Sales
            - Loss-making products
            - Category performance (incl. avg profit per order)
   ============================================================ */


-- 1) Create and select the project database
CREATE DATABASE IF NOT EXISTS record_analysis;
USE record_analysis;

-- 2) Reset the table to ensure a clean re-run of this script
DROP TABLE IF EXISTS records;

-- 3) Create table schema (column definitions + data types)
-- NOTE: product_name is TEXT because it can be long and may contain commas/special characters.
-- NOTE: order_year uses YEAR and order_month uses TINYINT (1–12) for fast time-based grouping.

CREATE TABLE records(
	category VARCHAR(40),
    city VARCHAR(40),
    customer_name VARCHAR(40),
    manufacturer VARCHAR(40),
    order_date DATE,
    order_id VARCHAR(40),
    postal_code INT,
    product_name TEXT,
    region VARCHAR(40),
    segment VARCHAR(40),
    ship_date DATE,
    ship_mode VARCHAR(40),
    state VARCHAR(40),
    sub_category VARCHAR(40),
    discount FLOAT,
    profit DECIMAL,
    profit_ratio INT,
    quantity INT,
    sales INT,
    order_year Year,
    order_month TINYINT
);

-- 4) Enable local file loading (required for LOAD DATA INFILE on some MySQL setups)
SET GLOBAL local_infile = 1;

-- 5) Load CSV data into the records table
-- Assumptions:
--   - Comma-separated values
--   - Text fields enclosed in double quotes
--   - First row contains headers (ignored)
-- IMPORTANT:
--   Ensure the CSV column order matches the table column order.
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 9.5/Uploads/Superstore__dataset.csv"
INTO TABLE records
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- 6) Quick table structure check (confirm columns + data types)
Describe records;

-- 7) Row count validation (sanity check vs Excel row count)
SELECT COUNT(*) FROM records;


-- ============================================================
-- ANALYSIS SECTION 1: Discount overview
-- ============================================================

-- 8) List all unique discount levels in the dataset (as percentages)
SELECT DISTINCT ROUND(discount * 100, 2) AS discounts
FROM records
ORDER BY discounts;


-- 9) Total profit by discount level
-- Goal: Identify discount levels that reduce overall profitability (profit leakage)
SELECT CONCAT(round(discount*100,2),'%') AS "Discount",
	SUM(profit) AS "Profit" 
	FROM records
	GROUP BY discount
	ORDER BY discount;

-- 10) Total sales (revenue) by discount level
-- Goal: See whether higher discounts drive revenue volume
SELECT CONCAT(ROUND(discount*100,2),"%") AS Discount,
	SUM(sales) AS Sales_Volume
    FROM records
    GROUP BY discount
    ORDER BY Sales_Volume DESC;

-- ============================================================
-- ANALYSIS SECTION 2: Loss-making products (net profit < 0)
-- ============================================================

-- 11) Count products whose total profit across all transactions is negative
SELECT COUNT(*) AS loss_making_products
FROM (
  SELECT product_name, SUM(profit) AS total_profit
  FROM records
  GROUP BY product_name
  HAVING SUM(profit) < 0
) t;

-- 12) Show top 5 worst loss-making products (most negative total profit)
-- Goal: Identify items to reprice, reduce discounts, renegotiate supplier costs, or discontinue
SELECT product_name,
	SUM(sales) as Total_sale,
	SUM(profit) AS Profit
    FROM records
    GROUP BY product_name
    HAVING Profit < 0
    ORDER BY Profit 
    Limit 5
    ;

-- ============================================================
-- ANALYSIS SECTION 3: Category performance + Avg profit per order
-- ============================================================

-- 13) Category-level summary:
--     - Total sales (sum of order_sales)
--     - Total profit (sum of order_profit)
--     - Average profit per order (NOT per row)
--
-- Why subquery?
--   Orders can have multiple rows (multiple products).
--   We first compute profit per order (within category),
--   then average those order-level profits to get a true "avg profit per order".
    
SELECT category,
	SUM(order_sales) AS Total_sales,
    SUM(order_profit) AS Total_profit,
    AVG(order_profit) AS Average_profit_per_order
    FROM (
		SELECT category,
        SUM(sales) AS order_sales,
        order_id,
        SUM(profit) AS order_profit
        FROM records
        GROUP BY order_id,category
    ) t
    GROUP BY category;

-- ============================================================
-- CUSTOMER PROFITABILITY ANALYSIS
-- ============================================================

-- 14) Identify the Top 10 most profitable customers.
-- Purpose:
--   • Find customers who contribute the most to overall profit.
--   • Understand where the business should focus retention efforts.

SELECT customer_name,
	SUM(sales) as total_sales,
	SUM(profit) as total_profit
FROM records
GROUP BY customer_name
ORDER BY total_profit DESC
LIMIT 10;

-- 15) Identify the Bottom 10 customers by total profit.
-- Purpose:
--   • Detect customers who consistently generate losses.
--   • Evaluate whether heavy discounting or return behavior is eroding margins.
SELECT customer_name,
	SUM(sales) as total_sales,
	SUM(profit) as total_profit
FROM records
GROUP BY customer_name
ORDER BY total_profit 
LIMIT 10;

-- ============================================================
-- CUSTOMER SEGMENT PERFORMANCE
-- ============================================================

-- 16) Analyze sales and profit by customer segment.
-- Purpose:
--   • Compare profitability across Consumer, Corporate, and Home Office segments.
SELECT segment,
	SUM(sales) as total_sales,
    SUM(profit) as total_profit
FROM records
GROUP BY segment
ORDER BY total_profit DESC;

-- ============================================================
-- GEOGRAPHIC PERFORMANCE ANALYSIS
-- ============================================================

-- 17) Identify the Top 10 states by total profit.
-- Purpose:
--   • Locate high-performing geographic markets.
--   • Understand where the business generates the most value.
SELECT state,
	SUM(sales) as total_sale,
    SUM(profit) as total_profit
FROM records
GROUP BY state
ORDER BY total_profit DESC
LIMIT 10;

-- 18) Identify the Top 10 cities by total profit, including state context.
-- Purpose:
--   • Pinpoint profitable urban markets while avoiding city-name ambiguity.
SELECT city,
	state,
	SUM(sales) as total_sale,
    SUM(profit) as total_profit
FROM records
GROUP BY city,state
ORDER BY total_profit DESC
LIMIT 10;

    
