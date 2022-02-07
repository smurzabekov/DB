-- Мурзабеков Султан БПИ195

-- 1.
select employee_id, first_name, second_name, salary,
      max(salary)  over (rows between unbounded preceding and unbounded following)::decimal / salary as less_by_comp
from employees;

--  2.
select employee_id, first_name, second_name, department_id, salary,
       salary / avg(salary) over (partition by department_id
                        rows between unbounded preceding and unbounded following
                        )::decimal as avg_salary_div_dep_sal
from employees;

-- 3. 
select *,
       res.avg_sal_dep / res.avg_sal_job as avg_sal_dep_div_avg_sal_job
from(
    select employee_id, first_name, second_name, department_id, salary,
       avg(salary) over(partition by department_id
                        rows between unbounded preceding and unbounded following
                        ) as avg_sal_dep,
       job_id,
       avg(salary) over(partition by job_id
                        rows between unbounded preceding and unbounded following
                        ) as avg_sal_job
    from employees
) as res;

-- 4.
select employee_id,  first_name, second_name, department_id,salary
from ( select distinct on (department_id) employee_id,
                                          first_name,
                                          second_name,
                                          department_id,
                                          salary,
                                          min(salary)
                                          over (partition by department_id rows between unbounded preceding and unbounded following) as mi_sal_dep
       from employees
       order by department_id, first_name
    ) as res;

-- 5. 
create table hw5.scores
(
	man_id int not null,
	division int not null,
	score double precision not null,
	constraint scores_departments_department_id_fk
		foreign key (division) references hw5.departments (department_id),
	constraint scores_employees_employee_id_fk
		foreign key (man_id) references hw5.employees (employee_id)
);

create unique index scores_man_id_uindex
	on hw5.scores (man_id);

select man_id, division, score from(
    select *,
       row_number() over (partition by division order by score desc
           rows between unbounded preceding and unbounded following) as rn
    from scores
    order by division
) as res
where res.rn <= 3;

--  6.
select *,
       avg_sal_in_gr.salary - avg_sal_in_gr.avg_gr_salary as diff_salary_and_avg_sal
from(
    select *,
           avg(divided.salary) over (
                                        partition by divided.gr_num
                                        order by divided.first_name
                                        rows between unbounded preceding
                                                      and unbounded following
                                    ) as avg_gr_salary
    from(
            select employee_id, first_name, second_name, ntile(5) over (order by first_name) as gr_num,
                   salary
            from employees
        ) as divided
) as avg_sal_in_gr;


-- 7. 
select base.employee_id, base.first_name, base.second_name, base.hire_date, base.hire_in_year_interval,
       count(base.hire_date) over (partition by date_part('year', hire_date)
                                    order by hire_date, first_name
                                    rows between 1 following and unbounded following
                                ) as hired_after_in_this_year
from (
    select e.employee_id, e.first_name, e.second_name, e.hire_date, count(e.hire_date) as hire_in_year_interval
    from employees as e
    inner join ( select employee_id,
                   hire_date - interval '1 year' as year_before,
                   hire_date + interval '1 year' as year_after
                   from employees
                ) as year_interval
    on year_interval.employee_id <> e.employee_id and e.hire_date between year_interval.year_before and year_interval.year_after
    group by e.employee_id, e.first_name, e.second_name, e.hire_date
    ) as base
group by base.employee_id, base.first_name, base.second_name, base.hire_date, base.hire_in_year_interval
order by base.hire_date;
