-- Database: amdocs_training

-- DROP DATABASE IF EXISTS amdocs_training;

CREATE DATABASE amdocs_training
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

'''What Are Window Functions?
Window functions perform row-wise calculations across a set of rows 
related to the current row, known as the “window.” 

Window functions allow you to:
•	Compute rankings, totals, or row numbers
•	Over a subset (partition) of data
•	While still keeping the original rows

'''

CREATE TABLE telecom.sales2 (
    sale_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(50),
    sale_amount NUMERIC(10,2),
    city VARCHAR(50)
);



INSERT INTO telecom.sales2 (customer_name, sale_amount, city) VALUES
('Dev', 500, 'Pune'),
('Dev', 300, 'Pune'),
('Harish', 400, 'Mumbai'),
('Harish', 200, 'Mumbai'),
('Satish', 700, 'Delhi'),
('Satish', 600, 'Delhi'),
('Satish', 700, 'Delhi'),
('Satish', 600, 'Delhi');

select * from telecom.sales2; 


--RANK Functions


--a) ROW_NUMBER()
-- Gives a unique row number within a partition.
-- Assigns a unique number to each row within the partition (no gaps)

SELECT customer_name, sale_amount, city,
ROW_NUMBER() OVER (ORDER BY sale_amount DESC) AS rn
FROM sales2;


SELECT customer_name, sale_amount, city,
ROW_NUMBER() OVER (PARTITION BY city ORDER BY sale_amount DESC) AS rn
FROM sales2;



-- b) RANK()

--Gives rank with gaps (similar to Oracle RANK()). 
--Assigns rank with gaps in case of ties

SELECT customer_name, sale_amount, city,
       RANK() OVER ( ORDER BY sale_amount DESC) AS rnk
FROM sales2;


SELECT customer_name, sale_amount, city,
       RANK() OVER (PARTITION BY city ORDER BY sale_amount DESC) AS rnk
FROM sales2;


--c) DENSE_RANK()
--Gives rank without gaps (like Oracle DENSE_RANK()).
--Assigns rank without gaps, even if there are ties

SELECT customer_name, sale_amount, city,
       DENSE_RANK() OVER ( ORDER BY sale_amount DESC) AS drnk
FROM sales2;


SELECT customer_name, sale_amount, city,
       DENSE_RANK() OVER (PARTITION BY city ORDER BY sale_amount DESC) AS drnk
FROM sales2;


CREATE TABLE sales1 (
    sale_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(50),
    sale_amount NUMERIC(10,2),
    city VARCHAR(50)
);

INSERT INTO sales1 (customer_name, sale_amount, city) VALUES
('Dev', 500, 'Pune');


SELECT 
    customer_name, 
    sale_amount, 
	city,
    RANK() OVER (PARTITION BY city ORDER BY sale_amount DESC) AS rank,
    DENSE_RANK() OVER (PARTITION BY city ORDER BY sale_amount DESC) AS dense_rank,
    ROW_NUMBER() OVER (PARTITION BY city ORDER BY sale_amount DESC) AS row_num
FROM sales2;



--Use Case 1: Top 3 Data Users Per Circle

SELECT * from telecom.usage;

--telecom.usage1

CREATE TABLE telecom.usage1 (
    customer_id INT,
    circle TEXT,
    data_usage_gb INT,
    month DATE
);


--Sample Data

INSERT INTO telecom.usage1 (customer_id, circle, data_usage_gb, month)
VALUES
(101, 'Delhi', 50, '2025-07-01'),
(102, 'Delhi', 60, '2025-07-01'),
(103, 'Delhi', 60, '2025-07-01'),
(104, 'Mumbai', 45, '2025-07-01'),
(105, 'Mumbai', 45, '2025-07-01'),
(106, 'Mumbai', 30, '2025-07-01');



--a. ROW_NUMBER() – Assigns a unique row number

--Use Case: Find the top user per circle with a unique rank.

SELECT
    customer_id,
    circle,
    data_usage_gb,
    ROW_NUMBER() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS row_num
FROM telecom.usage1;



--b. RANK() – Same rank for ties, but leaves gaps

