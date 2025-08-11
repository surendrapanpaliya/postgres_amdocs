'''Day_8_Partitioning_and_Full-TextSearch_Lab

What is Partitioning?

Partitioning is the technique of splitting a large table into smaller, more manageable child tables (partitions) based on certain criteria (e.g., date, region, ID range). 

Queries automatically target only the relevant partition(s).

Range   Partitions by a range (e.g., dates, IDs)
List    Partitions by list of values (e.g., regions)
Hash    Partitions by hash values (used for even spreading)
 
Why Partitioning Matters?
•   Improves query performance on large datasets
•   Speeds up bulk inserts, deletes, and archiving
•   Enables parallel query execution
•   Reduces index size per partition
•   Minimizes table bloat and vacuum overhead
 
  Telecom Use Cases for Partitioning

Daily recharge logs -- Range (by date)
Usage by telecom circle (Delhi, Mumbai) -- List (by circle)
Customer ID sharding  --  Hash

  1.  Creates a partitioned table telecom.recharges
  2.  Creates monthly partitions for July and August 2025
  3.  Inserts sample data (50 records per partition)
  4.  Verifies data insertion
  5.  Analyzes partition usage
  6.  Checks query performance with EXPLAIN ANALYZE
 
PostgreSQL Example: Monthly Partitioned Recharge Table

'''

-- Step 1: Create partitioned table
DROP TABLE IF EXISTS telecom.recharges CASCADE;


CREATE TABLE telecom.recharges (
    recharge_id SERIAL,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
) PARTITION BY RANGE (recharge_date);



-- Step 2: Create monthly partitions

CREATE TABLE telecom.recharges_2025_07 PARTITION OF telecom.recharges
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');



CREATE TABLE telecom.recharges_2025_08 PARTITION OF telecom.recharges
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


-- Step 3: Insert sample data for July (50 rows)

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
SELECT
  FLOOR(RANDOM() * 1000)::INT,
  DATE '2025-07-01' + (RANDOM() * 30)::INT,
  ROUND(50 + RANDOM() * 500)::NUMERIC
FROM generate_series(1, 50);

-- Step 4: Insert sample data for August (50 rows)
INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
SELECT
  FLOOR(RANDOM() * 1000)::INT,
  DATE '2025-08-01' + (RANDOM() * 30)::INT,
  ROUND(50 + RANDOM() * 500)
FROM generate_series(1, 50);

-- Step 5: Check inserted rows by partition

SELECT 'recharges_2025_07' AS partition_name, COUNT(*) 
FROM telecom.recharges_2025_07
UNION ALL
SELECT 'recharges_2025_08', COUNT(*) 
FROM telecom.recharges_2025_08;



-- Step 6: Verify partition routing using tableoid

SELECT 
  tableoid::regclass AS actual_partition,
  *
FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31'
ORDER BY recharge_id
LIMIT 5;



SELECT 
  tableoid::regclass AS actual_partition,
  *
FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-08-01' AND '2025-08-31'
ORDER BY recharge_id
LIMIT 5;


'''Line	Part	Explanation
tableoid::regclass AS actual_partition	

tableoid is a special system column in PostgreSQL that tells 
you which physical table (partition) a row actually resides in. 
::regclass casts the internal OID into a readable table name. 

 So this will output the actual partition table name, like recharges_2025_07
 
* Returns all columns from the telecom.recharges parent table.	
FROM telecom.recharges	You’re querying from the partitioned master table, 
which routes to child partitions (e.g., per month).	
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31'	
Filter only July 2025 records. 
If partitioning is done by recharge_date, this filter helps PostgreSQL
pick the correct partition (partition pruning).	
ORDER BY recharge_id	Sort results by ID.	
LIMIT 5	Show only the first 5 rows.	

Why Use tableoid?
	•	Purpose: To verify that PostgreSQL routed each row to the correct partition.
	•	When you insert rows into a partitioned table (like telecom.recharges), PostgreSQL automatically decides which partition (child table) the row goes into based on partition rules (like recharge_date).
	•	tableoid lets you audit or debug that routing.

This confirms that all those July records landed in the recharges_2025_07 partition

Summary
	•	tableoid shows the actual child table used during insert.
	•	Useful for debugging partition routing.
	•	Casting to regclass makes it human-readable.
	•	Adding this check is a best practice when working with list/range partitioned tables.

'''

