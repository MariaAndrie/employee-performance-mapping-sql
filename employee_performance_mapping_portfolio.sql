/*
Project: Employee Performance Mapping
MySQL 8+

Project objective:
Use employee data to explore workforce structure, validate data quality,
analyze performance and salary patterns, identify reporting relationships,
and demonstrate practical SQL skills for analytics roles.

Main business questions:
1. Is the employee dataset complete and usable for analysis?
2. How are employees distributed by department, rating, geography, and experience?
3. Which employees are low, medium, or high performers?
4. Who are the managers and how many direct reports do they have?
5. How do salary and performance vary by role, department, country, and continent?
6. Do employee roles align with experience-based seniority expectations?

Notes:
- This script does not create new business tables.
- Data cleaning is handled through validation queries and a standardized CTE layer.
- Existing objects referenced from the original work are preserved where relevant.
*/

/* ============================================================
   0. ENVIRONMENT SETUP
   ============================================================ */
CREATE DATABASE IF NOT EXISTS employee;
USE employee;
SELECT DATABASE() AS active_database;

/* ============================================================
   1. INITIAL DATA INSPECTION
   Purpose: understand schema and preview the source table.
   ============================================================ */
DESCRIBE emp_record_table;
SELECT *
FROM emp_record_table
LIMIT 10;

/* ============================================================
   2. DATA QUALITY CHECKS
   Purpose: verify whether the dataset is reliable before analysis.
   ============================================================ */

-- 2.1 Row count
SELECT COUNT(*) AS total_rows
FROM emp_record_table;

-- 2.2 Check uniqueness of employee ID
SELECT 
    COUNT(*) AS total_rows,
    COUNT(emp_id) AS non_null_emp_ids,
    COUNT(DISTINCT emp_id) AS distinct_emp_ids,
    COUNT(*) - COUNT(DISTINCT emp_id) AS duplicate_emp_id_gap
FROM emp_record_table;

-- 2.3 Find duplicate employee IDs, if any
SELECT emp_id, COUNT(*) AS duplicate_count
FROM emp_record_table
GROUP BY emp_id
HAVING COUNT(*) > 1;

-- 2.4 Null / missing-value audit for core analytical columns
SELECT 
    SUM(CASE WHEN emp_id IS NULL THEN 1 ELSE 0 END) AS null_emp_id,
    SUM(CASE WHEN first_name IS NULL OR TRIM(first_name) = '' THEN 1 ELSE 0 END) AS null_or_blank_first_name,
    SUM(CASE WHEN last_name IS NULL OR TRIM(last_name) = '' THEN 1 ELSE 0 END) AS null_or_blank_last_name,
    SUM(CASE WHEN gender IS NULL OR TRIM(gender) = '' THEN 1 ELSE 0 END) AS null_or_blank_gender,
    SUM(CASE WHEN dept IS NULL OR TRIM(dept) = '' THEN 1 ELSE 0 END) AS null_or_blank_dept,
    SUM(CASE WHEN role IS NULL OR TRIM(role) = '' THEN 1 ELSE 0 END) AS null_or_blank_role,
    SUM(CASE WHEN salary IS NULL THEN 1 ELSE 0 END) AS null_salary,
    SUM(CASE WHEN emp_rating IS NULL THEN 1 ELSE 0 END) AS null_emp_rating,
    SUM(CASE WHEN country IS NULL OR TRIM(country) = '' THEN 1 ELSE 0 END) AS null_or_blank_country,
    SUM(CASE WHEN continent IS NULL OR TRIM(continent) = '' THEN 1 ELSE 0 END) AS null_or_blank_continent,
    SUM(CASE WHEN exp IS NULL THEN 1 ELSE 0 END) AS null_exp,
    SUM(CASE WHEN manager_id IS NULL THEN 1 ELSE 0 END) AS null_manager_id
FROM emp_record_table;