--Use Case: List top 3 data users per circle, allowing ties and skipping ranks.

SELECT * FROM (
    SELECT
        customer_id,
        circle,
        data_usage_gb,
        RANK() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS rnk
    FROM telecom.usage1
) sub
WHERE rnk <= 3;


--c. DENSE_RANK() – Same rank for ties, no gaps

--Use Case: Assign billing tiers based on usage without skipping levels.

SELECT
    customer_id,
    circle,
    data_usage_gb,
    DENSE_RANK() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS tier
FROM telecom.usage1;




SELECT
    customer_id,
    circle,
    data_usage_gb,
    ROW_NUMBER() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS row_num,
	RANK() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS rnk,
	DENSE_RANK() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS densrank
FROM telecom.usage1;

--Telecom Use Cases
--Use Case 1: Top 3 Data Users Per Circle
--Objective: Identify the top 3 users by data usage in each telecom circle (Delhi, Mumbai, etc.)
--Best Function: RANK() or ROW_NUMBER()

SELECT *
FROM (
  SELECT *,
         RANK() OVER (PARTITION BY circle ORDER BY data_usage_gb DESC) AS usage_rank
  FROM telecom.usage1
) ranked
WHERE usage_rank <= 3;


-- Why RANK(): It accounts for ties — 2 users with same usage can both be rank 1.


--Use Case 2: Detect First Recharge of a Customer

--Objective: Identify the first recharge date and amount for each customer.

--Best Function: Use ROW_NUMBER() to assign a unique order to recharge events 
-- per customer and filter the first one only.


--Step 1: Create the telecom.recharges Table

DROP TABLE IF EXISTS telecom.recharges;

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount INT
);

 
--Step 2: Insert Sample Records

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount) VALUES
(101, '2025-01-10', 199),
(101, '2025-02-10', 249),
(101, '2025-03-10', 149),
(102, '2025-01-05', 299),
(102, '2025-02-15', 399),
(103, '2025-03-01', 199),
(103, '2025-03-05', 199),
(104, '2025-01-01', 99); -- only one recharge

select * from telecom.recharges;
 
--Step 3: Query – Get First Recharge per Customer

SELECT *
FROM (
    SELECT
        recharge_id,
        customer_id,
        recharge_date,
        recharge_amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY recharge_date ASC) AS rn
    FROM telecom.recharges
) sub
WHERE rn = 1
ORDER BY customer_id;


SELECT *
FROM (
    SELECT
        recharge_id,
        customer_id,
        recharge_date,
        recharge_amount,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY recharge_date ) AS rn
    FROM telecom.recharges
) sub
WHERE rn = 1
ORDER BY customer_id;

'''Explanation:
•	PARTITION BY customer_id ensures the ranking resets for each customer.
•	ORDER BY recharge_date ASC ensures the oldest recharge comes first.
•	ROW_NUMBER() gives a unique number to each recharge event per customer.
•	WHERE rn = 1 filters only the first recharge record. '''



--Why ROW_NUMBER(): You want only one recharge record per customer — no ties matter here.
 
/* Use Case 3: Assign Customer Loyalty Tiers
 Objective:
Rank customers by total billing amount and assign them loyalty tiers:
•	Tier 1 = highest billing
•	Tier 2 = next level
•	Ties should share the same tier (no skipping)

Best Function:
DENSE_RANK() — it assigns the same rank to ties without skipping the next rank.
 
Step 1: Create the telecom.customer_summary Table */

DROP TABLE IF EXISTS telecom.customer_summary;


CREATE TABLE telecom.customer_summary (
    customer_id INT PRIMARY KEY,
    customer_name TEXT,
    total_billing_amount NUMERIC
);

 
--Step 2: Insert Sample Records

INSERT INTO telecom.customer_summary (customer_id, customer_name, total_billing_amount) VALUES
(201, 'Dev',   10500),
(202, 'Satish',     9800),
(203, 'Charlie', 10500),
(204, 'David',   8700),
(205, 'Eve',     9800),
(206, 'Frank',   7500),
(207, 'Grace',   6000);

 
--Step 3: Query – Assign Loyalty Tiers

