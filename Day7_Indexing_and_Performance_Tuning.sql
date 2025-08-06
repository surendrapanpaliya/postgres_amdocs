--Day7_Indexing_and_Performance Tuning

/* What is Indexing?

Indexing in PostgreSQL is the process of creating data structures that speed up data retrieval by minimizing full table scans.
 
Why Use Indexing?
•	Improve query performance
•	Reduce CPU, I/O, and memory usage
•	Ensure scalability of telecom systems handling millions of rows
 
Indexing Strategies (with SQL and Telecom Use Cases) */
 
-- 1. Single-Column B-Tree Index

-- Use Case: Search by customer ID

-- Step 1: Create Table

CREATE TABLE telecom.customers (
    customer_id INT PRIMARY KEY,
    customer_name TEXT,
    mobile_number TEXT,
    status TEXT
);

select * from telecom.customers;

-- Step 2: Create Index

CREATE INDEX idx_customers_mobile_number ON telecom.customers(mobile_number);


-- Step 3: Use in Query

SELECT * FROM telecom.customers
WHERE mobile_number = '9876543210';


--Why: Frequently used in CRM, self-care portals, or support queries.
 
--2. Multi-Column B-Tree Index

--Use Case: Filter recharge logs by customer_id and recharge_date

-- Step 1: Create Table

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
);


-- Step 2: Create Composite Index

CREATE INDEX idx_recharges_cust_date ON telecom.recharges(customer_id, recharge_date);

-- Step 3: Use in Query

SELECT * FROM telecom.recharges
WHERE customer_id = 101 AND recharge_date >= '2025-07-01';


--Why: Boosts performance of multi-column WHERE clauses.
 
--3. Partial Index
--Use Case: Search only active users

-- Step 1: Create Partial Index

CREATE INDEX idx_active_customers ON telecom.customers(customer_id)
WHERE status = 'active';

--REINDEX TABLE idx_active_customers;

-- Step 2: Query

SELECT * FROM telecom.customers
WHERE status = 'active' AND customer_id = 101;

--Why: Reduces index size and lookup time by excluding inactive users.
 
--4. Expression Index
--Use Case: Case-insensitive mobile number lookup

-- Step 1: Create Expression Index

CREATE INDEX idx_lower_mobile ON telecom.customers(LOWER(mobile_number));

-- Step 2: Query using same expression

SELECT * FROM telecom.customers
WHERE LOWER(mobile_number) = '9876543210';

--Why: Avoids function-based sequential scan by indexing computed result.
 
--5. BRIN Index (Block Range Index)

--Use Case: Time-series usage data (massive billing or usage logs)

-- Step 1: Create Table

CREATE TABLE telecom.usage_logs (
    log_id SERIAL,
    customer_id INT,
    usage_date DATE,
    data_usage_gb NUMERIC
);

-- Step 2: Create BRIN Index

CREATE INDEX idx_usage_brin_date ON telecom.usage_logs USING BRIN (usage_date);


-- Step 3: Query

SELECT * FROM telecom.usage_logs
WHERE usage_date BETWEEN '2025-07-01' AND '2025-07-31';

--Why: Efficient for large, append-only tables with sorted columns.

 
--6. GIN Index on JSONB (Call Detail Records)
-- ( Generalised Inverted Index )

--Use Case: Fast search inside JSON column

-- Step 1: Create Table

CREATE TABLE telecom.call_logs (
    log_id SERIAL,
    customer_id INT,
    call_data JSONB
);

-- Step 2: Create GIN ( Generalised Inverted Index )

CREATE INDEX idx_call_data_gin ON telecom.call_logs USING GIN (call_data);

-- Step 3: Query

SELECT * FROM telecom.call_logs
WHERE call_data @> '{"call_type": "international"}';

--Why: GIN index accelerates containment queries on JSONB fields.
 
--7. Covering Index (Index-Only Scan)
--Use Case: Querying only indexed columns

-- Step 1: Create Index

CREATE INDEX idx_recharge_covering ON telecom.recharges(customer_id, recharge_amount);

-- Step 2: Query

SELECT customer_id, recharge_amount
FROM telecom.recharges
WHERE customer_id = 101;

--Why: PostgreSQL can serve the query entirely from the index, skipping the table.
 
--How to Check Index Usage

