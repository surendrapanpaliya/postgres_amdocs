/* Views and Materialized Views_Lab

WHAT is a View?
View:
•   A virtual table based on a SQL SELECT query.
•   Does not store data physically — data is fetched live from base tables.
•   Acts like a saved query.

CREATE VIEW view_name AS
SELECT column1, column2
FROM base_table
WHERE condition;
 

2. WHAT is a Materialized View?

Materialized View:
•   A physical snapshot of the result of a SELECT query.
•   Stores data on disk and can be refreshed manually or periodically.
•   Faster for read-heavy operations, especially with large joins or aggregations.

CREATE MATERIALIZED VIEW mat_view_name AS
SELECT column1, column2
FROM base_table
WHERE condition
WITH DATA;

-- Refresh manually
REFRESH MATERIALIZED VIEW mat_view_name;


Create and use views for telecom domain use cases step by step in sql format.
Below is a step-by-step guide in pure SQL format to create and use views for multiple telecom domain use cases. Each example includes:
1.  Table creation
2.  Sample data insertion
3.  View creation
4.  Sample usage of the view
 
Use Case 1: View for Customer Billing Summary

Step 1: Create telecom.billing Table

*/

DROP TABLE IF EXISTS telecom.billing;

CREATE TABLE telecom.billing (
    billing_id SERIAL PRIMARY KEY,
    customer_id INT,
    billing_date DATE,
    bill_amount NUMERIC
);


--Step 2: Insert Sample Data

INSERT INTO telecom.billing (customer_id, billing_date, bill_amount) VALUES
(101, '2025-07-01', 300),
(101, '2025-07-15', 200),
(102, '2025-07-01', 150),
(102, '2025-07-20', 250),
(103, '2025-07-05', 180);


--Step 3: Create Billing Summary View


CREATE OR REPLACE VIEW telecom.customer_billing_summary AS
SELECT
    customer_id,
    DATE_TRUNC('month', billing_date) AS billing_month,
    SUM(bill_amount) AS total_monthly_bill
FROM telecom.billing
GROUP BY customer_id, DATE_TRUNC('month', billing_date);


--Step 4: Query the View

SELECT * FROM telecom.customer_billing_summary;

 
--Use Case 2: View for Customer Basic Info (Access Control)

--Step 1: Create telecom.customers Table

DROP TABLE IF EXISTS telecom.customers CASCADE;

CREATE TABLE telecom.customers (
    customer_id INT PRIMARY KEY,
    customer_name TEXT,
    mobile_number TEXT,
    circle TEXT,
    kyc_status TEXT
);


--Step 2: Insert Sample Data


INSERT INTO telecom.customers VALUES
(101, 'Dev', '9876543210', 'Delhi', 'Verified'),
(102, 'Satish', '8765432109', 'Mumbai', 'Verified'),
(103, 'Charlie', '7654321098', 'Delhi', 'Pending');


--Step 3: Create View Exposing Limited Info

CREATE OR REPLACE VIEW telecom.customer_basic_info AS
SELECT
    customer_id,
    customer_name,
    circle
FROM telecom.customers;


--Step 4: Query the View


SELECT * FROM telecom.customer_basic_info;

SELECT * from telecom.customers; 
 
--Use Case 3: View for Churn Watchlist (Inactivity Ranking)

-- Step 1: Add last_login Column

ALTER TABLE telecom.customers ADD COLUMN last_login DATE;


--Step 2: Update Sample Last Login Dates


UPDATE telecom.customers SET last_login = '2025-06-01' WHERE customer_id = 101;

UPDATE telecom.customers SET last_login = '2025-05-01' WHERE customer_id = 102;

UPDATE telecom.customers SET last_login = '2025-07-01' WHERE customer_id = 103;


SELECT * from telecom.customers; 

--Step 3: Create Churn View with Rank

CREATE OR REPLACE VIEW telecom.churn_watchlist AS
SELECT
    customer_id,
    customer_name,
    circle,
    last_login,
    RANK() OVER (PARTITION BY circle ORDER BY last_login ASC) AS inactivity_rank
