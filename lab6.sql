--Laboratory work
--Student : Assylzhan Kuntubay
--Student ID: 24B031861

--Part 1: Database Setup
DROP TABLE employees CASCADE ;
CREATE TABLE employees(
    emp_id INT PRIMARY KEY ,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10,2)
);
DROP table departments CASCADE ;
DROP TABLE projects CASCADE ;
CREATE TABLE departments(
    dept_id INT PRIMARY KEY ,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE projects(
    project_id INT PRIMARY KEY ,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10,2)
);
--1.2
INSERT INTO employees(emp_id, emp_name,dept_id, salary) Values
 (1,'John Smith',101, 50000),
 (2,'Jane Doe',102, 60000),
 (3,'Mike Johnson', 101,55000),
 (4,'Sarah Williams',103,65000),
 (5,'Tom Brown',NULL,45000);

INSERT INTO departments(dept_id, dept_name, location) VALUES
 (101,'IT','Building A'),
 (102,'HR','Building B'),
 (103,'Finance','Building C'),
 (104,'Marketing','Building D');

INSERT INTO projects(project_id, project_name, dept_id, budget) VALUES
 (1,'Website redesign',101,100000),
 (2,'Employees Training',102,50000),
 (3,'Budget Analysis',103,75000),
 (4,'Cloud Migration',101, 150000),
 (5,'AI Research',NULL,200000);

--Part 2 Cross join
--2.1
SELECT e.emp_name,d.dept_name
from employees e CROSS JOIN departments d;
--Answer 5*4=20

--2.2
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

select e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

--2.3
SELECT e.emp_name, p.project_name
FROM employees e CROSS JOIN projects p
ORDER BY e.emp_name, p.project_name;
--Answer: 5*5=25

--Part 3
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d
ON e.dept_id = d.dept_id;
--Because the Tom Browns dept_id is NULL;

--3.2
SELECT e.emp_name, d.dept_name, d.location
FROM employees e INNER JOIN departments d USING (dept_id);
--ON used with different columns names while USING only with equal names
--we select all table with ON 2 columns with equal variables, but with USING only one

--3.3
SELECT emp_name , dept_name, departments.location
from employees
NATURAL INNER JOIN  departments;

--3.4
SELECT employees.emp_name, departments.dept_name, projects.project_name
from employees
INNER JOIN departments USING (dept_id)
INNER JOIN projects USING (dept_id);


SELECT employees.emp_name, departments.dept_name, projects.project_name
FROM employees
INNER JOIN departments ON employees.dept_id = departments.dept_id
INNER JOIN projects ON projects.dept_id = departments.dept_id;

SELECT employees.emp_name, departments.dept_name,projects.project_name
FROM employees
NATURAL INNER JOIN departments
NATURAL INNER JOIN projects;

--4.1
select
    e.emp_name,
    e.emp_id AS emp_dept,
    d.dept_id As dept_dept,
    d.dept_name
FROM employees e LEFT JOIN departments d ON e.dept_id= d.dept_id;
--Toms id is null because in left join result depends from first left table;

--4.2
select
    e.emp_name,
    e.emp_id AS emp_dept,
    d.dept_id As dept_dept,
    d.dept_name
FROM employees e LEFT JOIN departments d USING (dept_id);

--4.3
SELECT employees.emp_name, departments.dept_name
FROM employees
LEFT JOIN departments USING (dept_id)
WHERE dept_id IS NULL;

--4.4
SELECT
    departments.dept_id,
    count(employees.emp_id) AS employee_count
FROM departments LEFT JOIN employees USING (dept_id)
GROUP BY dept_id, dept_name
order by employee_count DESC ;

--5.1
SELECT employees.emp_name, d.dept_name
from employees
RIGHT JOIN departments d on employees.dept_id = d.dept_id;

SELECT departments.dept_name, departments.location
FROM employees
RIGHT JOIN departments ON employees.dept_id=departments.dept_id
WHERE emp_id IS NULL;

--Part 6
SELECT
    e.emp_name,
    e.dept_id As emp_dept,
    d.dept_id As dept_dept,
    d.dept_name
from employees e FULL JOIN departments d
on e.dept_id= d.dept_id;

SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'Department without employees'
        WHEN d.dept_id IS NULL THEN 'Employee without depertment'
        ELSE 'Matched'
    END AS record_status,
    e.emp_name, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id= d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL ;

--7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id
   AND d.location = 'Building A';

--7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
  ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--ON clause : Applies the filter before the join , so all employees are included, but only departments in Building A are matched
--Where clause: Applies the filter After the join , so employees are excluded if their department is not in Building A.

--7.3
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
Inner Join departments d
ON e.dept_id=d.dept_id
WHERE d.location= 'Building A';

SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
Inner Join departments d
ON e.dept_id=d.dept_id
AND d.location= 'Building A';

--There is no difference because inner join only keeps rows that match in both tables
--the filter d.location='Building A' applies to those same matched rows

--8.1
SELECT
    d.dept_name,
    e.emp_name,
    e.salary,
    p.project_name,
    p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

--8.2
ALTER TABLE employees
ADD COLUMN manager_id INT;
UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT
    employees.emp_name As employee,
    m.emp_name as manager
FROM employees
LEFT JOIN employees m
On employees.manager_id= m.emp_id;

--8.3
SELECT d.dept_name,
       avg(e.salary) AS avg_salary
From departments d
INNER JOIN employees e on d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary)> 50000;

--LAB questions
--1) What is the difference between INNER JOIN and LEFT JOIN ?
--INNER JOIN shows only rows with same info in both tables
--Left join shows all rows from left table

--2) When would you use Cross join in a practical scenario?
--When we need all possible row combinations from both tables

--3)Explain why the position of a filter condition(ON vs WHERE) matters for outer joins but not for inner joins
--For INNER JOIN not matter where the filter (ON or WHERE)
--For OUTER JOIN (LEFT or RIGHT) its matter
--ON using during the joining, rows without matching = NULL
--Where using after joining rows, rows with NULL deleted

--4)What is the result of Select count(*) from table1 cross join table 2
--if table1 has 5rows and table2 has 10 rows
--5*10=50

--5)How does NATURAL JOIN determine which columns to join on?
--NATURAL JOIN automatically join columns with same name

--6) What are the potential risks of using natural join?
--Get errors if name of columns same but have different meaning
--Hard to understand code and read

 --7)Convert left join to a right join
--Result will be the same, cause right join is mirrored version of left join

--8When should we use FULL OUTER JOIN instead of other join types?
--When we wanna see colunms from both tables
--to find not matched data
--join results of  left and right join