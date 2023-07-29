# Case study #4 - Data Bank

![4](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/0fb6cb92-2560-45cd-9784-8e901cd7ad22)

## Table of Contents
- [Context](#context)
- [Dataset](#dataset)
- [Questions and Answers](#questions-and-answers)
  - [A. Customer Nodes Exploration](#a-customer-nodes-exploration)
  - [B. Customer Transactions](#b-customer-transactions)
  - [C. Data Allocation Challenge](c-data-allocation-challenge)
  - [D. Extra Challenge](d-extra-challenge)
***
### Context

There is a new innovation in the financial industry called Neo-Banks: new aged digital only banks without physical branches.

Danny thought that there should be some sort of intersection between these new age banks, cryptocurrency and the data world…so he decides to launch a new initiative - Data Bank!

This case study is all about calculating metrics, growth and helping the business analyse their data in a smart way to better forecast and plan for their future developments!
***

### Dataset
#### Entity Relationship Diagram

<img width="544" alt="case-study-4-erd" src="https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/5354403e-1387-45cc-b34b-548e7899fbb1">

***
### Example Datasets

- Table 1: Regions

| region_id | region_name |
| --------- | ----------- |
| 1         | Africa      |
| 2         | America     |
| 3         | Asia        |
| 4         | Europe      |
| 5         | Oceania     |

- Table 2: Customer Nodes

| customer_id | region_id | node_id | start_date | end_date   |
| ----------- | --------- | ------- | ---------- | ---------- |
| 1           | 3         | 4       | 2020-01-02 | 2020-01-03 |
| 2           | 3         | 5       | 2020-01-03 | 2020-01-17 |
| 3           | 5         | 4       | 2020-01-27 | 2020-02-18 |
| 4           | 5         | 4       | 2020-01-07 | 2020-01-19 |
| 5           | 3         | 3       | 2020-01-15 | 2020-01-23 |
| 6           | 1         | 1       | 2020-01-11 | 2020-02-06 |
| 7           | 2         | 5       | 2020-01-20 | 2020-02-04 |
| 8           | 1         | 2       | 2020-01-15 | 2020-01-28 |
| 9           | 4         | 5       | 2020-01-21 | 2020-01-25 |
| 10          | 3         | 4       | 2020-01-13 | 2020-01-14 |

- Table 3: Customer Transactions

| customer_id | txn_date   | txn_type | txn_amount |
| ----------- | ---------- | -------- | ---------- |
| 429         | 2020-01-21 | deposit  | 82         |
| 155         | 2020-01-10 | deposit  | 712        |
| 398         | 2020-01-01 | deposit  | 196        |
| 255         | 2020-01-14 | deposit  | 563        |
| 185         | 2020-01-29 | deposit  | 626        |
| 309         | 2020-01-13 | deposit  | 995        |
| 312         | 2020-01-20 | deposit  | 485        |
| 376         | 2020-01-03 | deposit  | 706        |
| 188         | 2020-01-13 | deposit  | 601        |
| 138         | 2020-01-11 | deposit  | 520        |
***
### Questions and Answers
#### A. Customer Nodes Exploration

**1. How many unique nodes are there on the Data Bank system?**

````sql
SET search_path = data_bank;
SELECT
	COUNT(distinct (node_id, region_id)) node_num
FROM customer_nodes;
````

*Answer:*

| **node_num** |
| ------------ |
| 25           |
***
**2. What is the number of nodes per region?**

````sql
SELECT 
	region_name,
	COUNT(distinct node_id) node_num
FROM 
	customer_nodes c
	JOIN regions r ON c.region_id = r.region_id
GROUP BY 1;
````

*Answer:*

| **region_name** | **node_num** |
| --------------- | ------------ |
| **Africa**      | 5            |
| **America**     | 5            |
| **Asia**        | 5            |
| **Australia**   | 5            |
| **Europe**      | 5            |
***
**3. How many customers are allocated to each region?**

````sql
SELECT
	region_name,
	COUNT(distinct customer_id) cus_num
FROM 
	customer_nodes c
	JOIN regions r ON c.region_id = r.region_id
GROUP BY 1;
````

*Answer:*

| **region_name** | **cus_num** |
| --------------- | ----------- |
| **Africa**      | 102         |
| **America**     | 105         |
| **Asia**        | 95          |
| **Australia**   | 110         |
| **Europe**      | 88          |
***
**4. How many days on average are customers reallocated to a different node?**

- Firstly we create reallocation table with a lag column that shows every customer's previous start date. Then we calculate the different between periods by taking start_date column minus lag column, located in "different" column.

````sql
DROP TABLE IF EXISTS reallocation;
CREATE TEMP TABLE reallocation AS(
	SELECT
		customer_id,
		region_id,
		node_id,
		start_date,
		LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date),
		start_date - LAG(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS different
	FROM customer_nodes
);
````
-- We can easily see the average number of days that customers are reallocated to a different node is the average of "different"

````sql
SELECT
	ROUND(AVG(different),0) avg_rellocation_days
FROM
	reallocation;
````
- Or we could also use this way:

````sql
SELECT 
	ROUND(AVG(end_date - start_date + 1), 0) avg_rellocation_days 
FROM customer_nodes
WHERE end_date != '9999-12-31';
````

*Answer:*

| **avg_rellocation_days** |
| ------------------------ |
| 16                       |
***
**5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?**

````sql
SELECT
	region_id,
	PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY different) AS median,
	PERCENTILE_DISC(0.8) WITHIN GROUP(ORDER BY different) AS percentile_80,
	PERCENTILE_DISC(0.95) WITHIN GROUP(ORDER BY different) AS percentile_95
FROM
	reallocation
GROUP BY region_id;
````

*Answer:*

| **region_id** | **median** | **percentile_80** | **percentile_95** |
| ------------- | ---------- | ----------------- | ----------------- |
| **1**         | 16         | 24                | 29                |
| **2**         | 16         | 24                | 29                |
| **3**         | 16         | 25                | 29                |
| **4**         | 16         | 24                | 29                |
| **5**         | 16         | 25                | 29                |
***
#### B. Customer Transactions

**1. What is the unique count and total amount for each transaction type?**

````sql
SELECT
	txn_type,
	COUNT(*) txn_count,
	SUM(txn_amount) total_amount
FROM customer_transactions
GROUP BY 1;
````

*Answer:*

| **txn_type**   | **txn_count** | **total_amount** |
| -------------- | ------------- | ---------------- |
| **purchase**   | 1617          | 806537           |
| **withdrawal** | 1580          | 793003           |
| **deposit**    | 2671          | 1359168          |
***
**2. What is the average total historical deposit counts and amounts for all customers?**

````sql
SELECT
	ROUND(AVG(total_deposit_count),2) avg_deposit_count,
	ROUND(AVG(total_deposit_amount),2) avg_deposit_amount
FROM
	(
		SELECT
			customer_id,
			COUNT(*) total_deposit_count,
			SUM(txn_amount) total_deposit_amount
		FROM customer_transactions
		WHERE txn_type = 'deposit'
		GROUP BY 1
		ORDER BY 1
	) AS sub
````

*Answer:*

| **avg_deposit_count** | **avg_deposit_amount** |
| --------------------- | ---------------------- |
| **5.34**              | 2718.34                |
***
**3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?**

````sql
WITH 
	cte AS(
		SELECT
			*,
			CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END deposit,
			CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END purchase,
			CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END withdrawal
		FROM customer_transactions
		),
	cte1 AS(
		SELECT
			TO_CHAR(txn_date, 'Month') month_name,
			customer_id,
			SUM(deposit) deposit_count,
			SUM(purchase) purchase_count,
			SUM(withdrawal) withdrawal_count
		FROM cte
		GROUP BY 1,2
		)
SELECT
	month_name,
	COUNT(customer_id) customer_count
FROM cte1
WHERE deposit_count > 1 AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY 1;
````

*Answer:*

| **month_name** | **customer_count** |
| -------------- | ------------------ |
| **April**      | 50                 |
| **February**   | 108                |
| **January**    | 115                |
| **March**      | 113                |
***
**4. What is the closing balance for each customer at the end of the month?**

````sql
-- Step 1: Create a fix_amount column which define 'deposit' is adding amount, 'purchase' and 'withdrawal' are subtracting amount.

WITH sub AS(
	SELECT
		*,
		CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 - txn_amount END AS fix_amount
	FROM customer_transactions
	)

-- Step 2: use window function to sum over the fix_amount column, partition by customer_id and the month of txn_date

SELECT DISTINCT
	customer_id,
	DATE_PART('month', txn_date) end_of_month,
	SUM(fix_amount) OVER(PARTITION BY customer_id, DATE_TRUNC('month', txn_date)) closing_balance
FROM sub
ORDER BY 1,2;
````