-- Step 7: Performance Check using EXPLAIN ANALYZE (July data)

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31';



-- Step 8: Performance Check using EXPLAIN ANALYZE (August data)
EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-08-01' AND '2025-08-31';


-- Step 9: Optional – Total count
SELECT COUNT(*) FROM telecom.recharges;


'''Notes:
    •   PostgreSQL automatically routes inserts to the correct partition using the recharge_date.
    •   EXPLAIN ANALYZE will show partition pruning, making queries faster.
    •   tableoid::regclass helps validate which partition each row resides in.

Here is the extended SQL script to:
    1.  Add B-Tree indexing on recharge_date
    2.  Run test queries with partitioning
    3.  Run same test without partitioning (for benchmarking)
    4.  Compare performance with EXPLAIN ANALYZE

'''

--Part 1: WITH PARTITIONING

-- Add index on each partition's recharge_date

CREATE INDEX idx_recharges_2025_07_date ON telecom.recharges_2025_07 (recharge_date);

CREATE INDEX idx_recharges_2025_08_date ON telecom.recharges_2025_08 (recharge_date);

-- Query with partitioning - SELECT July data

EXPLAIN ANALYZE
SELECT * FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31';


-- Query with partitioning - Aggregate on August
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(recharge_amount) FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-08-01' AND '2025-08-31';


--Part 2: WITHOUT PARTITIONING

-- Create a non-partitioned version of the table
DROP TABLE IF EXISTS telecom.recharges_flat;

CREATE TABLE telecom.recharges_flat (
    recharge_id SERIAL,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
);

-- Insert same 100 records for fair comparison
INSERT INTO telecom.recharges_flat (customer_id, recharge_date, recharge_amount)
SELECT customer_id, recharge_date, recharge_amount FROM telecom.recharges;


-- Create single B-Tree index
CREATE INDEX idx_recharges_flat_date ON telecom.recharges_flat (recharge_date);

-- Query without partitioning - SELECT July data
EXPLAIN ANALYZE
SELECT * FROM telecom.recharges_flat
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31';

-- Query without partitioning - Aggregate on August
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(recharge_amount) FROM telecom.recharges_flat
WHERE recharge_date BETWEEN '2025-08-01' AND '2025-08-31';


--Optional: Compare Index Sizes

-- Index size on partitioned tables

SELECT relname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_index
JOIN pg_class ON pg_class.oid = pg_index.indexrelid
WHERE indrelid = 'telecom.recharges_2025_07'::regclass
   OR indrelid = 'telecom.recharges_2025_08'::regclass;

   
-- Index size on non-partitioned table
SELECT relname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_index
JOIN pg_class ON pg_class.oid = pg_index.indexrelid
WHERE indrelid = 'telecom.recharges_flat'::regclass;


--Step 3: Insert and Query

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
VALUES (101, '2025-07-15', 199);


SELECT * FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31';



-- List Partitioning


-- Step 1: Create master table using LIST partitioning

CREATE TABLE telecom.calls (
    call_id SERIAL,
    customer_id INT,
    circle TEXT,
    call_duration INT
) PARTITION BY LIST (circle);



-- Step 2: Create list partitions based on telecom circles

CREATE TABLE telecom.calls_mumbai
PARTITION OF telecom.calls
FOR VALUES IN ('Mumbai');


CREATE TABLE telecom.calls_delhi
PARTITION OF telecom.calls
FOR VALUES IN ('Delhi');


