--Assylzhan Kuntubay
--24B031861

--Part 1
DROP TABLE employees CASCADE ;
CREATE TABLE employees(
    emp_id INT PRIMARY KEY ,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    foreign key(dept_id) references departments(dept_id)
);
DROP table departments CASCADE ;
DROP TABLE projects CASCADE ;
CREATE TABLE departments(
    dept_id INT PRIMARY KEY ,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE projects(
    proj_id INT PRIMARY KEY ,
    proj_name VARCHAR(50),
    budget DECIMAL(12,2),
    dept_id INT,
    foreign key (dept_id) references departments(dept_id)
);
INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');
INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

--Part 2
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
--2 indexes

 CREATE INDEX emp_dept_idx ON employees(dept_id);
SELECT * FROM employees WHERE dept_id = 101;
--Indexing foreign key columns significantly speeds up JOIN operations between tables and can improve the performance
--of queries that filter data based on the foreign key. It also helps maintain referential integrity more
--efficiency during UPDATE and DELETE operations on the parent table.


--2.3
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--employees_pkey, departments_pkey, projects_pkey. Automatically was created indexes for the PRIMARY KEY constraints


--part 3
--3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
--NO, because a multicolumn index dept_id and saalry is moet effective when the query uses the leftmost columns
--a query filtering only on salary cant effectively use this index and would likely result in a sequential sscan

--3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Query 1: Filters by dept_id first
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- Query 2: Filters by salary first
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
--Question: Does the order of columns in a multicolumn index matter? Explain
--yes the order is matter. because the index is built in the order the columns are specified.
-- A query can only utilize the index if it includes the leftmost columns

--4.1 Unique Indexes
--4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--What error message did you receive
-- ОШИБКА: повторяющееся значение ключа нарушает ограничение уникальности "employees_pkey"
-- Подробности: Ключ "(emp_id)=(6)" уже существует.

--Exercise 4.2: Unique Index vs UNIQUE Constraint
-- Add a phone column with UNIQUE constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;
--View the indexes:

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
--Question: Did PostgreSQL automatically create an index? What type of index?
--Yes, when we add a UNIQUE constraint, postgreSQL automatically creates a unique Btree index to enforce that constraint
--employees_phone_key

--Part 5: Indexes and Sorting
-- 5.1: Create an Index for Sorting
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);
---Test with an ORDER BY query:

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
--Question: How does this index help with ORDER BY queries?
-- An index created with DESC(salary DESC) stores the data in descending order, when we run a query with descending order it helps avoid a sorting operation

--5.2  Index with NULL Handling
--Create an index that handles NULL values specially:
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

--Part 6: Indexes on Expressions
--6.1: Create a Function-Based Index
--Create an index for case-insensitive employee name searches:

CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

-- This query can use the expression index
SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
--Question: Without this index, how would PostgreSQL search for names case-insensitively?
--Withoutt the expression index,PostgreSQL would have to perform a sequential scan. It would convert every single emp_table in the table
--to lowercase using LOWER() function and then compare, which is very inefficient on large tables.

-- 6.2: Index on Calculated Values
--Add a hire_date column and create an index on the year:
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;
-- Create index on the year extracted from hire_date
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

--Part 7: Managing Indexes
--7.1: Rename an Index
--Rename the emp_salary_idx index to employees_salary_index:
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

--Verify the rename:
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- 7.2: Drop Unused Indexes
--Drop the redundant multicolumn index we created earlier:
DROP INDEX emp_salary_dept_idx;

--Question: Why might you want to drop an index?
--When indexes are unused and redundant

-- 7.3: Reindex
--Rebuild an index to optimize its structure:
REINDEX INDEX employees_salary_index;
--When is REINDEX useful?
-- • After bulk INSERT operations, • When index becomes bloated, • After significant data modifications

--Part 8: Practical Scenarios
-- 8.1: Optimize a Slow Query
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

--Create indexes to optimize this query:
-- Index for the WHERE clause
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

-- Index for the JOIN
-- (already created: emp_dept_idx)
-- Index for ORDER BY
-- (already created: emp_salary_desc_idx)

-- 8.2: Partial Index
--Create an index only for high-budget projects (budget > 80000):
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
--Question: What's the advantage of a partial index compared to a regular index?
--Smaller size and lower maintenance overhead.

-- 8.3: Analyze Index Usage
--Use EXPLAIN to see if indexes are being used:
EXPLAIN SELECT * FROM employees WHERE salary > 52000;

--Question: Does the output show an "Index Scan" or a "Seq Scan" (Sequential Scan)? What does this tell you?
-- output shows seq scan, it means yhe database is reading the entire table, which suggests no suitable index exists or optimizer
--has decided a table, which scan is faster


-- Part 9: Index Types Comparison
-- 9.1: Create a Hash Index
--Create a hash index on department name:
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

--Test the hash index:
SELECT * FROM departments WHERE dept_name = 'IT';

---Question: When should you use a HASH index instead of a B-tree index?
-- For simple equality comparisons(=) and for faster operation

-- 9.2: Compare Index Types
--Create both B-tree and Hash indexes on the project name:
-- B-tree index
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
-- Hash index
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

--Test with different queries:
-- Equality search (both can be used)
SELECT * FROM projects WHERE proj_name = 'Website Redesign';

-- Range search (only B-tree can be used)
SELECT * FROM projects WHERE proj_name > 'Database';

--Part 10: Cleanup and Best Practices
-- 10.1: Review All Indexes
--List all indexes and their sizes:
SELECT
 schemaname,
 tablename,
 indexname,
 pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

--Question: Which index is the largest? Why?
--Indexes on columns with many repeated queries or wide data types will be larger

-- 10.2: Drop Unnecessary Indexes
--Identify and drop indexes that are duplicates or rarely used:

-- Drop the duplicate expression indexes
DROP INDEX IF EXISTS proj_name_hash_idx;

-- 10.3: Document Your Indexes
--Create a view that documents all custom indexes:
CREATE VIEW index_documentation AS
SELECT
 tablename,
 indexname,
 indexdef,
 'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
 AND indexname LIKE '%salary%';


SELECT * FROM index_documentation;

--Summary Questions
--1. What is the default index type in PostgreSQL?
    -- B-tree

--2. Name three scenarios where you should create an index:
    -- columns in WHERE clauses, Foreign key columns, columns in Join conditions, Columns in Order by

--3. Name two scenarios where you should NOT create an index:
    --when tables are small or rarely queried

--4. What happens to indexes when you INSERT, UPDATE, or DELETE data?
    -- They must be updated

--5. How can you check if a query is using an index?
    -- by using EXPLAIN and explain analyze command before the query


