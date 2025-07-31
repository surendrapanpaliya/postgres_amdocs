-- SCHEMA: telecom

-- DROP SCHEMA IF EXISTS telecom ;

CREATE SCHEMA IF NOT EXISTS telecom
    AUTHORIZATION postgres;


--Create Sample Tables and Insert Data

DROP TABLE IF EXISTS telecom.customers3;

-- Customers table
CREATE TABLE telecom.customers3 (
  customer_id INT PRIMARY KEY,
  name TEXT,
  city TEXT
);

DROP TABLE IF EXISTS telecom.plans3;

SELECT * FROM telecom.customers3;

-- Plans table
CREATE TABLE telecom.plans3 (
  plan_id INT PRIMARY KEY,
  plan_name TEXT,
  monthly_fee NUMERIC
);


SELECT * FROM telecom.plans3;

DROP TABLE IF EXISTS telecom.subscriptions3;

-- Subscriptions table
CREATE TABLE telecom.subscriptions3 (
  subscription_id INT PRIMARY KEY,
  customer_id INT REFERENCES telecom.customers3(customer_id),
  plan_id INT REFERENCES telecom.plans3(plan_id),
  start_date DATE
);

select * from telecom.subscriptions3;


-- Insert data
INSERT INTO telecom.customers3 VALUES
(1, 'Raj', 'Pune'),
(2, 'Simran', 'Delhi'),
(3, 'Amit', 'Mumbai'),
(4, 'Surendra', 'Mumbai');

INSERT INTO telecom.customers3 VALUES (4, 'Surendra', 'Mumbai');


INSERT INTO telecom.plans3 VALUES
(101, 'Silver', 299),
(102, 'Gold', 499),
(103, 'Platinum', 699),
(104, 'PlatinumG', 799);


INSERT INTO telecom.subscriptions3 VALUES
(1001, 1, 101, '2024-01-01'),
(1002, 1, 102, '2024-02-11'),
(1003, 2, 103, '2024-03-15');


-- Note: Customer 3 has no subscription, and Plan 102 has no subscribers


--Step 1: INNER JOIN — Only Matching Records

SELECT c.customer_id, c.name, p.plan_name
FROM telecom.customers3 c
INNER JOIN telecom.subscriptions3 s ON c.customer_id = s.customer_id
INNER JOIN telecom.plans3 p ON s.plan_id = p.plan_id;




SELECT c.customer_id, c.name, p.plan_name
FROM telecom.customers c
INNER JOIN telecom.subscriptions s ON c.customer_id = s.customer_id
INNER JOIN telecom.plans p ON s.plan_id = p.plan_id;



-- Expected Result: Raj and Simran (who have subscriptions).
 
-- Step 2: LEFT JOIN — All Customers + Matched Plans

SELECT c.customer_id, c.name, p.plan_name
FROM telecom.customers3 c
LEFT JOIN telecom.subscriptions3 s ON c.customer_id = s.customer_id
LEFT JOIN telecom.plans3 p ON s.plan_id = p.plan_id;



SELECT c.customer_id, c.name, p.plan_name
FROM telecom.customers c
LEFT JOIN telecom.subscriptions s ON c.customer_id = s.customer_id
LEFT JOIN telecom.plans p ON s.plan_id = p.plan_id;


-- Expected Result: All 3 customers. Amit (customer 3) will show NULL for plan_name.
 
--Step 3: RIGHT JOIN — All Subscribed Plans + Matched Customers

SELECT p.plan_id, p.plan_name, c.name
FROM telecom.subscriptions3 s
RIGHT JOIN telecom.customers3 c ON s.customer_id = c.customer_id
RIGHT JOIN telecom.plans3 p ON s.plan_id = p.plan_id;


SELECT p.plan_id, p.plan_name, c.name
FROM telecom.subscriptions s
RIGHT JOIN telecom.customers c ON s.customer_id = c.customer_id
RIGHT JOIN telecom.plans p ON s.plan_id = p.plan_id;

-- Expected Result: All plans, even if no customers are subscribed (like Gold plan).
 
-- Step 4: FULL OUTER JOIN — All from Both Tables

SELECT c.customer_id, c.name, p.plan_name
FROM telecom.customers3 c
FULL JOIN telecom.subscriptions3 s ON c.customer_id = s.customer_id
FULL JOIN telecom.plans3 p ON s.plan_id = p.plan_id;