-- Explain query plan

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE customer_id = 101 AND recharge_date >= '2025-07-01';


--If the index is used correctly, you will see Index Scan instead of Seq Scan.
 
'''2. WHY Use Execution Plans?
To diagnose and optimize slow queries, especially in large telecom datasets.
Benefits:
•	Understand if indexes are used
•	Identify bottlenecks (e.g., sequential scans, nested loops)
•	Reduce resource consumption and improve performance
 '''
--3. TELECOM DOMAIN Use Case: Recharge Lookup Optimization
 
--PostgreSQL Example

DROP TABLE telecom.recharges CASCADE;

--Step 1: Create Recharge Table

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
);


--Step 2: Insert Sample Data

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
SELECT generate_series(1, 100000),
       CURRENT_DATE - (random() * 365)::int,
       (random() * 500)::int;


--Step 3: Create Index (optional)

CREATE INDEX idx_recharge_customer_date ON telecom.recharges(customer_id, recharge_date);


--Step 4: Analyze Query with and without Index

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE customer_id = 5000 AND recharge_date >= CURRENT_DATE - INTERVAL '90 days';


'''
This returns:
•	Total execution time
•	Rows returned
•	Whether index scan or seq scan was used
•	Cost estimates
 '''

--6. Advanced (PostgreSQL Only): Buffers and Timing

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM telecom.recharges
WHERE customer_id = 5000;

'''
Returns:
•	I/O buffers used
•	Planning vs execution time
•	Index vs seq scan
'''

--VACUUM	Reclaims storage from dead tuples (deleted/updated rows)

--ANALYZE	Updates statistics for query planner to make better decisions

--Statistics Metadata about table data (row count, distinct values, value distribution)
 

''' WHY Are They Important?

•	PostgreSQL uses MVCC (Multi-Version Concurrency Control): 

updates don’t overwrite rows — they mark old ones as dead.

•	Without VACUUM, disk bloat and performance degradation occur.

•	Without ANALYZE, the query planner might choose bad plans 
(e.g., sequential scan instead of index scan).

 
3. TYPES of VACUUM

VACUUM	Cleans dead tuples (but doesn’t update stats)

ANALYZE	Updates planner statistics only

VACUUM ANALYZE	Cleans dead tuples and updates stats

VACUUM FULL	Rewrites table to shrink disk usage (exclusive lock)
 

4. TELECOM DOMAIN USE CASES
 
Use Case 1: Recharge Table Cleanup (VACUUM)

Frequent recharges can create a large number of dead rows due to updates.

'''


--Step 1: Simulate Table

DROP TABLE telecom.recharges CASCADE; 

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
);


--Step 2: Insert Sample Data

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
SELECT 1000 + i, CURRENT_DATE, 199
FROM generate_series(1, 100000) AS i;

SELECT * from telecom.recharges WHERE recharge_amount < 200;

--Step 3: Update and Delete Rows

UPDATE telecom.recharges SET recharge_amount = 249 WHERE recharge_amount = 199;

SELECT * from telecom.recharges WHERE recharge_amount = 249 AND customer_id % 10 = 0 


DELETE FROM telecom.recharges WHERE recharge_amount = 249 AND customer_id % 3 = 0;


SELECT * from telecom.recharges WHERE recharge_amount = 249 

--Step 4: Reclaim Space

VACUUM telecom.recharges;

EXPLAIN ANALYSE
SELECT * from telecom.recharges WHERE recharge_amount = 249;

 --Use Case 2: Improve Planner Accuracy for Usage Queries (ANALYZE)


--Usage analytics queries benefit from up-to-date statistics.

ANALYZE telecom.usage;

--Now, planner knows the number of rows, distinct values, and helps 
--it choose the right index or scan method.
 

--Use Case 3: Combined VACUUM and ANALYZE

-- For daily maintenance:

VACUUM ANALYZE telecom.recharges;
 

/* Use Case 4: Full Space Reclamation (VACUUM FULL)

When a table has had massive deletes or updates and isn’t shrinking on disk. */


VACUUM FULL telecom.recharges;

-- Caution: This locks the table exclusively.

 
--5. HOW TO MONITOR

--View Table Statistics

SELECT relname, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
WHERE schemaname = 'telecom';


--View Last Autovacuum/Analyze Time

SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'telecom';

 
--6. CONFIGURING AUTOVACUUM (Optional)

--PostgreSQL automatically runs autovacuum if enabled in postgresql.conf.

--You can also tune per-table thresholds: 


ALTER TABLE telecom.recharges SET (
    autovacuum_vacuum_threshold = 1000,
    autovacuum_analyze_threshold = 500
);

 

VACUUM	Regular cleanup (minimal locking)	Reclaims dead tuples

ANALYZE	After large inserts/updates	Updates planner stats

VACUUM ANALYZE	Routine table maintenance	Reclaims + updates stats

VACUUM FULL	After mass deletions	Shrinks table size on disk
 

--Example: Full Workflow

-- Create Table

CREATE TABLE sales (
    id serial PRIMARY KEY,
    customer_name text,
    purchase_amount numeric,
    purchase_date date
);



-- Insert sample data

INSERT INTO sales (customer_name, purchase_amount, purchase_date)
SELECT 'Customer ' || i, random()*1000, current_date - (i % 100)
FROM generate_series(1, 100000) AS s(i);


-- Create Index
CREATE INDEX idx_sales_customer_name ON sales(customer_name);


-- Run Query
EXPLAIN ANALYZE
SELECT * FROM sales WHERE customer_name = 'Customer 500';

-- Clean Up and Update Statistics
VACUUM ANALYZE sales;
 

--Identify and tune slow queries using EXPLAIN ANALYZE

 
--Step-by-Step: Identify & Tune Slow Queries using EXPLAIN ANALYZE
 
--Use Case: Recharge Lookup by Customer and Date
 
--Step 1: Create Sample Table

DROP TABLE IF EXISTS telecom.recharges;


CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
);
 
--Step 2: Insert Test Data (Simulating 1 Million Rows)


INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
SELECT (random() * 10000)::int,
       CURRENT_DATE - (random() * 365)::int,
       (random() * 500)::int
FROM generate_series(1, 1000000);

 
--Step 3: Run the Query Without Index

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE customer_id = 1234
AND recharge_date >= CURRENT_DATE - INTERVAL '90 days';


--Expected Output (partial):

--Seq Scan on telecom.recharges  (cost=0.00..18250.00 rows=100 width=...)  

--Filter: (customer_id = 1234 AND recharge_date >= CURRENT_DATE - '90 days')

-- Problem: Sequential scan on a large table → Slow performance
 
--Step 4: Create a Composite Index

CREATE INDEX idx_recharge_cust_date ON telecom.recharges(customer_id, recharge_date);

 
--Step 5: Re-Run the Same Query

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE customer_id = 1234
AND recharge_date >= CURRENT_DATE - INTERVAL '90 days';

'''
Expected Output (partial):

Index Scan using idx_recharge_cust_date on telecom.recharges

Index Cond: (customer_id = 1234 AND recharge_date >= CURRENT_DATE - '90 days')
'''
 
-- Use Case: Top N Data Users by Circle and Month
 
--Step 1: Create Table

DROP TABLE IF EXISTS telecom.usage;

CREATE TABLE telecom.usage (
    usage_id SERIAL PRIMARY KEY,
    customer_id INT,
    circle TEXT,
    usage_date DATE,
    data_usage_gb NUMERIC
);
 
--Step 2: Insert Data

INSERT INTO telecom.usage (customer_id, circle, usage_date, data_usage_gb)
SELECT (random()*10000)::int,
       CASE WHEN random() < 0.5 THEN 'Delhi' ELSE 'Mumbai' END,
       CURRENT_DATE - (random() * 365)::int,
       (random() * 10)::numeric
FROM generate_series(1, 500000);


 
--Step 3: Run a Slow Query

EXPLAIN ANALYZE
SELECT customer_id, SUM(data_usage_gb) AS total
FROM telecom.usage
WHERE circle = 'Delhi'
AND usage_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY customer_id
ORDER BY total DESC
LIMIT 5;


-- Likely to show Seq Scan + GroupAggregate if no index exists.
 
--Step 4: Add Multi-Column Index for Filtering


CREATE INDEX idx_usage_circle_date ON telecom.usage(circle, usage_date);

 
--Step 5: Rerun Query with Index Help

