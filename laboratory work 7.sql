--Student name:
--Assylzhan Kuntubay
--Student ID:
--24B031861

--Part 1: use the same setup from labwork 6
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
--Part 2
CREATE VIEW employee_details AS
Select employees.emp_name, employees.salary,emp_id, departments.dept_id, departments.dept_name, departments.location
FROM employees
JOIN departments ON employees.dept_id= departments.dept_id;

SELECT * FROM employee_details;
--Tom does not appear because he has no department

--2.2
CREATE VIEW dept_statistics AS
SELECT
    departments.dept_id, departments.dept_name,
    COUNT(employees.emp_id) AS employee_count,
    round(AVG(employees.salary),2) AS avg_salary,
    MAX(employees.salary) AS max_salary,
    MIN(employees.salary) AS min_salary
FROM departments
LEFT JOIN employees  on departments.dept_id = employees.dept_id
GROUP BY departments.dept_id, dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC ;

--2.3
CREATE VIEW project_overview AS
SELECT
    projects.project_id,projects.project_name, projects.budget,
    departments.dept_id, departments.dept_name, departments.location,
    Coalesce(cnt.team_size,0) AS team_size
From projects
LEFT JOIN departments  on projects.dept_id = departments.dept_id
LEFT JOIN (
    SELECT dept_id, COUNT(emp_id) AS team_size
    FROM employees
    GROUP BY dept_id
) cnt ON cnt.dept_id= departments.dept_id;

--2.4
create view high_earners AS
SELECT employees.emp_id, employees.emp_name, employees.salary, employees.dept_id
FROM employees
WHERE salary> 55000;

--3.1
CREATE or replace view employee_details AS
SELECT
    e.emp_name,
    e.salary,
    e.emp_id,
    e.dept_id,
    d.dept_name,
    d.location,
    Case
        WHEN e.salary> 60000 THEN 'High'
        when e.salary> 50000 THEN 'Medium'
        else 'Standard'
    END AS salary_grade
From employees e
LEFT JOIN departments d on e.dept_id = d.dept_id;

--3.2
Alter view high_earners rename to top_performers;

--3.3
CREATE temp view temp_view AS
SELECT employees.emp_id, employees.emp_name,employees.salary
FROM employees
WHERE salary<50000;
DROP VIEW if exists temp_view;

--4.1
create or replace view employee_salaries AS
SELECT employees.emp_id, employees.emp_name, employees.dept_id,employees.salary
FROM employees;

--4.2
UPDATE employee_salaries
SET salary = 52000
where emp_name= 'John Smith';

--4.3
INSERT INTO employee_salaries(emp_id, emp_name, dept_id, salary)
VALUES (6,'Alice Johnson',102, 58000);

--4.4
CREATE OR REPLACE VIEW it_employees As
SELECT employees.emp_id,employees.emp_name,employees.dept_id,employees.salary
FROM employees
Where dept_id= 101
WITH Local Check Option;

--5.1 Create materialized view
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    d.dept_id, d.dept_name,
    coalesce(count(e.emp_id),0)AS total_employees,
    coalesce(sum(e.salary),0) AS total_salaries,
    coalesce(p.project_count), 0) AS total_projects,
    coalesce(p.total_budget),0) As total_project_budget
FROM departments d
Left join employees e on e.dept_id = d.dept_id
Left join (
    Select dept_id, COUNT(*) AS project_count, SUM(budget) AS total budget
    From projects
    Group by dept_id
) p on p.dept_id= d.dept_id
Group by d.dept_id, d.dept_name, p.project_count, p.total_budget
WITH DATA;

--5.2
INSERT INTO employees(emp_id, emp_name, dept_id, salary)
VALUES (8,'Charlie Brown',101, 54000);
REFRESH MATERIALIZED VIEW dept_summary_mv;

--5.3
CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id
ON dept_summary_mv(dept_id);

--5.4
CREATE materialized view project_ststs_mv AS
SELECT
    projects.project_id,
    projects.project_name,
    projects.budget,
    departments.dept_name,
    count(employees.emp_id) AS assigned_employees
From projects
LEFT JOIN departments  on projects.dept_id = departments.dept_id
LEFT JOIN employees  on projects.dept_id = employees.dept_id
GROUP BY project_id, project_name, budget, dept_name
WITH NO DATA;

--PART 6
CREATE ROLE analyst NOLOGIN ;
create role data_viewer LOGIN PASSWORD 'viewer123';
create role report_user LOGIN PASSWORD 'report456';

create role dg_creator LOGIN PASSWORD 'creator789' CREATEDB ;
create role user_manager LOGIN password 'manager101' CREATEROLE ;
create role admin_user LOGIN password 'admin999' SUPERUSER ;

--6.3Grant priviligies
GRANT SELECT On employees, departments, projects TO analyst;
grant all privileges on employee_details to data_viewer;
GRANT select,insert on employees to report_user;

--6.4
create role hr_team NOLOGIN ;
create role finance_team NOLOGIN ;
create role it_team NOLOGIN ;

create role hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';

grant hr_team to hr_user1;
grant finance_team to finance_user1;

grant select, update on employees to hr_team;
grant select on dept_statistics to finance_team;

--6.5 REVOKE privileges
REVOKE update on employees from hr_team;
revoke hr_team from hr_user1;
REVOKE ALL PRIVILEGES ON employee_details from data_viewer;

--6.6
ALTER ROLE analyst with login password 'analyst123';
alter role user_manager with superuser ;
alter role data_viewer with connection limit 5;

--part 7 Advanced role manager
create role read_only nologin ;
GRANT select on all tables in schema public to read_only;

create role junior_analyst LOGIN password 'junior1';
create role senior_analyst LOGIN password 'senior1';
GRANT read_only to junior_analyst, senior_analyst;
GRANT INSERT, update on employees to senior_analyst;

--7.2
create role project_manager LOGIN PASSWORD 'pm123';
alter view dept_statistics owner to project_manager;
alter table projects owner to project_manager;

--7.3
CREATE ROLE temp_owner login  password 'tem001';
create table temp_table (id int);
alter table temp_table owner to temp_owner;
reassign owned by temp_owner to postgres;
drop owned by temp_owner;
drop role temp_owner;

--8.1
create or replace dept_dashboard AS
SELECT
    departments.dept_id,
    departments.dept_name,
    departments.location,
    count(employees.emp_id) as employee_count,
    round(coalesce(avg(employees.salary),0),2) as avg_salary,
    coalesce(sum(case when projects.project_id is not null then 1 else 0 end),0) As active_projects
from departments
left join employees on departments.dept_id = employees.dept_id
left join projects  on departments.dept_id = projects.dept_id
group by departments.dept_id, dept_name, location;

--8.2
ALTER table projects
add column if not exists created_date timestamp default current_timestamp;

create or replace view high_budget as
select
    projects.project_id,
    projects.project_name,
    projects.budget,
    departments.dept_name,
    case
        when projects.budget>150000 then 'critical'
        else 'standard'
    end as status
from projects
left join departments  on projects.dept_id = departments.dept_id
where budget>75000;

--8.3
create role viewer nologin ;
grant select on all tables in schema public to viewer;

create role entry_role nologin ;
grant viewer to entry_role;
grant insert on employees, projects to entry_role;

create role alice login password 'alice123';
create role bob login password 'bob123';
create role charlie login password 'charlie123';

grant viewer to alice;
grant analyst to bob;
grant manager_role to charlie;