-- 2.5 Domain / validity checks
SELECT 
    SUM(CASE WHEN emp_rating < 0 THEN 1 ELSE 0 END) AS invalid_negative_rating,
    SUM(CASE WHEN salary < 0 THEN 1 ELSE 0 END) AS invalid_negative_salary,
    SUM(CASE WHEN exp < 0 THEN 1 ELSE 0 END) AS invalid_negative_experience
FROM emp_record_table;

-- 2.6 Orphan manager check: employees whose manager_id does not exist in employee IDs
SELECT e.emp_id, e.first_name, e.last_name, e.manager_id
FROM emp_record_table e
LEFT JOIN emp_record_table m
    ON e.manager_id = m.emp_id
WHERE e.manager_id IS NOT NULL
  AND m.emp_id IS NULL;

/* ============================================================
   3. STANDARDIZED / CLEANED ANALYTICAL LAYER
   Purpose: clean and standardize employee data and create 
   reusable fields for analysis.
   ============================================================ */
WITH cleaned_employees AS (
    SELECT
        emp_id,
        TRIM(first_name) AS first_name,
        TRIM(last_name) AS last_name,
        CONCAT(TRIM(first_name), ' ', TRIM(last_name)) AS employee_name,
        UPPER(TRIM(gender)) AS gender,
        TRIM(dept) AS dept,
        TRIM(role) AS role,
        salary,
        emp_rating,
        exp,
        manager_id,
        TRIM(country) AS country,
        TRIM(continent) AS continent,
        CASE
            WHEN emp_rating < 2 THEN 'Low Performer'
            WHEN emp_rating BETWEEN 2 AND 4 THEN 'Average Performer'
            WHEN emp_rating > 4 THEN 'High Performer'
            ELSE 'Unclassified'
        END AS performance_band,
        CASE
            WHEN exp <= 2 THEN 'Junior'
            WHEN exp BETWEEN 3 AND 5 THEN 'Associate'
            WHEN exp BETWEEN 6 AND 10 THEN 'Senior'
            WHEN exp > 10 THEN 'Leadership Track'
            ELSE 'Unclassified'
        END AS experience_band
    FROM emp_record_table
)
SELECT *
FROM cleaned_employees
LIMIT 10;

/* ============================================================
   4. CORE EMPLOYEE OVERVIEW
   Purpose: basic business-facing slices of the workforce.
   ============================================================ */

-- 4.1 Basic employee listing
SELECT emp_id, first_name, last_name, gender, dept
FROM emp_record_table
ORDER BY emp_id;

-- 4.2 Employees in Finance department
SELECT CONCAT(TRIM(first_name), ' ', TRIM(last_name)) AS employee_name,
       dept
FROM emp_record_table
WHERE LOWER(TRIM(dept)) = 'finance'
ORDER BY employee_name;

-- 4.3 Employees from Finance and Healthcare departments
SELECT first_name, last_name, dept
FROM emp_record_table
WHERE LOWER(TRIM(dept)) IN ('finance', 'healthcare')
ORDER BY dept, first_name, last_name;

/* ============================================================
   5. PERFORMANCE ANALYSIS
   Purpose: classify employees based on performance rating.
   ============================================================ */

-- 5.1 Low performers (rating < 2)
SELECT emp_id, first_name, last_name, gender, dept, emp_rating
FROM emp_record_table
WHERE emp_rating < 2
ORDER BY emp_rating, emp_id;

-- 5.2 High performers (rating > 4)
SELECT emp_id, first_name, last_name, gender, dept, emp_rating
FROM emp_record_table
WHERE emp_rating > 4
ORDER BY emp_rating DESC, emp_id;

-- 5.3 Mid performers using BETWEEN for clarity
SELECT emp_id, first_name, last_name, gender, dept, emp_rating
FROM emp_record_table
WHERE emp_rating BETWEEN 2 AND 4
ORDER BY emp_rating DESC, emp_id;

