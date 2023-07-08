# Case Study #3 - Foodie-Fi

![3](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/ef4609d1-9b87-434f-a6e7-8aa0b46b5e34)

## Table of Contents
- [Context](#context)
- [Dataset](#dataset)
- [Questions and Answers](#questions-and-answers)
  - [B. Data Analysis Questions](#b-data-analysis-questions)
  - [C. Challenge Payment Question](#c-challenge-payment-question)
***
### Context

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.
***
### Dataset

#### Entity Relationship Diagram

![case-study-3-erd](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/7efe5590-0351-4bc2-b189-9fde85fe83cc)

### Example Datasets

- Table 1: plans

| plan_id | plan_name     | price |
| ------- | ------------- | ----- |
| 0       | trial         | 0     |
| 1       | basic monthly | 9.90  |
| 2       | pro monthly   | 19.90 |
| 3       | pro annual    | 199   |
| 4       | churn         | null  |

- Table 2: subscriptions

| customer_id | plan_id | start_date |
| ----------- | ------- | ---------- |
| 1           | 0       | 2020-08-01 |
| 1           | 1       | 2020-08-08 |
| 2           | 0       | 2020-09-20 |
| 2           | 3       | 2020-09-27 |
| 11          | 0       | 2020-11-19 |
| 11          | 4       | 2020-11-26 |
| 13          | 0       | 2020-12-15 |
| 13          | 1       | 2020-12-22 |
| 13          | 2       | 2021-03-29 |
| 15          | 0       | 2020-03-17 |
| 15          | 2       | 2020-03-24 |
| 15          | 4       | 2020-04-29 |
| 16          | 0       | 2020-05-31 |
| 16          | 1       | 2020-06-07 |
| 16          | 3       | 2020-10-21 |
| 18          | 0       | 2020-07-06 |
| 18          | 2       | 2020-07-13 |
| 19          | 0       | 2020-06-22 |
| 19          | 2       | 2020-06-29 |
| 19          | 3       | 2020-08-29 |
***
### Questions and Answers
#### B. Data Analysis Questions

**1. How many customers has Foodie-Fi ever had?**

````sql
SET search_path = foodie_fi;
SELECT
	COUNT(DISTINCT customer_id) cus_num
FROM subscriptions;
````

*Answer:*

| **cus_num** |
| ----------- |
| 1000        |
***
**2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value**

````sql
SELECT
	COUNT(*) monthly_distribution,
	DATE_TRUNC('MONTH', start_date) start_date_of_month
FROM subscriptions
WHERE plan_id = 0
GROUP BY 2
ORDER BY 2;
````

*Answer:*

| **monthly_distribution** | **start_date_of_month** |
| ------------------------ | ----------------------- |
| **88**                   | 2020-01-01 00:00:00+07  |
| **68**                   | 2020-02-01 00:00:00+07  |
| **94**                   | 2020-03-01 00:00:00+07  |
| **81**                   | 2020-04-01 00:00:00+07  |
| **88**                   | 2020-05-01 00:00:00+07  |
| **79**                   | 2020-06-01 00:00:00+07  |
| **89**                   | 2020-07-01 00:00:00+07  |
| **88**                   | 2020-08-01 00:00:00+07  |
| **87**                   | 2020-09-01 00:00:00+07  |
| **79**                   | 2020-10-01 00:00:00+07  |
| **75**                   | 2020-11-01 00:00:00+07  |
| **84**                   | 2020-12-01 00:00:00+07  |
***
**3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name**

````sql
SELECT
	s.plan_id,
	plan_name,
	COUNT(*)
FROM 
	subscriptions s
	JOIN plans p ON s.plan_id = p.plan_id
WHERE 
	DATE_PART('year', start_date) > 2020
GROUP BY 1,2
ORDER BY 1;
````

*Answer:*

| **plan_id** | **plan_name** | **count** |
| ----------- | ------------- | --------- |
| **1**       | basic monthly | 8         |
| **2**       | pro monthly   | 60        |
| **3**       | pro annual    | 63        |
| **4**       | churn         | 71        |
***
**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**

````sql
SELECT 
	COUNT(customer_id) AS churned_num,
	ROUND(
		(100 * COUNT(*))::numeric /
		(	
			SELECT
			COUNT(DISTINCT customer_id) cus_num
		FROM subscriptions
		)
		, 1) AS churn_percentage
-- postgres auto round churn_percentage to 30 if I don't define (100 * COUNT(*) as numeric.		
FROM
	subscriptions
WHERE 
	plan_id = 4;
````

*Answer:*

| **churned_num** | **churn_percentage** |
| --------------- | -------------------- |
| **307**         | 30.7                 |

- For this question, we should try COUNT AND COUNT DISTINCT with those customer_id have plan_id = 4, as it might have a chance that 1 customer churned then re-subcribed our plan

````sql
SELECT 
	COUNT(DISTINCT customer_id) AS churned_num,
	ROUND(
		(100 * COUNT(*))::numeric /
		(	
			SELECT
			COUNT(DISTINCT customer_id) cus_num
		FROM subscriptions
		)
		, 1) AS churn_percentage	
FROM
	subscriptions
WHERE 
	plan_id = 4;
````

| **churned_num** | **churn_percentage** |
| --------------- | -------------------- |
| **307**         | 30.7                 |

- Run above queries with SELECT AND SELECT DISTINCT customer_id, we receive the same results, that means all customers have churned didn't resubcribe, and means every churned customer just has 1 time plan_id = 4
***
**5. How many customers have churned straight after their initial free trial?**

````sql
WITH tem_table AS(
	SELECT
		customer_id,
		COUNT(*)
	FROM
	(
		SELECT 
			*
		FROM
			subscriptions
		WHERE
			plan_id = 0 OR
			plan_id = 4
	) AS cte
	GROUP BY customer_id
	ORDER BY customer_id
)
SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS count_plan
FROM 
	subscriptions;
-- We could see customers who churned right after their trials will have plan_id = 4 with count_plan = 2.
-- So that from above table, we just need to choose customer with conditions: plan_id = 4 and count_plan = 2, then count them all, we will get the result.
WITH tem_table AS(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS count_plan
	FROM
		subscriptions
	)
SELECT 
	COUNT(*)
FROM
	tem_table
WHERE 
	plan_id = 4 AND
	count_plan = 2;
````

*Answer:*

| **count** |
| --------- |
| 92        |
***
**6. What is the number and percentage of customer plans after their initial free trial?**

````sql

WITH tem_table AS(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS count_plan
	FROM
		subscriptions
	)
SELECT *
FROM tem_table
WHERE count_plan = 1 OR count_plan = 2;
````
- I've tried to:
````sql
SELECT COUNT(*), COUNT(DISTINCT customer_id)
FROM tem_table
WHERE count_plan = 1 OR count_plan = 2;
````
- The results are 2000 and 1000, means there no customer just only has plan_id = 0 (new customer for example). They all have plan_id = 0, then at least 1 other plan_id. That means the count_plan = 2 for any customer is the plan after their initial trial.

````sql
WITH tem_table AS(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY plan_id) AS count_plan
	FROM
		subscriptions
	)
SELECT 
	plan_name,
	COUNT(*) plan_num,
	ROUND((100*COUNT(*)::numeric/
		(	
			SELECT
			COUNT(DISTINCT customer_id) cus_num
		FROM subscriptions
		))
		, 1) plan_percentage
		
FROM 
	tem_table t
	JOIN plans p ON t.plan_id = p.plan_id
WHERE 
	count_plan = 2
GROUP BY 1;
````

*Answer*

| **plan_name**     | **plan_num** | **plan_percentage** |
| ----------------- | ------------ | ------------------- |
| **basic monthly** | 546          | 54.6                |
| **churn**         | 92           | 9.2                 |
| **pro annual**    | 37           | 3.7                 |
| **pro monthly**   | 325          | 32.5                |
***
**7. What is the customer count of all 5 plan_name values at 2020-12-31?**

````sql
WITH latest_plan AS(
		SELECT
			customer_id,
			plan_id,
			RANK() OVER(PARTITION BY customer_id ORDER BY start_date DESC) ranking
		FROM subscriptions
		WHERE start_date <= '2020-12-31'
		ORDER BY 1
)

SELECT
	plan_name,
	COUNT(*) cus_num
FROM 
	latest_plan l
	JOIN plans p ON l.plan_id = p.plan_id
WHERE ranking = 1
GROUP BY 1;
````

*Answer:*

| **plan_name**     | **cus_num** |
| ----------------- | ----------- |
| **basic monthly** | 224         |
| **churn**         | 236         |
| **pro annual**    | 195         |
| **pro monthly**   | 326         |
| **trial**         | 19          |
***
**8. How many customers have upgraded to an annual plan in 2020?**

````sql
SELECT 
	COUNT(DISTINCT customer_id)
FROM subscriptions
WHERE 
	plan_id = 3
	AND DATE_PART('year', start_date) = 2020;
````

*Answer:*

| **count** |
| --------- |
| 195       |
***
**9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?**

````sql
WITH annual_customer AS(
	SELECT 
		customer_id
	FROM subscriptions
	WHERE 
		plan_id = 3
),
	lg AS(
	SELECT
		s.*,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id) rk,
		LAG(start_date) OVER(PARTITION BY s.customer_id) lag
	FROM
		subscriptions s
		JOIN annual_customer a ON s.customer_id = a.customer_id
	WHERE plan_id = 0 or plan_id = 3
)
SELECT
	ROUND(AVG(start_date - lag),2) AS avg_day_num
FROM lg
WHERE rk = 2;
````

*Answer:*

| **avg_day_num** |
| --------------- |
| 104.62          |
***
**10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)**
***
**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**

````sql
WITH sub AS(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date) row_num
	FROM subscriptions
	WHERE 
		DATE_PART('year', start_date) = 2020 AND
		(plan_id = 0 OR plan_id = 1 OR plan_id = 2)
)
-- As the row_num column is ordered by start_date, the customers downgraded from a pro monthly to a basic monthly plan
-- will have plan_id = 1 with the row_num = 3.
SELECT 
	COUNT(*)
FROM sub 
WHERE 
	plan_id = 1 AND
	row_num = 3;
````

*Answer:*

| **count** |
| --------- |
| 0         |

- Conclusion: there is no customers downgraded from a pro monthly to a basic monthly plan in 2020.