SELECT 
    customer_id,
    customer_name,
    total_billing_amount,
    DENSE_RANK() OVER (ORDER BY total_billing_amount DESC) AS loyalty_tier
FROM telecom.customer_summary
ORDER BY loyalty_tier, customer_id;

 
'''Explanation:
•	ORDER BY total_billing_amount DESC: higher billing gets higher rank (lower tier number).
•	DENSE_RANK(): assigns same rank to customers with same billing.
•	No ranks are skipped between tiers. '''



''' Use Case 4: Subscription History Ordering
Objective:
Track each customer’s subscription/plan changes in the order they occurred.
Best Function:
Use ROW_NUMBER() to assign a sequential number to each plan change for every customer.
'''

--Step 1: Create Table – telecom.subscription_changes


DROP TABLE IF EXISTS telecom.subscription_changes;

CREATE TABLE telecom.subscription_changes (
    change_id SERIAL PRIMARY KEY,
    customer_id INT,
    change_date DATE,
    old_plan TEXT,
    new_plan TEXT
);

 
--Step 2: Insert Sample Records

INSERT INTO telecom.subscription_changes (customer_id, change_date, old_plan, new_plan) VALUES
(301, '2025-01-01', NULL,     'Basic'),
(301, '2025-03-01', 'Basic',  'Standard'),
(301, '2025-06-01', 'Standard', 'Premium'),
(302, '2025-02-15', NULL,     'Standard'),
(302, '2025-04-10', 'Standard', 'Basic'),
(303, '2025-01-20', NULL,     'Basic'),
(303, '2025-02-20', 'Basic',  'Standard');
 
--Step 3: Query – Track Plan Change History in Order

SELECT
    customer_id,
    change_date,
    old_plan,
    new_plan,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY change_date) AS change_seq
FROM telecom.subscription_changes
ORDER BY customer_id, change_seq;
 
'''
Explanation:
•	PARTITION BY customer_id: groups records per customer.
•	ORDER BY change_date: sorts changes in chronological order.
•	ROW_NUMBER() gives a unique sequence number per customer’s change history.

'''

'''Use Case 5: Find and Remove Duplicate Recharges

Objective:
Identify and optionally remove duplicate recharge transactions for each customer.

Best Function:
Use ROW_NUMBER() to assign a unique sequence number to each recharge group. Keep the first (rn = 1) and remove the rest (rn > 1).
'''
 
--Step 1: Create Table – telecom.recharges

DROP TABLE IF EXISTS telecom.recharges;

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount INT
);

 
--Step 2: Insert Sample Records (with duplicates)

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount) VALUES
(401, '2025-01-10', 199),
(401, '2025-01-10', 199),  -- duplicate
(401, '2025-02-15', 249),
(402, '2025-03-01', 299),
(402, '2025-03-01', 299),  -- duplicate
(402, '2025-03-01', 299),  -- duplicate
(403, '2025-04-01', 399);  -- unique


SELECT * from telecom.recharges; 

 
--Step 3: Query – Identify Duplicate Recharges


SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id, recharge_amount, recharge_date
               ORDER BY recharge_id
           ) AS rn
    FROM telecom.recharges
) sub
WHERE rn > 1;



'''
Explanation:
•	PARTITION BY customer_id, recharge_amount, recharge_date groups recharges that are exact duplicates.
•	ORDER BY recharge_id picks the first occurrence by ID.
•	rn > 1 selects only the duplicate records (not the first).

'''


--Step 4 (Optional): Delete Duplicate Recharges

DELETE FROM telecom.recharges
WHERE recharge_id IN (
    SELECT recharge_id
    FROM (
        SELECT recharge_id,
               ROW_NUMBER() OVER (
                   PARTITION BY customer_id, recharge_amount, recharge_date
                   ORDER BY recharge_id
               ) AS rn
        FROM telecom.recharges
    ) duplicates
    WHERE rn > 1
);


-- Note: Always run the SELECT version before executing the DELETE.


SELECT * from telecom.recharges;