EXPLAIN ANALYZE
SELECT customer_id, SUM(data_usage_gb) AS total
FROM telecom.usage
WHERE circle = 'Delhi'
AND usage_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY customer_id
ORDER BY total DESC
LIMIT 5;



--Query planner now uses Index Scan on circle + usage_date

--Improves filtering → reduces number of grouped rows
 
--Bonus: Enable Buffers and Timing Info


EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM telecom.recharges
WHERE customer_id = 1234;
 

--Summary: Tuning Workflow in SQL Format


-- Identify slow query
EXPLAIN ANALYZE SELECT ...;

-- Create supporting index
CREATE INDEX ...;

-- Re-run with EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT ...;

-- Optional: Vacuum and Analyze
VACUUM ANALYZE telecom.recharges;
 
'''
Tune the Query

Case 1: Full Table Scan Detected
•	Problem: PostgreSQL is scanning the whole table.
•	Reason: No index on customer_id.
 
Solution: Create Index
'''

CREATE INDEX idx_customer_id ON orders(customer_id);
 
--Re-run the Query

EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 12345;

'''
Expected Output:
Index Scan using idx_customer_id on orders
(cost=0.28..8.30 rows=1 width=100)
(actual time=0.020..0.030 rows=1 loops=1)
'''

'''
Assignment:
•	Create 2 indexes and show performance improvement

 Demonstrate performance improvement by creating 2 indexes in PostgreSQL, using a telecom recharge use case. 

•	Create a large table
•	Run slow queries without indexes
•	Add indexes
•	Re-run the queries and compare performance using EXPLAIN ANALYZE
 
🚀 Use Case: Recharge Lookup & Reporting in Telecom
 
Step 1: Create Table
'''

DROP TABLE IF EXISTS telecom.recharges;

CREATE TABLE telecom.recharges (
    recharge_id SERIAL PRIMARY KEY,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC,
    circle TEXT
);
 
--Step 2: Insert 1 Million Rows

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount, circle)
SELECT
    (random() * 10000)::int,
    CURRENT_DATE - (random() * 365)::int,
    (random() * 500)::int,
    CASE
        WHEN random() < 0.5 THEN 'Delhi'
        ELSE 'Mumbai'
    END
FROM generate_series(1, 1000000);
 


--Step 3: Run First Query (No Index)

--Query: Lookup by customer_id and date range

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE customer_id = 1234 AND recharge_date >= CURRENT_DATE - INTERVAL '90 days';


'''
Output will show:

Seq Scan on telecom.recharges ...

Execution time is likely high. '''
 
--Step 4: Create First Index (customer_id + recharge_date)


CREATE INDEX idx_recharges_cust_date
ON telecom.recharges (customer_id, recharge_date);
 
 --Step 5: Re-Run First Query


EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE customer_id = 1234 AND recharge_date >= CURRENT_DATE - INTERVAL '90 days';

'''
 Output will now show:
Index Scan using idx_recharges_cust_date ...
Execution time significantly reduced.
'''
 
-- Step 6: Run Second Query (No Index)

--Query: Get recharge summary by circle

EXPLAIN ANALYZE
SELECT circle, COUNT(*) AS total_recharges, SUM(recharge_amount) AS total_amount
FROM telecom.recharges
GROUP BY circle;


--This will trigger a full table scan.
 
--Step 7: Create Second Index (on circle)

CREATE INDEX idx_recharges_circle ON telecom.recharges (circle);
 
Step 8: Re-Run Second Query

EXPLAIN ANALYZE
SELECT circle, COUNT(*) AS total_recharges, SUM(recharge_amount) AS total_amount
FROM telecom.recharges
GROUP BY circle;


Query planner now optimizes grouping using idx_recharges_circle.
 

Cleanup (Optional)

DROP INDEX IF EXISTS idx_recharges_cust_date;
DROP INDEX IF EXISTS idx_recharges_circle;
 
Would you like a shell script or PL/pgSQL function to benchmark execution time automatically before/after index creation?


Assignment: Create 2 Indexes and Show Performance Improvement
Scenario:

We will simulate a before-and-after performance comparison by:
1.	Running a query without indexes (slow query)
2.	Creating 2 indexes
3.	Running the same query again and comparing results using EXPLAIN ANALYZE
 
--Step 1️– Create a Sample Table