-- 5.4 Performance distribution by department
WITH cleaned_employees AS (
    SELECT
        emp_id,
        CONCAT(TRIM(first_name), ' ', TRIM(last_name)) AS employee_name,
        CONCAT(UCASE(LEFT(TRIM(dept), 1)), LCASE(SUBSTRING(TRIM(dept), 2))) AS dept,
        emp_rating,
        CASE
            WHEN emp_rating < 2 THEN 'Low Performer'
            WHEN emp_rating BETWEEN 2 AND 4 THEN 'Average Performer'
            WHEN emp_rating > 4 THEN 'High Performer'
            ELSE 'Unclassified'
        END AS performance_band
    FROM emp_record_table
)
SELECT dept,
       performance_band,
       COUNT(*) AS employee_count,
       ROUND(AVG(emp_rating), 2) AS avg_rating_in_group
FROM cleaned_employees
GROUP BY dept, performance_band
ORDER BY dept, avg_rating_in_group DESC;

-- 5.5 Department-level rating benchmark with window functions
SELECT 
    emp_id,
    first_name,
    last_name,
    dept,
    emp_rating,
    MAX(emp_rating) OVER (PARTITION BY dept) AS max_rating_in_department,
    AVG(emp_rating) OVER (PARTITION BY dept) AS avg_rating_in_department,
    DENSE_RANK() OVER (PARTITION BY dept ORDER BY emp_rating DESC) AS dept_rating_rank
FROM emp_record_table
ORDER BY dept, dept_rating_rank, emp_id;

/* ============================================================
   6. REPORTING STRUCTURE / MANAGER ANALYSIS
   Purpose: identify managers and measure team size.
   ============================================================ */

-- 6.1 Employees who have a manager assigned
SELECT emp_id, first_name, last_name, manager_id
FROM emp_record_table
WHERE manager_id IS NOT NULL
ORDER BY manager_id, emp_id;

-- 6.2 Employees who manage at least one direct report
SELECT DISTINCT 
    m.emp_id,
    m.first_name,
    m.last_name
FROM emp_record_table m
JOIN emp_record_table r
    ON m.emp_id = r.manager_id
ORDER BY m.emp_id;

-- 6.3 Managers with count of direct reports
SELECT 
    m.emp_id AS manager_emp_id,
    m.first_name,
    m.last_name,
    COUNT(r.emp_id) AS direct_reports
FROM emp_record_table m
JOIN emp_record_table r
    ON m.emp_id = r.manager_id
GROUP BY m.emp_id, m.first_name, m.last_name
ORDER BY direct_reports DESC, manager_emp_id;

-- 6.4 Reporting structure with manager name
SELECT 
    r.emp_id,
    CONCAT(r.first_name, ' ', r.last_name) AS employee_name,
    r.dept,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    m.dept AS manager_department
FROM emp_record_table r
LEFT JOIN emp_record_table m
    ON r.manager_id = m.emp_id
ORDER BY manager_name, employee_name;

/* ============================================================
   7. SALARY ANALYSIS
   Purpose: compare compensation across roles, countries, and regions.
   ============================================================ */

-- 7.1 Salary range by role
SELECT 
    role,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    ROUND(AVG(salary), 2) AS avg_salary,
    COUNT(*) AS employee_count
FROM emp_record_table
GROUP BY role
ORDER BY avg_salary DESC;

-- 7.2 Salary-based bonus estimation using rating as multiplier
SELECT 
    emp_id,
    first_name,
    last_name,
    emp_rating,
    salary,
    ROUND(salary * 0.05 * emp_rating, 2) AS bonus_estimate
FROM emp_record_table
ORDER BY bonus_estimate DESC, emp_id;

-- 7.3 High-salary employees (> 6000) by country
CREATE OR REPLACE VIEW emp_countries AS
SELECT first_name, last_name, salary, country
FROM emp_record_table
WHERE salary > 6000;

SELECT *
FROM emp_countries
ORDER BY country, salary DESC;

SELECT country, COUNT(*) AS employees_above_6000
FROM emp_record_table
WHERE salary > 6000
GROUP BY country
ORDER BY employees_above_6000 DESC, country;

-- 7.4 Average salary by continent and country
SELECT 
    continent,
    country,
    ROUND(AVG(salary), 2) AS average_salary