''' Use Case 6: Churn Leaderboard Per Circle
Objective:
Identify and rank customers by inactivity (least recent last_login) within each telecom circle to assess churn risk.

Best Function:
Use RANK() — it allows ties when multiple customers have the same last_login date, and skips ranks accordingly.
'''
 
--Step 1: Create Table – telecom.customers

SELECT * from telecom.customers; 

DROP TABLE IF EXISTS telecom.customers CASCADE;

CREATE TABLE telecom.customers (
    customer_id INT PRIMARY KEY,
    customer_name TEXT,
    circle TEXT,
    last_login DATE
);
 
--Step 2: Insert Sample Records

INSERT INTO telecom.customers (customer_id, customer_name, circle, last_login) VALUES
(501, 'Dev',   'Delhi',  '2025-05-01'),
(502, 'Satish',     'Delhi',  '2025-06-15'),
(503, 'Charlie', 'Delhi',  '2025-05-01'),
(504, 'David',   'Mumbai', '2025-04-20'),
(505, 'Eve',     'Mumbai', '2025-06-01'),
(506, 'Frank',   'Mumbai', '2025-04-20'),
(507, 'Grace',   'Kolkata','2025-03-10'),
(508, 'Helen',   'Kolkata','2025-06-10');


SELECT * from telecom.customers; 
 
--Step 3: Query – Rank Inactive Customers Per Circle

SELECT
    customer_id,
    customer_name,
    circle,
    last_login,
    RANK() OVER (PARTITION BY circle ORDER BY last_login ASC) AS inactivity_rank
FROM telecom.customers
ORDER BY circle, inactivity_rank;
 
'''Explanation:
•	PARTITION BY circle ensures ranks are calculated per telecom circle.
•	ORDER BY last_login ASC ranks the oldest login dates first (most inactive users).
•	RANK() handles ties — if multiple users share the same last_login, they get the same rank, and the next rank is skipped.

Use Cases of Output:
•	Target Rank 1 users for re-engagement campaigns.
•	Use inactivity trends to trigger automatic churn prediction flags.
•	Analyze retention effectiveness over time.

'''

--Window functions: LAG, LEAD, FIRST_VALUE, and SUM() OVER.

SELECT * from telecom.recharges;

--Lab Exercise: Telecom Window Functions


DROP TABLE IF EXISTS telecom.recharges;

CREATE TABLE telecom.recharges (
    customer_id INT,
    recharge_date DATE,
    recharge_amount INT,
    data_usage_gb INT
);



INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount, data_usage_gb)
VALUES 
    (201, '2025-01-10', 199, 5),
    (201, '2025-02-10', 249, 7),
    (201, '2025-03-10', 149, 4),
    (202, '2025-01-15', 299, 10),
    (202, '2025-02-15', 299, 8),
    (203, '2025-01-20', 399, 12),
    (203, '2025-02-20', 399, 14),
    (203, '2025-03-20', 499, 15);
 
-- Exercise 1: Use LAG() to Compare Previous Recharge

select * from telecom.recharges;

