CREATE DATABASE advanced_Lab;
CREATE TABLE employees(
    emp_id SERIAL PRIMARY KEY,
    firs_name VARCHAR,
    last_name VARCHAR,
    department varchar,
    salary integer,
    hire_date date,
    status varchar(20) default 'Active'
);

drop table departments;
drop table projects cascade ;

create table departments(
    dept_id serial primary key ,
    dept_name varchar(20),
    budget int,
    manager_id int
);

create table projects(
    project_id serial primary key ,
    project_name varchar(20),
    dept_id int,
    start_date date,
    end_date date,
    budget integer
);

--2 PART B;
insert into employees (emp_id, firs_name, last_name, department) values (1, 'Assylzhan', 'Kuntubay','IT');

 --3
insert into employees (emp_id,firs_name, last_name, department,salary,status)
values (2,'Alina','Mukhametsadyk','IS',default,default ) ;

--4
insert into departments (dept_name, budget)
values ('Finance',120000),
       ('Marketing',20000),
       ('OP',90000);

--5
insert into employees (emp_id,firs_name, last_name, department, salary, hire_date)
VALUES (3,'Arai','Bekbatsha','IT',50000*0.1, current_date);

--6
create temporary table temp_employees as
select * from employees where department = 'IT';

--7 PART C
update employees set salary = salary*1.10;

--8
update employees set status='Senior'
where salary>60000 and hire_date < '2020-01-01';

--9
update employees set department=
    case
        when salary> 80000 then 'Management'
        when salary between 50000 and 80000 then 'senior'
        else 'Junior'
    end;
--10
alter table  employees alter column department set default 'General';
update employees
set department= default
where status = 'Inactive';

--11
update departments d
set budget = (
    select avg(salary) * 1.20
    from employees e
    where e.department = d.dept_name
    )
where dept_name in (select distinct employees.department from employees where department is not null);

--12
update employees
set salary= salary*1.5,
    status = 'promoted'
where department = 'Sales';

--13 Part D
insert into employees (emp_id,firs_name, last_name, department, salary, status)
values (4,'kuanysh','komekbay','Finance',50000,'Terminated');
 delete from employees
 where status = 'Terminated';

--14
delete from employees
where salary< 40000
and hire_date>'2023-01-01'
and department is null;

--15
delete from departments
where dept_id not in (
    select distinct d.dept_id
    from departments d
    join employees e on d.dept_name = e.department
    where e.department is not null
    );

--16
delete from projects
where end_date < '2023-01-01'
returning *;

--17
insert into employees(emp_id, firs_name, last_name, department, salary)
values (5,'Null','kaldybai',null,null);

--18
update employees
set department = 'Unassigned'
where department is null;

--19
delete from employees
    where salary is null or department is null;
--20
insert into employees(firs_name, last_name, department, salary)
values ('Ali','Kali','IT',450000)
returning emp_id, firs_name|| ' '|| last_name as full_name;

--21
update employees
    set salary= salary+5000
where department='IT'
returning emp_id, salary-5000 as old_salary, salary as new_salary;
--22
delete from employees
where hire_date<'2020-01-01'
returning *;

--23
insert into employees(firs_name, last_name, department, salary)
select 'selena','gomez','ART',200000
where not exists(
    select 1 from employees
    where firs_name= 'selena' and last_name='gomez'
);

--24
UPDATE employees
SET salary =
    CASE
        WHEN department IN (
            SELECT dept_name FROM departments WHERE budget > 100000
        ) THEN salary * 1.10
        ELSE salary * 1.05
    END;

-- 25. bulk operations
INSERT INTO employees (firs_name, last_name, department, salary) VALUES
('Kairat', 'Nurtas', 'ART', 40000),
('Toregali', 'Toreali', 'ART', 42000),
('Irina', 'Kairatovna', 'ART', 38000),
('Qazyna', 'Kunesbay', 'IT', 45000),
('Aknur', 'Ryskul', 'Sales', 47000);


UPDATE employees
SET salary = salary * 1.10
WHERE firs_name IN ('Kairat', 'Toregali', 'Irina', 'Qazyna', 'Aknur');

-- 26. Data migration simulation
CREATE TABLE employee_archive AS TABLE employees WITH NO DATA;

INSERT INTO employee_archive
SELECT * FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

-- 27. Complex business logic
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND p.dept_id IN (
      SELECT d.dept_id
      FROM departments d
      JOIN employees e ON d.dept_name = e.department
      GROUP BY d.dept_id
      HAVING COUNT(e.emp_id) > 3
  );