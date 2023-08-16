# Case Study #5 - Data Mart

![5](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/86c7dac9-775a-4d2d-a0ee-78831b922d26)

## Table of Contents:
* [Context](#context)
* [Dataset](#dataset)
* [Questions and Answers](#questions-and-answers)
***
### Context
Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce - Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.
***
### Dataset
#### Entity Relationship Diagram

<img width="234" alt="ERD Case Study 5" src="https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/562a107e-ed67-4467-9025-d13e7d7b781d">

#### Example Datasets

| week_date | region        | platform | segment | customer_type | transactions | sales      |
| --------- | ------------- | -------- | ------- | ------------- | ------------ | ---------- |
| 9/9/20    | OCEANIA       | Shopify  | C3      | New           | 610          | 110033.89  |
| 29/7/20   | AFRICA        | Retail   | C1      | New           | 110692       | 3053771.19 |
| 22/7/20   | EUROPE        | Shopify  | C4      | Existing      | 24           | 8101.54    |
| 13/5/20   | AFRICA        | Shopify  | null    | Guest         | 5287         | 1003301.37 |
| 24/7/19   | ASIA          | Retail   | C1      | New           | 127342       | 3151780.41 |
| 10/7/19   | CANADA        | Shopify  | F3      | New           | 51           | 8844.93    |
| 26/6/19   | OCEANIA       | Retail   | C3      | New           | 152921       | 5551385.36 |
| 29/5/19   | SOUTH AMERICA | Shopify  | null    | New           | 53           | 10056.2    |
| 22/8/18   | AFRICA        | Retail   | null    | Existing      | 31721        | 1718863.58 |
| 25/7/18   | SOUTH AMERICA | Retail   | null    | New           | 2136         | 81757.91   |
***
### Questions and Answers
#### A. Data Cleaning Steps

````sql
SET search_path = data_mart;
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales AS(
	SELECT
		TO_DATE(week_date, 'DD/MM/YY') week_date,
		TO_CHAR(TO_DATE(week_date, 'DD/MM/YY'), 'WW')::numeric week_number,
		TO_CHAR(TO_DATE(week_date, 'DD/MM/YY'), 'MM')::numeric month_number,
		TO_CHAR(TO_DATE(week_date, 'DD/MM/YY'), 'YYYY')::numeric calendar_year,
		region,
		platform,
		CASE WHEN segment LIKE 'null' THEN 'unknown' ELSE segment END AS segment,
		CASE
			WHEN segment LIKE '%1' THEN 'Young Adults'
			WHEN segment LIKE '%2' THEN 'Middle Aged'
			WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
			ELSE 'unknown'
		END AS age_band,
		CASE
			WHEN segment LIKE 'C%' THEN 'Couples' 
			WHEN segment LIKE 'F%' THEN 'Families'
			ELSE 'unknown'
		END AS demographic,
		customer_type,
		transactions,
		sales,
		ROUND(sales::numeric/transactions,2) avg_transaction
	FROM weekly_sales
);
````
***
#### B. Data Exploration
**1. What day of the week is used for each week_date value?**

````sql
SELECT
	DISTINCT TO_CHAR(week_date,'Day') day_of_week
FROM clean_weekly_sales;
````

*Answer:*

| **day_of_week** |
| --------------- |
| Monday          |
***
**2. What range of week numbers are missing from the dataset?**

````sql
WITH 
	full_week_number AS(
		SELECT GENERATE_SERIES(1,52) full_week
	),
	sales_week_number AS(
		SELECT
			DISTINCT week_number 
		FROM clean_weekly_sales
		ORDER BY 1
	)
SELECT f.full_week missing_week_number
FROM full_week_number f
	LEFT JOIN sales_week_number s ON f.full_week = s.week_number
WHERE s.week_number IS NULL;
````

*Answer:*

| **missing_week_number** |
| ----------------------- |
| 1                       |
| 2                       |
| 3                       |
| 4                       |
| 5                       |
| 6                       |
| 7                       |
| 8                       |
| 9                       |
| 10                      |
| 11                      |
| 37                      |
| 38                      |
| 39                      |
| 40                      |
| 41                      |
| 42                      |
| 43                      |
| 44                      |
| 45                      |
| 46                      |
| 47                      |
| 48                      |
| 49                      |
| 50                      |
| 51                      |
| 52                      |
***
**3. How many total transactions were there for each year in the dataset?**

````sql
SELECT
	calendar_year,
	SUM(transactions) total_transations
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **calendar_year** | **total_transations** |
| ----------------- | --------------------- |
| **2018**          | 346406460             |
| **2019**          | 365639285             |
| **2020**          | 375813651             |
***
**4. What is the total sales for each region for each month?**

````sql
SELECT
	region,
	DATE_TRUNC('MONTH', week_date)::DATE sale_month,
	SUM(sales) total_sales
FROM clean_weekly_sales
GROUP BY 1,2
ORDER BY 1,2;
````

*Answer: (the first 10 rows)*

| **region** | **sale_month** | **total_sales** |
| ---------- | -------------- | --------------- |
| **AFRICA** | 2018-03-01     | 130542213       |
| **AFRICA** | 2018-04-01     | 650194751       |
| **AFRICA** | 2018-05-01     | 522814997       |
| **AFRICA** | 2018-06-01     | 519127094       |
| **AFRICA** | 2018-07-01     | 674135866       |
| **AFRICA** | 2018-08-01     | 539077371       |
| **AFRICA** | 2018-09-01     | 135084533       |
| **AFRICA** | 2019-03-01     | 141619349       |
| **AFRICA** | 2019-04-01     | 700447301       |
| **AFRICA** | 2019-05-01     | 553828220       |
***
**5. What is the total count of transactions for each platform?**

````sql
SELECT
	platform,
	SUM(transactions) transactions_count
FROM clean_weekly_sales
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **platform** | **transactions_count** |
| ------------ | ---------------------- |
| **Retail**   | 1081934227             |
| **Shopify**  | 5925169                |
***
**6. What is the percentage of sales for Retail vs Shopify for each month?**

````sql
WITH 
	total_sales AS(
		SELECT
			DATE_TRUNC('MONTH', week_date)::DATE sale_month,
			SUM(sales) total_sales
		FROM clean_weekly_sales
		GROUP BY 1
		ORDER BY 1
	),
	flatform_sales AS(
		SELECT
			DATE_TRUNC('MONTH', week_date)::DATE sale_month,
			platform,
			SUM(sales) sales
		FROM clean_weekly_sales 
		GROUP BY 1,2
	)
SELECT 
	t.sale_month,
	platform,
	ROUND((sales*100)::numeric/total_sales,2) percentage
FROM total_sales t
	JOIN flatform_sales f ON t.sale_month = f.sale_month
ORDER BY 1,2;
````

*Answer:*

| **sale_month** | **platform** | **percentage** |
| -------------- | ------------ | -------------- |
| **2018-03-01** | Retail       | 97.92          |
| **2018-03-01** | Shopify      | 2.08           |
| **2018-04-01** | Retail       | 97.93          |
| **2018-04-01** | Shopify      | 2.07           |
| **2018-05-01** | Retail       | 97.73          |
| **2018-05-01** | Shopify      | 2.27           |
| **2018-06-01** | Retail       | 97.76          |
| **2018-06-01** | Shopify      | 2.24           |
| **2018-07-01** | Retail       | 97.75          |
| **2018-07-01** | Shopify      | 2.25           |
| **2018-08-01** | Retail       | 97.71          |
| **2018-08-01** | Shopify      | 2.29           |
| **2018-09-01** | Retail       | 97.68          |
| **2018-09-01** | Shopify      | 2.32           |
| **2019-03-01** | Retail       | 97.71          |
| **2019-03-01** | Shopify      | 2.29           |
| **2019-04-01** | Retail       | 97.80          |
| **2019-04-01** | Shopify      | 2.20           |
| **2019-05-01** | Retail       | 97.52          |
| **2019-05-01** | Shopify      | 2.48           |
| **2019-06-01** | Retail       | 97.42          |
| **2019-06-01** | Shopify      | 2.58           |
| **2019-07-01** | Retail       | 97.35          |
| **2019-07-01** | Shopify      | 2.65           |
| **2019-08-01** | Retail       | 97.21          |
| **2019-08-01** | Shopify      | 2.79           |
| **2019-09-01** | Retail       | 97.09          |
| **2019-09-01** | Shopify      | 2.91           |
| **2020-03-01** | Retail       | 97.30          |
| **2020-03-01** | Shopify      | 2.70           |
| **2020-04-01** | Retail       | 96.96          |
| **2020-04-01** | Shopify      | 3.04           |
| **2020-05-01** | Retail       | 96.71          |
| **2020-05-01** | Shopify      | 3.29           |
| **2020-06-01** | Retail       | 96.80          |
| **2020-06-01** | Shopify      | 3.20           |
| **2020-07-01** | Retail       | 96.67          |
| **2020-07-01** | Shopify      | 3.33           |
| **2020-08-01** | Retail       | 96.51          |
| **2020-08-01** | Shopify      | 3.49           |
***
**7. What is the percentage of sales by demographic for each year in the dataset?**

````sql
WITH 
	total_sales AS(
		SELECT
			calendar_year,
			SUM(sales) total_sales
		FROM clean_weekly_sales
		GROUP BY 1
		ORDER BY 1
	),
	demographic_sales AS(
		SELECT
			calendar_year,
			demographic,
			SUM(sales) sales
		FROM clean_weekly_sales 
		GROUP BY 1,2
	)
SELECT 
	t.calendar_year,
	demographic,
	sales,
	total_sales,
	ROUND((sales*100)::numeric/total_sales,2) percentage
FROM total_sales t
	JOIN demographic_sales d ON t.calendar_year = d.calendar_year
ORDER BY 1,2;
````

*Answer:*

| **calendar_year** | **demographic** | **sales**  | **total_sales** | **percentage** |
| ----------------- | --------------- | ---------- | --------------- | -------------- |
| **2018**          | Couples         | 3402388688 | 12897380827     | 26.38          |
| **2018**          | Families        | 4125558033 | 12897380827     | 31.99          |
| **2018**          | unknown         | 5369434106 | 12897380827     | 41.63          |
| **2019**          | Couples         | 3749251935 | 13746032500     | 27.28          |
| **2019**          | Families        | 4463918344 | 13746032500     | 32.47          |
| **2019**          | unknown         | 5532862221 | 13746032500     | 40.25          |
| **2020**          | Couples         | 4049566928 | 14100220900     | 28.72          |
| **2020**          | Families        | 4614338065 | 14100220900     | 32.73          |
| **2020**          | unknown         | 5436315907 | 14100220900     | 38.55          |
***
**8. Which age_band and demographic values contribute the most to Retail sales?**

````sql
SELECT
	platform,
	age_band,
	demographic,
	SUM(sales) total_sales
FROM clean_weekly_sales
GROUP BY 1,2,3
ORDER BY 3 DESC
LIMIT 1;
````

*Answer:*

| **platform** | **age_band** | **demographic** | **total_sales** |
| ------------ | ------------ | --------------- | --------------- |
| **Retail**   | unknown      | unknown         | 16067285533     |
***
**9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?**

We can not use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify.

````sql
SELECT
	calendar_year,
	platform,
	ROUND(SUM(sales)::numeric/SUM(transactions),2) avg_tran_size
FROM clean_weekly_sales
GROUP BY 1,2
ORDER BY 1,2;
````

*Answer:*

| **calendar_year** | **platform** | **avg_tran_size** |
| ----------------- | ------------ | ----------------- |
| **2018**          | Retail       | 36.56             |
| **2018**          | Shopify      | 192.48            |
| **2019**          | Retail       | 36.83             |
| **2019**          | Shopify      | 183.36            |
| **2020**          | Retail       | 36.56             |
| **2020**          | Shopify      | 179.03            |
***
#### C. Before & After Analysis
**1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?**

````sql
-- Firstly, we create the sub_table includes sales of 4 weeks before and 4 weeks after '2020-06-15'.

WITH 
	sub_table AS (
		SELECT
			week_date,
			CASE
				WHEN week_date < '2020-06-15' THEN sales ELSE 0 END AS sales_before,
			CASE 
				WHEN week_date >= '2020-06-15' THEN sales ELSE 0 END AS sales_after
		FROM clean_weekly_sales
		WHERE week_date BETWEEN ('2020-06-15'::DATE - interval'4 weeks') AND ('2020-06-15'::DATE + interval'3 week')
		ORDER BY 1
	)
-- Then, we easily calculate the total sales for every period asked.

SELECT
	SUM(sales_before) before_change,
	SUM(sales_after) after_change,
	SUM(sales_after) - SUM(sales_before) change_sales_value,
	ROUND(100*(SUM(sales_after) - SUM(sales_before))::numeric/SUM(sales_before),2) change_sales_percentage
FROM sub_table;
````

*Answer:*

| **before_change** | **after_change** | **change_sales_value** | **change_sales_percentage** |
| ----------------- | ---------------- | ---------------------- | --------------------------- |
| **2345878357**    | 2318994169       | \-26884188             | \-1.15                      |
***
**2. What about the entire 12 weeks before and after?**

````sql
WITH 
	sub_table AS (
		SELECT
			week_date,
			CASE
				WHEN week_date < '2020-06-15' THEN sales ELSE 0 END AS sales_before,
			CASE 
				WHEN week_date >= '2020-06-15' THEN sales ELSE 0 END AS sales_after
		FROM clean_weekly_sales
		WHERE week_date BETWEEN ('2020-06-15'::DATE - interval'12 weeks') AND ('2020-06-15'::DATE + interval'11 week')
		ORDER BY 1
	)
SELECT
	SUM(sales_before) before_change,
	SUM(sales_after) after_change,
	SUM(sales_after) - SUM(sales_before) change_sales_value,
	ROUND(100*(SUM(sales_after) - SUM(sales_before))::numeric/SUM(sales_before),2) change_sales_percentage
FROM sub_table;
````

*Answer:*

| **before_change** | **after_change** | **change_sales_value** | **change_sales_percentage** |
| ----------------- | ---------------- | ---------------------- | --------------------------- |
| **7126273147**    | 6973947753       | \-152325394            | \-2.14                      |
***
