-- SCHEMA: telecom

-- DROP SCHEMA IF EXISTS telecom ;

CREATE SCHEMA IF NOT EXISTS telecom
    AUTHORIZATION postgres;


--PostgreSQL PL/pgSQL
DO $$
BEGIN
    RAISE NOTICE 'Hello from PL/pgSQL';
END;
$$;


DO $$
BEGIN
	RAISE NOTICE 'Welcome to Procedure LANGUAGE';
END;
$$


--Variable Declaration

DO $$
DECLARE
    v_name VARCHAR(100);
BEGIN
    v_name := 'Surendra';
	RAISE NOTICE '%', v_name;
END;
$$;


DO $$
DECLARE
    v_msg VARCHAR(50);
BEGIN
    v_msg := 'Welcome to PL/pgSQL';
    RAISE NOTICE '%', v_msg;
END;
$$;


DO $$
DECLARE
  v_name TEXT;
  v_count INTEGER;
BEGIN
  v_name := 'Amdocs';
  v_count := 1;
  RAISE NOTICE 'Name: %, Count: %', v_name, v_count;
END;
$$;

-- IF ELSIF ELSE -- BLOCK -- 

DO $$
DECLARE
  v_count INTEGER := 10;
BEGIN
  IF v_count > 5 THEN
    RAISE NOTICE 'More than 5';
  ELSIF v_count = 5 THEN
    RAISE NOTICE 'Exactly 5';
  ELSE
    RAISE NOTICE 'Less than 5';
  END IF;
END;
$$;


DO $$
DECLARE
  v_status TEXT := 'A';
BEGIN
  CASE v_status
    WHEN 'A' THEN RAISE NOTICE 'Active';
    WHEN 'I' THEN RAISE NOTICE 'Inactive';
    ELSE RAISE NOTICE 'Unknown';
  END CASE;
END;
$$;



DO $$
DECLARE
  i INTEGER := 1;
BEGIN
  LOOP
    EXIT WHEN i > 5;
    RAISE NOTICE 'i = %', i;
    i := i + 1;
  END LOOP;
END;
$$;


DO $$
DECLARE
  i INTEGER := 1;
BEGIN
  WHILE i <= 5 LOOP
    RAISE NOTICE 'i = %', i;
    i := i + 1;
  END LOOP;
END;
$$;


DO $$
BEGIN
  FOR i IN 1..5 LOOP
    RAISE NOTICE 'i = %', i;
  END LOOP;
END;
$$;


DO $$
BEGIN
  -- risky operation
  PERFORM 1 / 0;
EXCEPTION
  WHEN division_by_zero THEN
    RAISE NOTICE 'Division by zero occurred!';
  WHEN OTHERS THEN
    RAISE NOTICE 'Some error: %', SQLERRM;
END;
$$;


--Create a customer table and use %TYPE to declare variables.

--Create Table

CREATE TABLE telecom.customer (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(50));

INSERT INTO telecom.customer(name,city) values ('Surendra','Pune'),
('Narendra','Pune'),('Satish','Florida');

SELECT * from telecom.customer;


DO $$
DECLARE
    v_city telecom.customer.city %TYPE;
BEGIN
    v_city := 'Pune';
    RAISE NOTICE 'City is %', v_city;
END;
$$;


DO $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM telecom.customer;

    IF cnt = 0 THEN
        RAISE NOTICE 'No Customers Found';
    ELSE
        RAISE NOTICE 'Total Customers: %', cnt;
    END IF;
END;
$$;



--Loop from 1 to 5 and print numbers:

DO $$
BEGIN
    FOR i IN 1..5 LOOP
        RAISE NOTICE 'Iteration: %', i;
    END LOOP;
END;
$$;


--Use CASE to print product type.

DO $$
DECLARE
    product_name TEXT := 'Mobile Plan';
BEGIN
    CASE product_name
        WHEN 'Mobile Plan' THEN RAISE NOTICE 'Category: Telecom';
        WHEN 'Broadband' THEN RAISE NOTICE 'Category: Internet';
        ELSE RAISE NOTICE 'Unknown Category';
    END CASE;
END;
$$;



--EXCEPTION Handling

Task

--Try to insert duplicate data and handle unique violation.

--Create Table

CREATE TABLE telecom.test_unique (
    id INT PRIMARY KEY,
    name TEXT
);


--Block with Exception

DO $$
BEGIN
    INSERT INTO telecom.test_unique VALUES (1, 'First');
    INSERT INTO telecom.test_unique VALUES (1, 'Duplicate');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Duplicate ID error handled.';
END;
$$;


-- Use of %ROWTYPE

-- Task Fetch a customer row using %ROWTYPE.

DO $$
DECLARE
    cust_rec telecom.customer%ROWTYPE;