CREATE TABLE transactions (
    id serial PRIMARY KEY,
    customer_id int,
    transaction_date date,
    amount numeric
);
 
--Step 2️ – Insert Sample Data


INSERT INTO transactions (customer_id, transaction_date, amount)
SELECT (random() * 10000)::int, 
       current_date - (random() * 1000)::int,
       (random() * 1000)::numeric
FROM generate_series(1, 1000000);  -- 1 million rows
 
--Step 3️ – Run Query Without Index

EXPLAIN ANALYZE
SELECT * FROM transactions 
WHERE customer_id = 1234 
AND transaction_date BETWEEN '2023-01-01' AND '2023-12-31';

'''
Expected Output:
Seq Scan on transactions
(cost=0.00..15000.00 rows=500 width=50)
(actual time=0.100..200.000 rows=500 loops=1)


Observation:
•	Full Table Scan (Seq Scan)
•	High execution time (e.g., 200 ms)
'''
 
--Step 4️– Create 2 Indexes

-- Index 1: On customer_id
CREATE INDEX idx_customer_id ON transactions(customer_id);

-- Index 2: Composite index on customer_id and transaction_date
CREATE INDEX idx_customer_date ON transactions(customer_id, transaction_date);
 
Step 5️ – Run Query Again

EXPLAIN ANALYZE
SELECT * FROM transactions 
WHERE customer_id = 1234 
AND transaction_date BETWEEN '2023-01-01' AND '2023-12-31';



--Use Case: Optimizing Call Detail Record (CDR) Search by MSISDN & Date Range
 
--1. Create the CDR Table

DROP TABLE IF EXISTS cdr;

CREATE TABLE telecom.cdr (
    call_id BIGSERIAL PRIMARY KEY,
    msisdn VARCHAR(15),
    call_date TIMESTAMP,
    call_duration INT
);

'''
Explanation:
•	call_id: Unique identifier for each call.
•	msisdn: Mobile number (Telecom standard).
•	call_date: Date & time of the call.
•	call_duration: Duration in seconds.

'''
 
--2. Insert Sample Data (1 Million Rows for Testing)

INSERT INTO telecom.cdr (msisdn, call_date, call_duration)
SELECT
    '91' || LPAD((RANDOM() * 999999999)::INT::TEXT, 10, '0') AS msisdn,
    NOW() - (RANDOM() * INTERVAL '365 days') AS call_date,
    (RANDOM() * 500)::INT AS call_duration
FROM generate_series(1, 1000000);


'''
Explanation:
•	Generates 1 million fake call records.
•	msisdn: Random 12-digit Indian mobile numbers.
•	call_date: Random dates within the last 1 year.
•	call_duration: Random duration between 0 and 500 seconds.

'''

--3. Run Query Without Index 

EXPLAIN ANALYZE
SELECT * FROM telecom.cdr
WHERE msisdn = '919876543210'
  AND call_date BETWEEN '2024-06-01' AND '2024-06-30';

'''  
Expected Result:
•	Execution Plan: Will show a Seq Scan (Sequential Scan).
•	Performance: Likely slow because PostgreSQL will scan all 1M rows.
•	Reason: No index exists, so PostgreSQL must check every row.
'''
 
--4. Create a B-Tree Index

CREATE INDEX idx_cdr_msisdn_date ON telecom.cdr (msisdn, call_date);

'''
Why this order?
•	Filtering starts with msisdn (exact match).
•	Then narrows down using call_date (range condition).
•	B-Tree is ideal for equality + range queries.
'''
 
--5. Run the Query Again With Index

EXPLAIN ANALYZE
SELECT * FROM telecom.cdr
WHERE msisdn = '919876543210'
  AND call_date BETWEEN '2024-06-01' AND '2024-06-30';

  
'''Expected Result:
•	Execution Plan: Will now show an Index Scan.
•	Performance: Should be significantly faster than sequential scan.
•	PostgreSQL uses the B-Tree index to quickly locate relevant rows.
'''
 
--6. Compare Index Sizes
-- List indexes for the table

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'cdr';


-- Show index size
SELECT
	indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_all_indexes
WHERE relname = 'cdr';


'''
Explanation:
•	pg_indexes: Lists all indexes on the cdr table.
•	pg_size_pretty(): Converts size to human-readable format (MB, GB).
''



