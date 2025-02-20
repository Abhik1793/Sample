-- Identify employees with the highest total hours worked and least absenteeism.
SELECT 
    e.employeeid,
    e.employeename,
    SUM(a.total_hours) AS total_hours_worked,
    SUM(a.days_absent) AS total_days_absent,
    (SUM(a.total_hours) * SUM(a.days_present)) AS productivity_score
FROM 
    employee_details e
JOIN 
    attendance_records a ON e.employeeid = a.employeeid
GROUP BY
    e.employeeid, e.employeename
ORDER BY
    productivity_score DESC
LIMIT 10;
    
-- Analyze how training programs improve departmental performance    
select e.department_id,
avg(CASE 
            WHEN e.performance_score = 'Excellent' THEN 5
            WHEN e.performance_score = 'Good' THEN 4
            WHEN e.performance_score = 'Average' THEN 3
            ELSE 0 
        END
    ) as avg_performance_score_before_training,
avg(t.feedback_score) as avg_performance_after_training
from employee_details e join  training_programs t
on e.employeeid = t.employeeid 
group by e.department_id order by avg_performance_score_before_training desc;

-- Evaluate the efficiency of project budgets by calculating costs per hour worked
select 
project_name,
sum(p.budget) as total_budget,
sum(p.hours_worked) as total_hours_worked,
(sum(budget)/sum(hours_worked)) as average_cost_per_hour
from project_assignments p
group by project_name
order by average_cost_per_hour desc;

-- Measure attendance trends and identify departments with significant deviations
select e.department_id,
avg(a.days_present) as avgerage_days_present,
avg(a.days_absent) as average_days_absent,
stddev(a.days_present) as deviation
from employee_details e join attendance_records a
on e.employeeid = a.employeeid
group by
e.department_id
order by deviation desc;

-- Link training technologies with project milestones to assess the real-world impact of training
SELECT tp.technologies_covered, AVG(pa.milestones_achieved) AS avg_milestones
FROM Training_Programs tp
JOIN Project_Assignments pa ON tp.employeeid = pa.employeeid
GROUP BY tp.technologies_covered
ORDER BY avg_milestones DESC;

-- Identify employees who significantly contribute to high-budget projects while maintaining excellent performance scores.
select e.employeeid,
e.employeename,
p.project_name,
p.budget,
e.performance_score
 from employee_details e join project_assignments p 
 on e.employeeid=p.employeeid
 where p.budget > 400000 and e.performance_score="Excellent" 
 order by p.budget desc,e.performance_score;
 
-- Identify employees who have undergone training in specific technologies and contributed to high-performing projects using those technologies.
SELECT 
    tp.employeeid, 
    ed.employeename, 
    tp.technologies_covered, 
    pa.project_id, 
    pa.project_name, 
    pa.milestones_achieved
FROM Training_Programs tp
JOIN Project_Assignments pa 
    ON tp.employeeid = pa.employeeid
JOIN Employee_Details ed 
    ON tp.employeeid = ed.employeeid
WHERE EXISTS (
    SELECT 1
    FROM (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.technologies_covered, ',', numbers.n), ',', -1)) AS covered_tech
          FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
          WHERE numbers.n <= 1 + LENGTH(tp.technologies_covered) - LENGTH(REPLACE(tp.technologies_covered, ',', ''))
    ) AS tech_split
    WHERE LOWER(pa.technologies_used) LIKE CONCAT('%', LOWER(tech_split.covered_tech), '%')
)
ORDER BY pa.milestones_achieved DESC;