SELECT c.customer_id, c.name, p.plan_name
FROM telecom.customers c
FULL JOIN telecom.subscriptions s ON c.customer_id = s.customer_id
FULL JOIN telecom.plans p ON s.plan_id = p.plan_id;


--Expected Result: All customers + all plans, even unmatched ones.

--- Real Telecom Use Cases

--Use Case 1: Customer Billing Summary (Plan Fee + City)

SELECT c.name, c.city, p.plan_name, p.monthly_fee
FROM telecom.customers c
JOIN telecom.subscriptions s ON c.customer_id = s.customer_id
JOIN telecom.plans p ON s.plan_id = p.plan_id;



--Use Case 1: Customer Billing Summary (Plan + Fee + City)

SELECT c.name, c.city, p.plan_name, p.monthly_fee
FROM telecom.customers3 c
JOIN telecom.subscriptions3 s ON c.customer_id = s.customer_id
JOIN telecom.plans3 p ON s.plan_id = p.plan_id;


--Use Case: Display customer’s monthly billing.

 
--Use Case 2: Identify Churned Customers (No Subscription)

SELECT c.customer_id, c.name
FROM telecom.customers c
LEFT JOIN telecom.subscriptions s ON c.customer_id = s.customer_id
WHERE s.subscription_id IS NULL;


SELECT c.customer_id, c.name
FROM telecom.customers3 c
LEFT JOIN telecom.subscriptions3 s ON c.customer_id = s.customer_id
WHERE s.subscription_id IS NULL;


--Use Case: Find inactive customers (e.g., Amit).

--Use Case 3: Plans Not Subscribed by Anyone

SELECT p.plan_id, p.plan_name
FROM telecom.plans p
LEFT JOIN telecom.subscriptions s ON p.plan_id = s.plan_id
WHERE s.subscription_id IS NULL;

--Use Case 3: Plans Not Subscribed by Anyone

SELECT p.plan_id, p.plan_name
FROM telecom.plans3 p
LEFT JOIN telecom.subscriptions3 s ON p.plan_id = s.plan_id
WHERE s.subscription_id IS NULL;

--Use Case: Identify underperforming plans (e.g., PlatinumG).



--Use Case 4: Customer with Multiple Subscriptions (if allowed)

SELECT customer_id, COUNT(*) AS total_subscriptions
FROM telecom.subscriptions
GROUP BY customer_id
HAVING COUNT(*) > 1;

--Use Case 4: Customer with Multiple Subscriptions (if allowed)

SELECT customer_id, COUNT(*) AS total_subscriptions
FROM telecom.subscriptions3
GROUP BY customer_id
HAVING COUNT(*) > 1;

--Use Case: Flag customers with multiple plans (for policy or upgrade).

 
--Use Case 5: Add Usage Table & Analyze Top Data Users


CREATE TABLE telecom.usage (
  usage_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES telecom.customers3(customer_id),
  month TEXT,
  call_minutes INT,
  data_mb NUMERIC
);


-- Sample usage
INSERT INTO telecom.usage (customer_id, month, call_minutes, data_mb) VALUES
(1, '2024-01', 300, 2048),
(2, '2024-01', 120, 1024),
(1, '2024-02', 500, 5120);

INSERT INTO telecom.usage (customer_id, month, call_minutes, data_mb) VALUES
(3, '2024-01', 220, 2024);

SELECT * from telecom.usage; 

--Use Case 5: Add Usage Table & Analyze Top Data Users

SELECT * from telecom.customers3; 

-- Query

SELECT c.name, SUM(u.data_mb) AS total_data_used
FROM telecom.customers3 c
JOIN telecom.usage u ON c.customer_id = u.customer_id
GROUP BY c.name
ORDER BY total_data_used DESC;

--Use Case: Rank customers by data usage.


-- Subqueries  (Telecom Context)
 
-- Step 0: Sample Tables (If not already created)


CREATE TABLE telecom.customers4 (
  customer_id INT PRIMARY KEY,
  name TEXT,
  city TEXT
);


-- Insert data
INSERT INTO telecom.customers4 VALUES
(1, 'Raj', 'Pune'),
(2, 'Simran', 'Delhi'),
(3, 'Amit', 'Mumbai');