CREATE TABLE telecom.calls_chennai
PARTITION OF telecom.calls
FOR VALUES IN ('Chennai');


CREATE TABLE telecom.calls_bangalore
PARTITION OF telecom.calls
FOR VALUES IN ('Bangalore');


-- Step 3: Insert bulk sample data (simulating with repeated insert values)

INSERT INTO telecom.calls (customer_id, circle, call_duration) VALUES
(2001, 'Mumbai', 250), (2002, 'Delhi', 180), (2003, 'Chennai', 120), (2004, 'Bangalore', 90),
(2005, 'Mumbai', 210), (2006, 'Delhi', 300), (2007, 'Chennai', 60), (2008, 'Bangalore', 110),
(2009, 'Mumbai', 275), (2010, 'Delhi', 240), (2011, 'Chennai', 150), (2012, 'Bangalore', 95),
(2013, 'Mumbai', 200), (2014, 'Delhi', 170), (2015, 'Chennai', 80), (2016, 'Bangalore', 105),
(2017, 'Mumbai', 260), (2018, 'Delhi', 190), (2019, 'Chennai', 140), (2020, 'Bangalore', 115);



-- Step 4: Create index on each partition

CREATE INDEX idx_calls_mumbai_duration ON telecom.calls_mumbai(call_duration);
CREATE INDEX idx_calls_delhi_duration ON telecom.calls_delhi(call_duration);
CREATE INDEX idx_calls_chennai_duration ON telecom.calls_chennai(call_duration);
CREATE INDEX idx_calls_bangalore_duration ON telecom.calls_bangalore(call_duration);

-- Step 5: Performance Benchmarking with EXPLAIN ANALYZE

-- Query before indexing
EXPLAIN ANALYZE
SELECT * FROM telecom.calls
WHERE circle = 'Mumbai' AND call_duration > 200;


-- Step 6: Check partition index sizes

SELECT 
    c2.relname AS index_name,
    c1.relname AS table_name,
    pg_size_pretty(pg_relation_size(c2.oid)) AS index_size
FROM 
    pg_index i
JOIN 
    pg_class c1 ON c1.oid = i.indrelid  -- table
JOIN 
    pg_class c2 ON c2.oid = i.indexrelid  -- index
WHERE 
    c1.relname LIKE 'calls_%'
ORDER BY 
    pg_relation_size(c2.oid) DESC;


-- Step 7: Check table size per partition
SELECT
    relname AS partition,
    pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_catalog.pg_statio_user_tables
WHERE relname LIKE 'calls_%';




'''
PART 2: FULL-TEXT SEARCH (FTS)
 
 What is Full-Text Search?

Full-Text Search allows you to perform complex text queries 
(searching, ranking, stemming, etc.) 
inside PostgreSQL using natural language terms.
Unlike LIKE '%term%', it uses inverted indexes, lexical analysis, 
and ranking algorithms.
 

  Why FTS Matters?
•   Enables searchable support tickets, call logs, SMS content, and feedback text
•   Highly efficient and fast when used with GIN indexes
•   Built-in to PostgreSQL (no need for external search engines like Elasticsearch in many cases)
 
📈 Telecom Use Cases for Full-Text Search

Use Case    Benefit
Search SMS logs or complaints   Customer care analytics
Match call descriptions Fraud detection or keyword tracking
Filter JSON logs (CDRs) Query specific event tags or call reasons
Analyze survey feedback Sentiment or keyword-based filtering
 
PostgreSQL Example: Search Customer Complaints
'''

--Step 1: Create Complaints Table

CREATE TABLE telecom.complaints (
    complaint_id SERIAL PRIMARY KEY,
    customer_id INT,
    complaint_text TEXT,
    created_at TIMESTAMP
);

--Step 2: Insert Sample Data

INSERT INTO telecom.complaints (customer_id, complaint_text, created_at) VALUES
(101, 'Network coverage is very poor in my area', NOW()),
(102, 'Frequent call drops and slow internet', NOW()),
(103, 'Recharge failed but money deducted', NOW());