FROM emp_record_table
GROUP BY continent, country
ORDER BY continent, average_salary DESC;

-- 7.5 Employee salary benchmark versus country and continent averages
SELECT 
    first_name,
    last_name,
    continent,
    country,
    salary,
    ROUND(AVG(salary) OVER (PARTITION BY continent), 2) AS avg_salary_by_continent,
    COUNT(*) OVER (PARTITION BY continent) AS employees_in_continent,
    ROUND(AVG(salary) OVER (PARTITION BY country), 2) AS avg_salary_by_country,
    COUNT(*) OVER (PARTITION BY country) AS employees_in_country
FROM emp_record_table
ORDER BY continent, country, salary DESC;

/* ============================================================
   8. EXPERIENCE ANALYSIS
   Purpose: understand seniority distribution and rank employees by experience.
   ============================================================ */

-- 8.1 Experience ranking across the workforce
SELECT 
    emp_id,
    first_name,
    last_name,
    exp,
    RANK() OVER (ORDER BY exp DESC) AS experience_rank
FROM emp_record_table
ORDER BY experience_rank, emp_id;

-- 8.2 Employees with more than 10 years of experience
SELECT emp_id, first_name, last_name, exp
FROM emp_record_table
WHERE exp > 10
ORDER BY exp DESC, emp_id;

-- 8.3 Experience segmentation with CASE logic
SELECT 
    emp_id,
    first_name,
    last_name,
    exp,
    CASE
        WHEN exp <= 2 THEN 'Junior'
        WHEN exp BETWEEN 3 AND 5 THEN 'Associate'
        WHEN exp BETWEEN 6 AND 10 THEN 'Senior'
        WHEN exp > 10 THEN 'Leadership Track'
        ELSE 'Unclassified'
    END AS experience_band
FROM emp_record_table
ORDER BY exp DESC, emp_id;

-- 8.4 Experience and performance combined view
WITH experience_performance AS (
    SELECT 
        emp_id,
        first_name,
        last_name,
        dept,
        exp,
        emp_rating,
        CASE
            WHEN exp <= 2 THEN 'Junior'
            WHEN exp BETWEEN 3 AND 5 THEN 'Associate'
            WHEN exp BETWEEN 6 AND 10 THEN 'Senior'
            WHEN exp > 10 THEN 'Leadership Track'
            ELSE 'Unclassified'
        END AS experience_band
    FROM emp_record_table
)
SELECT 
    dept,
    experience_band,
    COUNT(*) AS employee_count,
    ROUND(AVG(emp_rating), 2) AS avg_rating,
    ROUND(AVG(exp), 2) AS avg_experience
FROM experience_performance
GROUP BY dept, experience_band
ORDER BY dept, avg_experience DESC;

/* ============================================================
   9. ADVANCED BUSINESS QUERIES
   Purpose: show SQL skills using CTEs and window functions.
   ============================================================ */

-- 9.1 Top-rated employees within each department
WITH department_rankings AS (
    SELECT 
        emp_id,
        first_name,
        last_name,
        dept,
        emp_rating,
        DENSE_RANK() OVER (PARTITION BY dept ORDER BY emp_rating DESC) AS dept_rank
    FROM emp_record_table
)
SELECT emp_id, first_name, last_name, dept, emp_rating, dept_rank
FROM department_rankings
WHERE dept_rank = 1
ORDER BY dept, emp_id;

-- 9.2 Employees earning above their department average
WITH department_salary_benchmark AS (
    SELECT 
        emp_id,
        first_name,
        last_name,
        dept,
        salary,
        AVG(salary) OVER (PARTITION BY dept) AS dept_avg_salary
    FROM emp_record_table
)
SELECT 
    emp_id,
    first_name,
    last_name,
    dept,
    salary,
    ROUND(dept_avg_salary, 2) AS dept_avg_salary,
    ROUND(salary - dept_avg_salary, 2) AS salary_vs_dept_avg
FROM department_salary_benchmark
WHERE salary > dept_avg_salary
ORDER BY dept, salary_vs_dept_avg DESC;