BEGIN
    SELECT * INTO cust_rec FROM telecom.customer WHERE customer_id = 2;
    RAISE NOTICE 'Customer Name: %, City: %', cust_rec.name, cust_rec.city;
END;
$$;


DO $$
DECLARE
    cust_rec telecom.customer%ROWTYPE;
BEGIN
    SELECT * INTO cust_rec FROM telecom.customer WHERE customer_id = 5;
    RAISE NOTICE 'Customer Name: %, City: %', cust_rec.name, cust_rec.city;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'No customer found with ID 5';
END;
$$;



DO $$
DECLARE
    cust_rec telecom.customer%ROWTYPE;
BEGIN
    SELECT * INTO cust_rec FROM telecom.customer WHERE customer_id = 5;

    IF NOT FOUND THEN
        RAISE NOTICE 'Customer not found!';
    ELSE
        RAISE NOTICE 'Customer Name: %, City: %', cust_rec.name, cust_rec.city;
    END IF;
END;
$$;


DO $$
DECLARE
    cust_rec telecom.customer%ROWTYPE;
BEGIN
    SELECT * INTO cust_rec FROM telecom.customer WHERE customer_id = 5;
    RAISE NOTICE 'Customer Name: %, City: %', cust_rec.name, cust_rec.city;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'Customer not found!';
END;
$$;


DO $$
DECLARE
    cust_rec telecom.customer%ROWTYPE;
    rows_found INT;
BEGIN
    SELECT * INTO cust_rec FROM telecom.customer WHERE customer_id = 10;

    GET DIAGNOSTICS rows_found = ROW_COUNT;

    IF rows_found = 0 THEN
        RAISE NOTICE 'Customer not found!';
    ELSE
        RAISE NOTICE 'Customer Name: %, City: %', cust_rec.name, cust_rec.city;
    END IF;
END;
$$;


-- Function with Return

--Task: Create a function to return the total number of products.

--Create Table

CREATE TABLE telecom.product (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100)
);


INSERT INTO telecom.product(product_name) 
VALUES ('Mobile'),('Laptop'),('Computer');


--Function

CREATE OR REPLACE FUNCTION telecom.get_product_count()
RETURNS INT AS $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM telecom.product;
    RETURN cnt;
END;
$$ LANGUAGE plpgsql;

-- Call Function

SELECT telecom.get_product_count();



CREATE OR REPLACE FUNCTION telecom.get_customer_count()
RETURNS INT AS $$
DECLARE
    cnt INT;
BEGIN
    SELECT COUNT(*) INTO cnt FROM telecom.customer;
    RETURN cnt;
END;
$$ LANGUAGE plpgsql;


-- Call Function

SELECT telecom.get_customer_count();

-- Create Procedure

--Task: Create a stored procedure to insert a new customer.


