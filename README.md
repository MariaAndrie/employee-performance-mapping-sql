# Employee Performance Mapping (SQL Project)

## Overview
This project analyses employee performance, salary structure, reporting hierarchy, and workforce distribution. It demonstrates how SQL can be used not only for querying data, but also for solving practical business problems and generating actionable insights.

## Objectives
The main goal of this project is to explore employee data and answer key business questions related to:

- data quality validation and cleanup  
- performance distribution across the organization  
- salary differences between departments and roles  
- reporting structure and manager relationships  
- experience-based segmentation  

## Dataset
The analysis is based on the `emp_record_table`.

Before performing the analysis, a data quality check was conducted to identify potential issues, including:

- duplicate employee IDs  
- missing or null values  
- invalid salary or experience values  
- inconsistent text formatting  
- missing or incorrect manager references  

## SQL Skills Demonstrated
This project demonstrates the use of:

- data filtering and sorting  
- aggregations and `GROUP BY`  
- `CASE WHEN` logic  
- Common Table Expressions (CTE)  
- window functions (`OVER`, `PARTITION BY`)  
- ranking functions  
- data cleaning and validation techniques  
- structured, business-oriented query design  

## Business Questions
The project explores several practical questions:

- Is the employee dataset complete and usable for analysis?
- How are employees distributed by department, rating, geography, and experience?
- Which employees are low, medium, or high performers?
- Who are the managers and how many direct reports do they have?
- How do salary levels vary across roles, departments, countries, and continents?
- How does experience relate to performance and employee segmentation? 

## Key Insights

- Employees with higher experience levels tend to have better performance ratings, indicating a positive relationship between experience and productivity.

- Salary levels vary significantly across departments, suggesting differences in role specialization and compensation strategies.

- High-performing employees are unevenly distributed, which may indicate differences in team effectiveness or management quality.

- Some employees earn significantly above their departmental average, highlighting potential senior roles or compensation inconsistencies.

- Data quality checks revealed missing manager assignments and inconsistencies that could affect reporting accuracy.

- Salary distribution differs across groups, indicating structural variation in compensation.

- Certain managers oversee a large number of employees, which may impact team performance and management effectiveness.

## Business Impact

The analysis can support:

- HR decision-making on salary adjustments and compensation strategy  
- identification of high-performing teams and employees  
- improvement of organizational structure and reporting lines  
- detection and resolution of data quality issues  
- more reliable internal reporting and analytics  

## Project Structure

```
employee-performance-mapping-sql/
├── README.md
└── sql/
    └── employee_performance_mapping_portfolio.sql
```


## Notes
This repository is intended as a portfolio project demonstrating practical SQL skills in a structured business context. It focuses on combining data analysis with real-world problem-solving and clear communication of insights.