FROM telecom.customers;


SELECT * FROM telecom.churn_watchlist;

--Step 4: Query Churn Watchlist

SELECT * FROM telecom.churn_watchlist WHERE inactivity_rank <= 2;
 
--Use Case 4: View for Recharge Summary by Circle

--Step 1: Create telecom.recharges Table


DROP TABLE IF EXISTS telecom.recharges;

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount INT,
    circle TEXT
);

--Step 2: Insert Sample Data

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount, circle) VALUES
(101, '2025-07-01', 199, 'Delhi'),
(102, '2025-07-02', 249, 'Delhi'),
(103, '2025-07-03', 149, 'Mumbai'),
(104, '2025-07-04', 299, 'Mumbai'),
(105, '2025-07-05', 199, 'Delhi');


--Step 3: Create View for Recharge Summary

CREATE OR REPLACE VIEW telecom.recharge_summary_by_circle AS
SELECT
    circle,
    COUNT(*) AS total_recharges,
    SUM(recharge_amount) AS total_revenue
FROM telecom.recharges
GROUP BY circle;


--Step 4: Query Recharge Summary

SELECT * FROM telecom.recharge_summary_by_circle;
 

'''Create and refresh materialized views for common Telecom domain Use Cases
Each use case includes:
•   Table creation
•   Sample data insertion
•   Materialized view creation
•   Refresh mechanism
'''
 
--Use Case 1: Materialized View – Daily Data Usage Summary

--Step 1: Create the telecom.usage Table

DROP TABLE IF EXISTS telecom.usage CASCADE;

CREATE TABLE telecom.usage (
    usage_id SERIAL PRIMARY KEY,
    customer_id INT,
    usage_date DATE,
    data_usage_gb NUMERIC
);


--Step 2: Insert Sample Data

INSERT INTO telecom.usage (customer_id, usage_date, data_usage_gb) VALUES
(101, '2025-07-01', 2.5),
(101, '2025-07-01', 1.0),
(101, '2025-07-02', 3.0),
(102, '2025-07-01', 5.0),
(103, '2025-07-02', 4.2);


--Step 3: Create the Materialized View

CREATE MATERIALIZED VIEW telecom.daily_usage_summary AS
SELECT
    customer_id,
    usage_date,
    SUM(data_usage_gb) AS total_daily_usage
FROM telecom.usage
GROUP BY customer_id, usage_date
WITH DATA;


--Step 4: Query the Materialized View

SELECT * FROM telecom.daily_usage_summary;


--Step 5: Refresh the Materialized View Manually (when base data changes)

REFRESH MATERIALIZED VIEW telecom.daily_usage_summary;
 
--Use Case 2: Materialized View – Monthly Recharge Summary by Circle

--Step 1: Create the telecom.recharges 


DROP TABLE IF EXISTS telecom.recharges;

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC,
    circle TEXT
);


--Step 2: Insert Sample Data

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount, circle) VALUES
(101, '2025-07-01', 199, 'Delhi'),
(102, '2025-07-02', 249, 'Delhi'),
(103, '2025-07-05', 149, 'Mumbai'),
(104, '2025-07-15', 299, 'Mumbai'),
(105, '2025-08-01', 199, 'Delhi');


--Step 3: Create the Materialized View

CREATE MATERIALIZED VIEW telecom.monthly_recharge_summary AS
SELECT
    circle,
    DATE_TRUNC('month', recharge_date) AS recharge_month,
    COUNT(*) AS total_recharges,
    SUM(recharge_amount) AS total_amount
FROM telecom.recharges
GROUP BY circle, DATE_TRUNC('month', recharge_date)
WITH DATA;


--Step 4: Query the Materialized View

SELECT * FROM telecom.monthly_recharge_summary;

--Step 5: Refresh Materialized View When Recharge Table Updates