SELECT * FROM telecom.complaints; 


--Step 3: Add a tsvector
--Column (optional for performance)

ALTER TABLE telecom.complaints
ADD COLUMN search_vector tsvector;


UPDATE telecom.complaints
SET search_vector = to_tsvector('english', complaint_text);


'''This query updates the search_vector column in the telecom.complaints 
table by converting the text in the complaint_text column into a 
tsvector for full-text search in PostgreSQL. '''

--Step 4: Create GIN Index

CREATE INDEX idx_complaints_search ON telecom.complaints USING GIN (search_vector);

--Step 5: Query Using FTS

SELECT *
FROM telecom.complaints
WHERE to_tsvector('english', complaint_text) @@ to_tsquery('recharge & failed');


--Result: Matches phrases that contain both words (AND logic)


--Step 4: Create GIN Index

CREATE INDEX idx_complaints_search 
ON telecom.complaints 
USING GIN (search_vector);


'''
Creates a GIN (Generalized Inverted Index) on the search_vector column.
Optimizes full-text search performance, especially for large datasets.
GIN indexes are highly efficient for @@ queries (i.e., full-text search operations).

Why GIN?
	•	Designed for indexing composite values like tsvector.
	•	Supports fast lookup of lexemes (search terms) in full-text search.

Step 5: Query Using FTS

SELECT *
FROM telecom.complaints
WHERE to_tsvector('english', complaint_text) @@ to_tsquery('recharge & failed');

Clause	Meaning
to_tsvector('english', complaint_text)	
Converts the complaint_text into a normalized searchable format 
(tokens, stemming, stopwords removed)

to_tsquery('recharge & failed')	Creates a search query for both terms 
"recharge" AND "failed"
@@ operator	Checks if the tsvector contains all lexemes in the tsquery
WHERE ...	Filters rows where the complaint text includes both 
"recharge" and "failed" (after stemming/normalization)

Important Note:

In this query, you’re not using the GIN index you just created on search_vector.
That’s because you’re not using the search_vector column in the WHERE clause — you’re re-generating the tsvector on the fly.

How to Use the GIN Index Effectively

To benefit from the index, you should write the query like this:

SELECT *
FROM telecom.complaints
WHERE search_vector @@ to_tsquery('recharge & failed');

This will trigger PostgreSQL to use the GIN index on search_vector, resulting in faster searches.

'''

--To keep search_vector up-to-date, add a trigger:

CREATE TRIGGER trg_update_vector
BEFORE INSERT OR UPDATE ON telecom.complaints
FOR EACH ROW
EXECUTE FUNCTION
tsvector_update_trigger('search_vector', 'pg_catalog.english', 'complaint_text');


 
FTS Operators
Operator    Description Example
@@  Text matches query  tsvector @@ tsquery
to_tsquery()    Converts query string   'network & poor'
plainto_tsquery()   Tokenizes plain text    'slow internet'
ts_rank()   Ranks results by relevance  ORDER BY ts_rank(...)
 
GIN Index (FTS) Fast search in text/JSON    Complaint keywords, fraud detection
 
RANGE PARTITIONING
Partitioning rows based on a range of values in a column — e.g., by date, amount, or ID ranges.

Why Range Partitioning Matters?
•   Efficient querying when filtering by ranges (e.g., date range)
•   Reduces table scan time
•   Speeds up bulk deletes, archival, and index maintenance

--Step 1: Create Master Table

CREATE TABLE telecom.recharges (
    recharge_id SERIAL,
    customer_id INT,
    recharge_date DATE,
    recharge_amount NUMERIC
) PARTITION BY RANGE (recharge_date);


--Step 2: Create Monthly Partitions


CREATE TABLE telecom.recharges_2025_07
PARTITION OF telecom.recharges
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');


CREATE TABLE telecom.recharges_2025_08
PARTITION OF telecom.recharges
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');