SELECT 
    customer_id,
    recharge_date,
    recharge_amount,
    LAG(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS prev_recharge
FROM telecom.recha


-- Exercise 2: Use LEAD() to Preview Next Recharge


--1. LAG() – Compare Current & Previous Recharge Amounts
--What it does: Gets the previous row’s value in the same partition.
-- Use Case: Check if customer recharged less than last time (churn or downgrade risk).

SELECT customer_id, recharge_date, recharge_amount,
       LAG(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS prev_recharge
FROM telecom.recharges;


 -- Helps detect downward spending trends or potential churn.


 '''2. LEAD() – Forecast Upcoming Recharge/Usage
What it does: Gets the next row’s value in the window.
Use Case: Show current + next recharge to forecast trends.
'''

SELECT customer_id, recharge_date, recharge_amount,
       LEAD(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS next_recharge
FROM telecom.recharges;


--Why: Enables predictive analytics for marketing or alerting if customer skips recharges.


--Exercise 3: Use FIRST_VALUE() to Get First Recharge Per Customer
/*3. FIRST_VALUE() – Get First Plan or Recharge
What it does: Returns the first value from the window.
Use Case: Show customer’s initial recharge plan or original plan they started with.

Why: Useful for customer lifecycle analysis or plan migration history.
*/

SELECT 
    customer_id,
    recharge_date,
    recharge_amount,
    FIRST_VALUE(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS first_recharge
FROM telecom.recharges;


--Exercise 4: Use SUM() OVER() to Calculate Cumulative Data Usage

/* 4. SUM() OVER() – Cumulative Usage or Billing
What it does: Computes a running or window total.
Use Case: Calculate total data usage or billing per customer over time.
*/

SELECT 
    customer_id,
    recharge_date,
    data_usage_gb,
    SUM(data_usage_gb) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS cumulative_usage
FROM telecom.recharges;


--Combine all the window functions in a single query:

SELECT 
    customer_id,
    recharge_date,
    recharge_amount,
    data_usage_gb,
    LAG(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS prev_recharge,
    LEAD(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS next_recharge,
    FIRST_VALUE(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS first_recharge,
    SUM(data_usage_gb) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS cumulative_usage
FROM telecom.recharges;


-- Returns a moving average or group average without collapsing rows.

SELECT 
    customer_id,
    recharge_date,
    data_usage_gb,
    AVG(data_usage_gb) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS avg_usage
FROM telecom.recharges;


-- Counts the number of rows in the partition.
SELECT 
    customer_id,
    recharge_date,
    data_usage_gb,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS count_rows
FROM telecom.recharges;


-- Breaks ordered data into n buckets (quantiles/quartiles).

SELECT 
    customer_id,
    recharge_date,
    data_usage_gb,
    NTILE(2) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS cust_group
FROM telecom.recharges;

--Breaks sales into 2 groups (top/bottom).


-- LAG, LEAD, FIRST_VALUE, and SUM() OVER() real-world Telecom domain use cases 
'''
LAG(column)	-> Returns the previous row’s value

LEAD(column) -> Returns the next row’s value

FIRST_VALUE() -> 	Returns the first row’s value in the window
SUM() OVER() -> Computes a running or partitioned total (cumulative or grouped total)

WHY Use These Functions in Telecom?

Telecom data is time-sequential — usage, recharges, subscriptions, complaints — making these functions powerful for:
•	Tracking customer behavior over time
•	Detecting churn risks or spending patterns
•	Comparing current vs. previous usage
•	Calculating running totals

'''

--1. LAG() – Compare Current & Previous Recharge Amounts
-- What it does: Gets the previous row’s value in the same partition.

-- Use Case: Check if customer recharged less than last time (churn or downgrade risk).


SELECT customer_id, recharge_date, recharge_amount,
       LAG(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS prev_recharge
FROM telecom.recharges;


 --Why: Helps detect downward spending trends or potential churn.
 
 
''' 
2. LEAD() – Forecast Upcoming Recharge/Usage

What it does: Gets the next row’s value in the window.

Use Case: Show current + next recharge to forecast trends.
'''

SELECT customer_id, recharge_date, recharge_amount,
       LEAD(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS next_recharge
FROM telecom.recharges;



-- Why: Enables predictive analytics for marketing or alerting if customer skips recharges.
 
'''
3. FIRST_VALUE() – Get First Plan or Recharge
What it does: Returns the first value from the window.
Use Case: Show customer’s initial recharge plan or original plan they started with.
'''

SELECT customer_id, recharge_date, recharge_amount,
       FIRST_VALUE(recharge_amount) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS first_recharge
FROM telecom.recharges;

-- Why: Useful for customer lifecycle analysis or plan migration history.

'''
4. SUM() OVER() – Cumulative Usage or Billing
What it does: Computes a running or window total.
Use Case: Calculate total data usage or billing per customer over time.
'''

SELECT customer_id, recharge_date, data_usage_gb FROM telecom.recharges;

SELECT customer_id, recharge_date, data_usage_gb,
       SUM(data_usage_gb) OVER (PARTITION BY customer_id ORDER BY recharge_date) AS cumulative_usage
FROM telecom.recharges;

'''
Why: Helps with:
•	Monthly reports
•	Fair usage tracking
•	Detecting heavy users
'''