REFRESH MATERIALIZED VIEW telecom.monthly_recharge_summary;

 
--Use Case 3: Materialized View – Inactive Customer Leaderboard (Last Login Snapshot)

--Step 1: Create telecom.customers Table

DROP TABLE IF EXISTS telecom.customers CASCADE;

CREATE TABLE telecom.customers (
    customer_id INT PRIMARY KEY,
    customer_name TEXT,
    circle TEXT,
    last_login DATE
);

--Step 2: Insert Sample Data

INSERT INTO telecom.customers VALUES
(201, 'Dev', 'Delhi', '2025-06-01'),
(202, 'Bob', 'Delhi', '2025-04-15'),
(203, 'Charlie', 'Mumbai', '2025-05-20'),
(204, 'David', 'Mumbai', '2025-03-01');


--Step 3: Create the Materialized View

CREATE MATERIALIZED VIEW telecom.inactive_customers_ranked AS
SELECT
    customer_id,
    customer_name,
    circle,
    last_login,
    RANK() OVER (PARTITION BY circle ORDER BY last_login ASC) AS inactivity_rank
FROM telecom.customers
WITH DATA;


--Step 4: Query Inactivity Ranking

SELECT * FROM telecom.inactive_customers_ranked WHERE inactivity_rank <= 2;

--Step 5: Refresh as Needed

REFRESH MATERIALIZED VIEW telecom.inactive_customers_ranked;

''' 
Optional: Auto Refresh Materialized Views
PostgreSQL does not support automatic refresh natively, but you can schedule refresh using:
•   pg_cron (PostgreSQL extension)
•   pgAgent (Job scheduler)
•   External CRON job with psql script
Example CRON command:

psql -U postgres -d telecom_db -c "REFRESH MATERIALIZED VIEW telecom.daily_usage_summary;"

'''

/* 2️ Create and Use Views
Scenario:

Summarize total order amount per customer using a view.
 
Step 1: Create Base Table
*/

CREATE TABLE telecom.customer_orders (
    order_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(50),
    order_date DATE,
    order_amount NUMERIC(10,2)
);

 --Step 2: Insert Sample Data

INSERT INTO telecom.customer_orders (customer_name, order_date, order_amount) VALUES
('John', '2024-07-01', 200),
('John', '2024-07-05', 300),
('Alice', '2024-07-02', 150),
('Alice', '2024-07-08', 250),
('Bob', '2024-07-03', 400);


select * from telecom.customer_orders;

 
--Step 3: Create View

CREATE OR REPLACE VIEW telecom.customer_total_orders AS
SELECT customer_name, SUM(order_amount) AS total_spent
FROM telecom.customer_orders
GROUP BY customer_name;


--Step 4: Query the View

SELECT * FROM telecom.customer_total_orders;
 

--3️. Create and Use Materialized Views
'''
What Is a Materialized View?
•   Stores precomputed results
•   Faster for large data sets
•   Needs manual refresh
'''
 
--Step 1: Create Materialized View

CREATE MATERIALIZED VIEW telecom.customer_total_orders_mv AS
SELECT customer_name, SUM(order_amount) AS total_spent
FROM telecom.customer_orders
GROUP BY customer_name;

 
--Step 2: Query the Materialized View

SELECT * FROM customer_total_orders_mv;
 
--Step 3: Insert New Data

INSERT INTO telecom.customer_orders (customer_name, order_date, order_amount) 
VALUES ('John', '2024-07-10', 500);
 
--Step 4: Check the View and MV

Query   Behavior

SELECT * FROM telecom.customer_total_orders;    Real-time updated
SELECT * FROM telecom.customer_total_orders_mv; Not updated yet
 
--Step 5: Refresh the Materialized View

REFRESH MATERIALIZED VIEW customer_total_orders_mv;

--Now customer_total_orders_mv will show updated data.
 

--Cleanup

DROP VIEW customer_total_orders;
DROP MATERIALIZED VIEW customer_total_orders_mv;
DROP TABLE customer_orders;