--Step 3: Insert and Query

INSERT INTO telecom.recharges (customer_id, recharge_date, recharge_amount)
VALUES (1001, '2025-07-10', 199);

SELECT * FROM telecom.recharges
WHERE recharge_date BETWEEN '2025-07-01' AND '2025-07-31';


--LIST PARTITIONING
Partitioning rows based on a list of values, such as city, region, or network type.

Why List Partitioning Matters?
•   Efficient when your data naturally belongs to a small set of distinct categories
•   Speeds up filtering and reporting by category
•   Reduces index size per partition
 
📈 Telecom Use Cases for List Partitioning
Use Case    List Column
Call logs by telecom circle circle
SMS feedback grouped by region  region
Complaints by plan type plan_type
 
--List Partitioning
--Step 1: Create Master Table

CREATE TABLE telecom.calls (
    call_id SERIAL,
    customer_id INT,
    circle TEXT,
    call_duration INT
) PARTITION BY LIST (circle);


--Step 2: Create Region-Based Partitions

CREATE TABLE telecom.calls_mumbai
PARTITION OF telecom.calls
FOR VALUES IN ('Mumbai');

CREATE TABLE telecom.calls_delhi
PARTITION OF telecom.calls
FOR VALUES IN ('Delhi');

--Step 3: Insert and Query

INSERT INTO telecom.calls (customer_id, circle, call_duration)
VALUES (2001, 'Mumbai', 250);

SELECT * FROM telecom.calls
WHERE circle = 'Mumbai';


-- Step 1: Create master table using LIST partitioning
CREATE TABLE telecom.calls (
    call_id SERIAL,
    customer_id INT,
    circle TEXT,
    call_duration INT
) PARTITION BY LIST (circle);


-- Step 2: Create list partitions based on telecom circles
CREATE TABLE telecom.calls_mumbai
PARTITION OF telecom.calls
FOR VALUES IN ('Mumbai');

CREATE TABLE telecom.calls_delhi
PARTITION OF telecom.calls
FOR VALUES IN ('Delhi');

CREATE TABLE telecom.calls_chennai
PARTITION OF telecom.calls
FOR VALUES IN ('Chennai');

CREATE TABLE telecom.calls_bangalore
PARTITION OF telecom.calls
FOR VALUES IN ('Bangalore');

-- Step 3: Insert bulk sample data (simulating with repeated insert values)
INSERT INTO telecom.calls (customer_id, circle, call_duration) VALUES
(2001, 'Mumbai', 250), (2002, 'Delhi', 180), (2003, 'Chennai', 120), (2004, 'Bangalore', 90),
(2005, 'Mumbai', 210), (2006, 'Delhi', 300), (2007, 'Chennai', 60), (2008, 'Bangalore', 110),
(2009, 'Mumbai', 275), (2010, 'Delhi', 240), (2011, 'Chennai', 150), (2012, 'Bangalore', 95),
(2013, 'Mumbai', 200), (2014, 'Delhi', 170), (2015, 'Chennai', 80), (2016, 'Bangalore', 105),
(2017, 'Mumbai', 260), (2018, 'Delhi', 190), (2019, 'Chennai', 140), (2020, 'Bangalore', 115);

-- Step 4: Create index on each partition
CREATE INDEX idx_calls_mumbai_duration ON telecom.calls_mumbai(call_duration);
CREATE INDEX idx_calls_delhi_duration ON telecom.calls_delhi(call_duration);
CREATE INDEX idx_calls_chennai_duration ON telecom.calls_chennai(call_duration);
CREATE INDEX idx_calls_bangalore_duration ON telecom.calls_bangalore(call_duration);

-- Step 5: Performance Benchmarking with EXPLAIN ANALYZE
-- Query before indexing
EXPLAIN ANALYZE
SELECT * FROM telecom.calls
WHERE circle = 'Mumbai' AND call_duration > 200;