INSERT INTO telecom.customers4 VALUES
(4, 'Surendra', 'Mumbai');


CREATE TABLE telecom.plans4 (
  plan_id INT PRIMARY KEY,
  plan_name TEXT,
  monthly_fee NUMERIC
);

INSERT INTO telecom.plans4 VALUES
(101, 'Silver', 299),
(102, 'Gold', 499),
(103, 'Platinum', 699);

INSERT INTO telecom.plans4 VALUES (104, 'PlatinumG', 799);

DROP TABLE IF EXISTS telecom.subscriptions4 ;

CREATE TABLE telecom.subscriptions4 (
  subscription_id INT PRIMARY KEY,
  customer_id INT REFERENCES telecom.customers4(customer_id),
  plan_id INT REFERENCES telecom.plans4(plan_id),
  start_date DATE
);


INSERT INTO telecom.subscriptions4 VALUES
(1001, 1, 101, '2024-01-01'),
(1002, 2, 103, '2024-03-15');

INSERT INTO telecom.subscriptions4 VALUES
(1003, 3, 104, '2024-02-15');

DROP TABLE IF EXISTS telecom.usage4;

CREATE TABLE telecom.usage4 (
  usage_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES telecom.customers4(customer_id),
  month TEXT,  -- e.g., '2024-07',
  call_minutes INT,
  data_usage_mb NUMERIC
);

-- Sample usage
INSERT INTO telecom.usage4(usage_id, month, call_minutes, data_usage_mb) VALUES
(1, '2024-01', 300, 2048),
(2, '2024-01', 120, 1024),
(3, '2024-02', 500, 5120);

INSERT INTO telecom.usage4(usage_id, month, call_minutes, data_usage_mb) VALUES
(4, '2024-01', 400, 3048);


--Step 1: Subquery in WHERE clause

--Use Case: Get Customers on the Most Expensive Plan

SELECT name
FROM telecom.customers4
WHERE customer_id IN (
  SELECT customer_id
  FROM telecom.subscriptions4
  WHERE plan_id = (
    SELECT plan_id FROM telecom.plans4
    ORDER BY monthly_fee DESC LIMIT 1
  )
);


--Step 1: Subquery in WHERE clause

--Use Case: Get Customers on the Most Expensive Plan

SELECT name
FROM telecom.customers4
WHERE customer_id IN (
  SELECT customer_id
  FROM telecom.subscriptions4
  WHERE plan_id = (
    SELECT plan_id FROM telecom.plans4
    ORDER BY monthly_fee DESC LIMIT 1
  )
);



SELECT * from telecom.customers4; 


SELECT * from telecom.subscriptions4; 

SELECT * from telecom.plans4; 




--Why: Pinpoint VIP or high-paying customers.
 
--Step 2: Subquery in SELECT clause

-- Use Case: Show total usage per customer as a column

SELECT name,
       (SELECT SUM(call_minutes) FROM telecom.usage4 u WHERE u.usage_id = c.customer_id) AS total_call_minutes
FROM telecom.customers4 c;


SELECT name,
       (SELECT SUM(call_minutes) FROM telecom.usage u WHERE u.usage_id = c.customer_id) AS total_call_minutes
FROM telecom.customers c;


--Why: Embed calculated fields per row.
 
 -- Step 3: Subquery in FROM clause
 
-- Use Case: Show customers with above-average usage

SELECT name, total_minutes
FROM (
    SELECT c.name, SUM(u.call_minutes) AS total_minutes
    FROM telecom.customers4 c
    JOIN telecom.usage4 u ON c.customer_id = u.usage_id
    GROUP BY c.name
) AS usage_summary
WHERE total_minutes > (
    SELECT AVG(call_minutes) FROM telecom.usage4
);



SELECT name, total_minutes
FROM (
    SELECT c.name, SUM(u.call_minutes) AS total_minutes
    FROM telecom.customers c
    JOIN telecom.usage u ON c.customer_id = u.usage_id
    GROUP BY c.name
) AS usage_summary
WHERE total_minutes > (
    SELECT AVG(call_minutes) FROM telecom.usage
);




-- Why: Compare derived metrics using a temporary result.
 
-- Step 4: Correlated Subquery
-- Use Case: Show customers and their latest subscription plan