CREATE OR REPLACE PROCEDURE telecom.add_customer(cust_name TEXT, cust_city TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO telecom.customer(name, city) VALUES (cust_name, cust_city);
END;
$$;


--Call Procedure
CALL telecom.add_customer('Suresh', 'Hyderabad');


SELECT * from telecom.customer;


--Write basic PL/pgSQL functions (factorial, greeting message)

'''What is PL/pgSQL Function?

A Function in PostgreSQL is a named block of code that:
•	Takes input parameters
•	Performs calculations or logic
•	Returns a result
 
Syntax Structure

CREATE OR REPLACE FUNCTION function_name(parameters)
'''

RETURNS return_type AS $$
DECLARE
    -- variable declarations
BEGIN
    -- statements
    RETURN value;
END;



$$ LANGUAGE plpgsql;
 
 
 --Greeting Message

--Goal:Create a function greet_user that accepts a name and 
-- returns a greeting message.
 
CREATE OR REPLACE FUNCTION greet_user(p_name TEXT)
RETURNS TEXT AS $$
DECLARE
    greeting TEXT;
BEGIN
    greeting := 'Hello, ' || p_name || '! Welcome to PL/pgSQL.';
    RETURN greeting;
END;
$$ LANGUAGE plpgsql;

--Call the Function

SELECT greet_user('Amdocs Developer');

 
--Factorial Calculation

--Goal:Create a function factorial that returns n!
 
CREATE OR REPLACE FUNCTION telecom.factorial(n INT)
RETURNS BIGINT AS $$
DECLARE
    result BIGINT := 1;
    i INT;
BEGIN
    IF n < 0 THEN
        RAISE EXCEPTION 'Factorial is not defined for negative numbers';
    END IF;

    FOR i IN 1..n LOOP
        result := result * i;
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


--Call the Function

SELECT telecom.factorial(5);

--Recursive Factorial

--If you prefer recursion (like in PL/SQL):


CREATE OR REPLACE FUNCTION telecom.factorial_recursive(n INT)
RETURNS BIGINT AS $$
BEGIN
    IF n = 0 THEN
        RETURN 1;
    ELSIF n < 0 THEN
        RAISE EXCEPTION 'Negative numbers not allowed';
    ELSE
        RETURN n * telecom.factorial_recursive(n - 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

 
--Call the Recursive Function

SELECT telecom.factorial_recursive(5);
 

-- Cleanup

--DROP FUNCTION greet_user(TEXT);

DROP FUNCTION telecom.factorial(INT);

DROP FUNCTION telecom.factorial_recursive(INT);
 
--Assignment:
-- Rewrite an Oracle PL/SQL block into PL/pgSQL function

/* Assignment:Rewrite an Oracle PL/SQL Block into a PostgreSQL PL/pgSQL Function
 
1️ Given: Oracle PL/SQL Block

Here’s an example Oracle PL/SQL anonymous block:
DECLARE
    v_name VARCHAR2(100);
    v_city VARCHAR2(50);
BEGIN
    SELECT name, city INTO v_name, v_city 
    FROM customer 
    WHERE customer_id = 101;

    IF v_city = 'Pune' THEN
        DBMS_OUTPUT.PUT_LINE('Customer is from Pune: ' || v_name);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Customer is from ' || v_city || ': ' || v_name);
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Customer not found');
END;
/
 Your Task: Convert the Block into a PostgreSQL Function

Expected Output Template

Write a PL/pgSQL function named check_customer_city that:
•	Accepts p_customer_id INT
•	Returns TEXT message
•	Prints the message using RAISE NOTICE
•	Returns the message to caller

*/ 
 
CREATE OR REPLACE FUNCTION telecom.check_customer_city(p_customer_id INT)
RETURNS TEXT AS $$
DECLARE
    v_name VARCHAR(100);
    v_city VARCHAR(50);
    msg TEXT;
BEGIN
    SELECT name, city INTO v_name, v_city
    FROM telecom.customer
    WHERE customer_id = p_customer_id;

    IF v_city = 'Pune' THEN
        msg := 'Customer is from Pune: ' || v_name;
    ELSE
        msg := 'Customer is from ' || v_city || ': ' || v_name;
    END IF;

    RAISE NOTICE '%', msg;

    RETURN msg;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        msg := 'Customer not found';
        RAISE NOTICE '%', msg;
        RETURN msg;
END;
$$ LANGUAGE plpgsql;
 

SELECT telecom.check_customer_city(5);


Use Case: Subscription Insertion in a Telecom System
In a telecom application, when inserting a new record into a subscriptions table, you need to:
•	Ensure the customer_id exists in the customers table.
•	Ensure the plan_id exists in the plans table.
•	Catch exceptions like:
o	Foreign key violations
o	Missing customer or plan
o	Duplicate subscription
o	Unexpected errors



CREATE TABLE telecom.customers2 (
    customer_id SERIAL PRIMARY KEY,
    name TEXT
);

CREATE TABLE telecom.plans2 (
    plan_id SERIAL PRIMARY KEY,
    plan_name TEXT
);

CREATE TABLE telecom.subscriptions2 (
    subscription_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES telecom.customers(customer_id),
    plan_id INT REFERENCES telecom.plans(plan_id),
    start_date DATE DEFAULT CURRENT_DATE
);


-- PostgreSQL Function with Exception Handling

CREATE OR REPLACE FUNCTION telecom.add_subscription(p_customer_id INT, p_plan_id INT)
RETURNS VOID AS $$
DECLARE
  v_exists INT;
BEGIN
  -- Check if customer exists
  SELECT 1 INTO v_exists FROM telecom.customers2 WHERE customer_id = p_customer_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer ID % does not exist', p_customer_id;
  END IF;

  -- Check if plan exists
  
  SELECT 1 INTO v_exists FROM telecom.plans2 WHERE plan_id = p_plan_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan ID % does not exist', p_plan_id;
  END IF;

  -- Attempt to insert subscription
  INSERT INTO telecom.subscriptions2(customer_id, plan_id)
  VALUES (p_customer_id, p_plan_id);

  RAISE NOTICE 'Subscription successfully added for customer % on plan %', p_customer_id, p_plan_id;

EXCEPTION
  WHEN foreign_key_violation THEN
    RAISE NOTICE 'FK Violation: Check customer_id or plan_id.';
  WHEN unique_violation THEN
    RAISE NOTICE 'Duplicate subscription exists.';
  WHEN OTHERS THEN
    RAISE NOTICE 'Unexpected error: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


--Sample Test Calls
-- Valid insert
SELECT telecom.add_subscription(1, 2);

-- Invalid customer_id
SELECT telecom.add_subscription(999, 2);

-- Invalid plan_id
SELECT telecom.add_subscription(1, 999);