-- Step 6: Check partition index sizes
SELECT
    indexname,
    tablename,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_indexes
JOIN pg_class ON pg_indexes.indexname = pg_class.relname
WHERE tablename LIKE 'calls_%';

-- Step 7: Check table size per partition
SELECT
    relname AS partition,
    pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_catalog.pg_statio_user_tables
WHERE relname LIKE 'calls_%';
 
'''
tsvector:
•   A normalized and tokenized form of text used for indexing.
•   Stores words (lexemes) with positional info.
•   It’s what PostgreSQL searches over.

 tsquery:
•   A query structure for matching words against a tsvector.
•   Supports Boolean logic (AND, OR, NOT), prefix matching, and phrases.
 
  Why it matters?
•   Traditional search with LIKE '%text%' is slow and inaccurate.
•   Full-text search with tsvector + tsquery:
o   Is fast, especially with GIN indexes.
o   Supports natural language search.
o   Is built-in — no external tools like Elasticsearch needed.
 
'''
--Full-Text Search Example with SQL
 
--Step 1: Create Table

CREATE TABLE telecom.complaints (
    complaint_id SERIAL PRIMARY KEY,
    customer_id INT,
    complaint_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
 
--Step 2: Insert Sample Data

INSERT INTO telecom.complaints (customer_id, complaint_text) VALUES
(101, 'Network coverage is very poor in my area.'),
(102, 'Frequent call drops and very slow 4G internet.'),
(103, 'Recharge failed but the money got deducted.'),
(104, 'Excellent service and fast activation.'),
(105, 'Data usage is very high even on low usage.');

 
--Step 3: Simple FTS Using to_tsvector and to_tsquery

SELECT *
FROM telecom.complaints
WHERE to_tsvector('english', complaint_text) @@ to_tsquery('call & drops');


--This matches complaints containing both the words call AND drops.

--Step 4: Use plainto_tsquery() (Auto-handles stop words, stemming)

SELECT *
FROM telecom.complaints
WHERE to_tsvector('english', complaint_text) @@ plainto_tsquery('slow internet');

 
--Step 5: Add a Search Vector Column (optional but improves performance)

ALTER TABLE telecom.complaints
ADD COLUMN search_vector tsvector;

UPDATE telecom.complaints
SET search_vector = to_tsvector('english', complaint_text);
 
--Step 6: Create a GIN Index for Speed

CREATE INDEX idx_complaints_search_vector
ON telecom.complaints
USING GIN (search_vector);
 
--Step 7: Query Using Precomputed tsvector

SELECT *
FROM telecom.complaints
WHERE search_vector @@ plainto_tsquery('recharge failed');
 
--Bonus: Rank Results by Relevance

SELECT *, ts_rank(search_vector, plainto_tsquery('network issue')) AS rank
FROM telecom.complaints
WHERE search_vector @@ plainto_tsquery('network issue')
ORDER BY rank DESC;
 


tsvector    Document representation for indexing    to_tsvector('english', text)

tsquery Query structure for searching   to_tsquery('recharge & failed')


plainto_tsquery Converts plain text into tsquery    plainto_tsquery('slow internet')

@@  Match operator  tsvector @@ tsquery

ts_rank()   Computes relevance of a match   ts_rank(tsvector, tsquery)

GIN Index   Fastest index for FTS in PostgreSQL CREATE INDEX ... USING GIN (tsvector)



--Step 1: Create Schema & Table

DROP SCHEMA IF EXISTS telecom CASCADE;

CREATE SCHEMA telecom;

CREATE TABLE telecom.customer_complaints (
    complaint_id SERIAL PRIMARY KEY,
    customer_id INT,
    complaint_text TEXT,
    complaint_vector TSVECTOR
);


--Step 2: Insert 100,000 Rows of Sample Complaint Data (using generate_series)

INSERT INTO telecom.customer_complaints (customer_id, complaint_text)
SELECT
    1000 + s.i,
    CASE
        WHEN i % 5 = 0 THEN 'Recharge failed, amount deducted from bank'
        WHEN i % 5 = 1 THEN 'Frequent call drops and poor signal strength'
        WHEN i % 5 = 2 THEN 'Incorrect billing for international roaming'
        WHEN i % 5 = 3 THEN 'SMS sending issue and delayed delivery'
        ELSE 'Voicemail service activated without request, balance deducted'
    END
FROM generate_series(1, 100000) AS s(i);


--Step 3: Generate tsvector for All Rows

UPDATE telecom.customer_complaints
SET complaint_vector = to_tsvector('english', complaint_text);


--Step 4: Search Without Index (First Search Benchmark)

EXPLAIN ANALYZE
SELECT complaint_id, complaint_text
FROM telecom.customer_complaints
WHERE complaint_vector @@ to_tsquery('english', 'call & drop');



--Step 5: Create GIN Index on tsvector

CREATE INDEX idx_complaint_vector_gin
ON telecom.customer_complaints
USING GIN (complaint_vector);


--Step 6: Search With Index (Second Search Benchmark)

EXPLAIN ANALYZE
SELECT complaint_id, complaint_text
FROM telecom.customer_complaints
WHERE complaint_vector @@ to_tsquery('english', 'call & drop');



Step 7: Compare Index Size

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'customer_complaints';

SELECT
    pg_size_pretty(pg_relation_size('idx_complaint_vector_gin')) AS gin_index_size,
    pg_size_pretty(pg_relation_size('telecom.customer_complaints')) AS table_size;


--Step 8: Rank Top Matching Complaints by Relevance

SELECT complaint_id, customer_id, complaint_text,
       ts_rank(complaint_vector, to_tsquery('english', 'call & drop')) AS rank
FROM telecom.customer_complaints
WHERE complaint_vector @@ to_tsquery('english', 'call & drop')
ORDER BY rank DESC
LIMIT 10;

'''
This script will:
    •   Load 100,000 telecom complaint records
    •   Benchmark search performance with and without index
    •   Show real query timings via EXPLAIN ANALYZE
    •   Show index and table size
    •   Rank results using ts_rank

'''
''' 
FUNCTIONAL INDEXES
 
What is a Functional Index?

A functional index is built on the result of an expression or 
function applied to a column, rather than on the raw column value itself.

 Why Functional Indexes Matter?
•   Boosts performance for queries with expressions (e.g., LOWER(email), DATE(timestamp))
•   Avoids full scans when using computed WHERE conditions
•   Useful for non-trivial WHERE clauses
 
Telecom Use Cases for Functional Indexes

Use Case    Function Used
Search by lowercase complaint email/text    LOWER(complaint_text)
Billing grouped by day (not timestamp)  DATE(billing_time)
Region code extraction from phone number    SUBSTRING(phone, 1, 4)
 
SQL Example: Functional Index in PostgreSQL '''

--1. Create Table

CREATE TABLE telecom.tickets (
    ticket_id SERIAL PRIMARY KEY,
    customer_email TEXT,
    complaint_text TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);


--2. Insert Sample Data


INSERT INTO telecom.tickets (customer_email, complaint_text) VALUES
('USER1@GMAIL.COM', 'Network down in area'),
('user2@gmail.com', 'Slow internet speed'),
('User3@Gmail.com', 'Call drops every day');


3. Query with Function (Without Index)

SELECT * FROM telecom.tickets
WHERE LOWER(customer_email) = 'user1@gmail.com';


-- Without an index on LOWER(customer_email), this results in a sequential scan.
 
--4. Create Functional Index

CREATE INDEX idx_lower_email ON telecom.tickets (LOWER(customer_email));



--5. Query Now Uses Index

EXPLAIN ANALYZE
SELECT * FROM telecom.tickets
WHERE LOWER(customer_email) = 'user1@gmail.com';

 --Output will now show Index Scan using idx_lower_email.
 