SELECT name,
       (SELECT p.plan_name
        FROM telecom.subscriptions4 s
        JOIN telecom.plans4 p ON s.plan_id = p.plan_id
        WHERE s.customer_id = c.customer_id
        ORDER BY s.start_date DESC
        LIMIT 1) AS latest_plan
FROM telecom.customers4 c;


-- Why: Fetch the latest child record for each parent.
 
 --Real Telecom Queries Using Subqueries
 
-- 1. Billing Summary per Customer (Plan + Total Monthly Usage)

SELECT c.name,
       p.plan_name,
       p.monthly_fee,
       (SELECT SUM(u.data_usage_mb) FROM telecom.usage4 u WHERE u.usage_id = c.customer_id AND u.month = '2024-01') AS total_data_used
FROM telecom.customers4 c
JOIN telecom.subscriptions4 s ON c.customer_id = s.customer_id
JOIN telecom.plans4 p ON s.plan_id = p.plan_id;


-- Purpose: Generate usage + fee for billing system.
 
 --2. Churn Report – Customers Without Any Subscription

SELECT name
FROM telecom.customers4
WHERE customer_id NOT IN (
  SELECT DISTINCT customer_id FROM telecom.subscriptions4
);


-- Purpose: Identify inactive or lost customers.
 
-- 3. Usage Spike Detection – Above Average Users

SELECT name
FROM telecom.customers4
WHERE customer_id IN (
  SELECT usage_id
  FROM telecom.usage4
  GROUP BY usage_id
  HAVING SUM(data_usage_mb) > (SELECT AVG(data_usage_mb) FROM telecom.usage4)
);


-- Purpose: Target for upgrades or upsell.
 
-- 4. Plan Popularity Ranking

SELECT plan_name
FROM telecom.plans4
WHERE plan_id IN (
  SELECT plan_id
  FROM telecom.subscriptions4
  GROUP BY plan_id
  HAVING COUNT(*) = (
    SELECT MAX(cnt)
    FROM (
      SELECT COUNT(*) AS cnt FROM telecom.subscriptions4 GROUP BY plan_id
    ) AS sub_counts
  )
);

-- Purpose: Identify most used plan.

--Step 1: Simple CTE Syntax

WITH active_customers AS (
  SELECT customer_id, name
  FROM telecom.customers4
  WHERE city = 'Pune'
)
SELECT * FROM active_customers;

--Why: CTE acts like a temporary view — helps modularize code.


--Step 2: CTE for Joining Filtered Data

WITH active_subs AS (
  SELECT * FROM telecom.subscriptions4 WHERE start_date = '2024-01-01'
)
SELECT c.name, p.plan_name
FROM active_subs s
JOIN telecom.customers4 c ON c.customer_id = s.customer_id
JOIN telecom.plans p ON p.plan_id = s.plan_id;


--Use Case: Display active subscriptions with customer and plan.

-- Step 3: CTE for Aggregation

WITH usage_summary AS (
  SELECT customer_id, SUM(call_minutes) AS total_calls, SUM(data_usage_mb) AS total_data
  FROM telecom.usage4
  WHERE month = '2024-01'
  GROUP BY customer_id
)
SELECT c.name, u.total_calls, u.total_data
FROM usage_summary u
JOIN telecom.customers4 c ON u.customer_id = c.customer_id;


--Use Case: Summarize monthly usage with customer details.


---Step 4: CTE with Filtering on Aggregated Results

WITH usage_summary AS (
  SELECT customer_id, SUM(data_usage_mb) AS total_data
  FROM telecom.usage4
  GROUP BY customer_id
)
SELECT c.name, u.total_data
FROM usage_summary u
JOIN telecom.customers4 c ON c.customer_id = u.customer_id
WHERE u.total_data > 5000;

--Use Case: Identify heavy data users.


--Step 5: Recursive CTE (Advanced - Optional)

WITH RECURSIVE month_series AS (
  SELECT '2024-01'::TEXT AS month
  UNION ALL
  SELECT TO_CHAR(TO_DATE(month, 'YYYY-MM') + INTERVAL '1 month', 'YYYY-MM')
  FROM month_series
  WHERE month < '2024-06'
)
SELECT * FROM month_series;

--Use Case: Generate month ranges dynamically (e.g., billing cycles).



