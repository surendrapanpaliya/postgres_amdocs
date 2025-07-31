 CREATE TABLE public.employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE
);

/* Multiline Comment */

-- Single line comment 

--Insert Sample Data

INSERT INTO public.employees (first_name, last_name, email, hire_date)
VALUES ('John', 'Doe', 'john.doe@amdocs.com', CURRENT_DATE);

SELECT * FROM public.employees;


SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';



-- Create a schema

CREATE SCHEMA sales;

-- Create table inside schema

CREATE TABLE sales.orders (id SERIAL PRIMARY KEY, item TEXT);

-- Access table
SELECT * FROM sales.orders;


-- List all tables using pg_catalog

SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public';

-- List all roles

SELECT rolname FROM pg_catalog.pg_roles;



CREATE TABLE public.amd_employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    hire_date DATE
);

INSERT INTO public.amd_employees (first_name, last_name, email, hire_date)
VALUES ('John', 'Doe', 'john.doe@amdocs.com', CURRENT_DATE);

SELECT * FROM public.amd_employees;

SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';


CREATE SCHEMA telecom;

--Verify Schema Creation:

SELECT schema_name 
FROM information_schema.schemata
WHERE schema_name = 'telecom';


CREATE TABLE telecom.customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    mobile_number VARCHAR(15),
    city VARCHAR(50),
    balance NUMERIC(10,2)
);

--Verify Table Creation:

SELECT table_name 
FROM information_schema.tables
WHERE table_schema = 'telecom';

-- Insert 5 Sample Records

INSERT INTO telecom.customers (name, mobile_number, city, balance) VALUES
('Rahul Sharma', '9876543210', 'Pune', 500.00),
('Sneha Gupta', '9123456789', 'Mumbai', 1200.50),
('Amit Verma', '9988776655', 'Delhi', 750.00),
('Pooja Nair', '9876501234', 'Bangalore', 300.75),
('Karan Malhotra', '9823456789', 'Hyderabad', 950.00);


-- Query the Data
SELECT * FROM telecom.customers;