-- 9.3 Managers whose teams have above-average performance
WITH manager_team_rating AS (
    SELECT 
        m.emp_id AS manager_emp_id,
        CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
        ROUND(AVG(r.emp_rating), 2) AS team_avg_rating,
        COUNT(r.emp_id) AS direct_reports
    FROM emp_record_table m
    JOIN emp_record_table r
        ON m.emp_id = r.manager_id
    GROUP BY m.emp_id, manager_name
),
company_rating AS (
    SELECT AVG(emp_rating) AS overall_avg_rating
    FROM emp_record_table
)
SELECT 
    mtr.manager_emp_id,
    mtr.manager_name,
    mtr.team_avg_rating,
    mtr.direct_reports,
    ROUND(cr.overall_avg_rating, 2) AS company_avg_rating
FROM manager_team_rating mtr
CROSS JOIN company_rating cr
WHERE mtr.team_avg_rating > cr.overall_avg_rating
ORDER BY mtr.team_avg_rating DESC, mtr.direct_reports DESC;


/* ============================================================
   10. REUSABLE DATABASE OBJECTS
   Purpose: demonstrate procedural SQL and business-rule logic.
   ============================================================ */

-- 10.1 Stored procedure to return employees above a chosen experience threshold
DROP PROCEDURE IF EXISTS employee_details_by_experience;
DELIMITER $$
CREATE PROCEDURE employee_details_by_experience(IN min_experience INT)
BEGIN
    SELECT emp_id, first_name, last_name, exp, dept, role
    FROM emp_record_table
    WHERE exp > min_experience
    ORDER BY exp DESC, emp_id;
END $$
DELIMITER ;

CALL employee_details_by_experience(5);

-- 10.2 Function to map experience to expected seniority profile
DROP FUNCTION IF EXISTS standard_profile;
DELIMITER $$
CREATE FUNCTION standard_profile(exp INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    RETURN CASE
        WHEN exp <= 2 THEN 'JUNIOR DATA SCIENTIST'
        WHEN exp > 2 AND exp <= 5 THEN 'ASSOCIATE DATA SCIENTIST'
        WHEN exp > 5 AND exp <= 10 THEN 'SENIOR DATA SCIENTIST'
        WHEN exp > 10 AND exp <= 12 THEN 'LEAD DATA SCIENTIST'
        WHEN exp > 12 AND exp <= 16 THEN 'MANAGER'
        ELSE 'NOT DEFINED'
    END;
END $$
DELIMITER ;

SELECT 
    emp_id,
    exp,
    role,
    standard_profile(exp) AS standard_role,
    CASE
        WHEN role = standard_profile(exp) THEN 'match'
        ELSE 'not match'
    END AS role_alignment
FROM data_science_team;

/* ============================================================
   11. PERFORMANCE OPTIMIZATION
   Purpose: demonstrate indexing on a searched text field.
   ============================================================ */

SHOW INDEX FROM emp_record_table;

SELECT first_name
FROM emp_record_table
WHERE first_name = 'Eric';

CREATE INDEX index_first_name ON emp_record_table(first_name(25));

SHOW INDEX FROM emp_record_table;
DESCRIBE emp_record_table;

EXPLAIN SELECT first_name
FROM emp_record_table
WHERE first_name = 'Eric';

/* ============================================================
   12. FINAL SUMMARY QUERIES FOR REPORTING
   Purpose: quick summary outputs useful for dashboards or exports.
   ============================================================ */

-- 12.1 Department summary
SELECT 
    dept,
    COUNT(*) AS employee_count,
    ROUND(AVG(emp_rating), 2) AS avg_rating,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(AVG(exp), 2) AS avg_experience
FROM emp_record_table
GROUP BY dept
ORDER BY avg_rating DESC, avg_salary DESC;

-- 12.2 Country summary
SELECT 
    country,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS avg_salary,
    ROUND(AVG(emp_rating), 2) AS avg_rating
FROM emp_record_table
GROUP BY country
ORDER BY employee_count DESC, avg_salary DESC;
