# Case Study #2 - Pizza Runner

![2](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/71d97d06-c491-463b-a7a1-e35d8eeb1076)

## Table of Contents
* [Context](#context)
* [Dataset](#dataset)
* [Questions and Answer](#question-and-answer)
  * [Clean data](#clean-data)
  * [A. Pizza Metrics](#a.-pizza-metrics)
  * [B. Runner and Customer Experience](#b.-runner-and-customer-experience)
  * [C. Ingredient Optimisation](#c.-ingredient-optimisation)
  * [D. Pricing and Ratings](#d.-pricing-and-ratings)
***
### Context
Danny launched Pizza Runner and started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

Danny has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

If you want to learn more details about the case study, please visit [Case Study #2 - Pizza Runner](https://8weeksqlchallenge.com/case-study-2/)
***
### Dataset
#### Entity Relationship Diagram

<img width="797" alt="Ảnh màn hình 2023-07-06 lúc 16 41 47" src="https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/8f109f55-5f30-447c-9511-8e3e94fdab47">

#### Example datasets
* Table 1: runners

| runner_id | registration_date |
| --------- | ----------------- |
| 1         | 2021-01-01        |
| 2         | 2021-01-03        |
| 3         | 2021-01-08        |
| 4         | 2021-01-15        |

* Table 2: customer_orders

| order_id | customer_id | pizza_id | exclusions | extras | order_time          |
| -------- | ----------- | -------- | ---------- | ------ | ------------------- |
| 1        | 101         | 1        |            |        | 2021-01-01 18:05:02 |
| 2        | 101         | 1        |            |        | 2021-01-01 19:00:52 |
| 3        | 102         | 1        |            |        | 2021-01-02 23:51:23 |
| 3        | 102         | 2        |            | NaN    | 2021-01-02 23:51:23 |
| 4        | 103         | 1        | 4          |        | 2021-01-04 13:23:46 |
| 4        | 103         | 1        | 4          |        | 2021-01-04 13:23:46 |
| 4        | 103         | 2        | 4          |        | 2021-01-04 13:23:46 |
| 5        | 104         | 1        | null       | 1      | 2021-01-08 21:00:29 |
| 6        | 101         | 2        | null       | null   | 2021-01-08 21:03:13 |
| 7        | 105         | 2        | null       | 1      | 2021-01-08 21:20:29 |
| 8        | 102         | 1        | null       | null   | 2021-01-09 23:54:33 |
| 9        | 103         | 1        | 4          | 1, 5   | 2021-01-10 11:22:59 |
| 10       | 104         | 1        | null       | null   | 2021-01-11 18:34:49 |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2021-01-11 18:34:49 |

* Table 3: runner_orders

| order_id | runner_id | pickup_time         | distance | duration   | cancellation            |
| -------- | --------- | ------------------- | -------- | ---------- | ----------------------- |
| 1        | 1         | 2021-01-01 18:15:34 | 20km     | 32 minutes |                         |
| 2        | 1         | 2021-01-01 19:10:54 | 20km     | 27 minutes |                         |
| 3        | 1         | 2021-01-03 00:12:37 | 13.4km   | 20 mins    | NaN                     |
| 4        | 2         | 2021-01-04 13:53:03 | 23.4     | 40         | NaN                     |
| 5        | 3         | 2021-01-08 21:10:57 | 10       | 15         | NaN                     |
| 6        | 3         | null                | null     | null       | Restaurant Cancellation |
| 7        | 2         | 2020-01-08 21:30:45 | 25km     | 25mins     | null                    |
| 8        | 2         | 2020-01-10 00:15:02 | 23.4 km  | 15 minute  | null                    |
| 9        | 2         | null                | null     | null       | Customer Cancellation   |
| 10       | 1         | 2020-01-11 18:50:20 | 10km     | 10minutes  | null<br>                |

* Table 4: pizza_names

| pizza_id | pizza_name  |
| -------- | ----------- |
| 1        | Meat Lovers |
| 2        | Vegetarian  |

* Table 5: pizza_recipes

| pizza_id | toppings                |
| -------- | ----------------------- |
| 1        | 1, 2, 3, 4, 5, 6, 8, 10 |
| 2        | 4, 6, 7, 9, 11, 12      |

* Table 6: pizza_toppings

| topping_id | topping_name |
| ---------- | ------------ |
| 1          | Bacon        |
| 2          | BBQ Sauce    |
| 3          | Beef         |
| 4          | Cheese       |
| 5          | Chicken      |
| 6          | Mushrooms    |
| 7          | Onions       |
| 8          | Pepperoni    |
| 9          | Peppers      |
| 10         | Salami       |
| 11         | Tomatoes     |
| 12         | Tomato Sauce |

***
### Questions and Answers
#### Clean data

Take a look at the customer_orders table, we see the exclusions and extras columns will need to be cleaned up before using them in queries. We will create a temporary table named new_customer_orders with cleaned data.

````sql
SET search_path = pizza_runner;
DROP TABLE IF EXISTS new_customer_orders;
CREATE TEMP TABLE new_customer_orders AS (
	SELECT order_id, customer_id, pizza_id,
	CASE WHEN exclusions LIKE 'null' OR exclusions = '' THEN NULL
	ELSE exclusions END,
	CASE WHEN extras LIKE 'null' OR extras = '' THEN NULL
	ELSE extras END,
	order_time
	FROM customer_orders
);
````
Take a look at the new_customer_orders to see it's good to use now:

````sql
SELECT * FROM new_customer_orders;
````

Result:

| **order_id** | **customer_id** | **pizza_id** | **exclusions** | **extras** | **order_time**      |
| ------------ | --------------- | ------------ | -------------- | ---------- | ------------------- |
| **1**        | 101             | 1            |                |            | 2020-01-01 18:05:02 |
| **2**        | 101             | 1            |                |            | 2020-01-01 19:00:52 |
| **3**        | 102             | 1            |                |            | 2020-01-02 23:51:23 |
| **3**        | 102             | 2            |                |            | 2020-01-02 23:51:23 |
| **4**        | 103             | 1            | 4              |            | 2020-01-04 13:23:46 |
| **4**        | 103             | 1            | 4              |            | 2020-01-04 13:23:46 |
| **4**        | 103             | 2            | 4              |            | 2020-01-04 13:23:46 |
| **5**        | 104             | 1            |                | 1          | 2020-01-08 21:00:29 |
| **6**        | 101             | 2            |                |            | 2020-01-08 21:03:13 |
| **7**        | 105             | 2            |                | 1          | 2020-01-08 21:20:29 |
| **8**        | 102             | 1            |                |            | 2020-01-09 23:54:33 |
| **9**        | 103             | 1            | 4              | 1, 5       | 2020-01-10 11:22:59 |
| **10**       | 104             | 1            |                |            | 2020-01-11 18:34:49 |
| **10**       | 104             | 1            | 2, 6           | 1, 4       | 2020-01-11 18:34:49 |
***
Take a look at the runner_orders table, we see the distance and duration columns need to be cleaned before any analysing. We will create a temporary table named new_runner_orders with cleaned data.

````sql
DROP TABLE IF EXISTS new_runner_orders;
CREATE TEMP TABLE new_runner_orders AS (
	SELECT  
		order_id,
		runner_id,
		CASE WHEN pickup_time LIKE '%null%' THEN NULL
		ELSE pickup_time END :: timestamp,
		CASE WHEN distance LIKE '%null%' THEN NULL
		ELSE regexp_replace(distance,'[[:alpha:]]','','g') END :: decimal AS distance,
		CASE WHEN duration LIKE '%null%' THEN NULL
		ELSE regexp_replace(duration,'[[:alpha:]]','','g') END :: decimal AS duration,
		CASE WHEN cancellation LIKE '%null%' OR cancellation = '' THEN NULL
		ELSE cancellation END
	FROM runner_orders
);
````

Take a look at the new_customer_orders to see it's good to use now:

````sql
SELECT * FROM new_runner_orders;
````

Result:

| **order_id** | **runner_id** | **pickup_time**     | **distance** | **duration** | **cancellation**        |
| ------------ | ------------- | ------------------- | ------------ | ------------ | ----------------------- |
| **1**        | 1             | 2020-01-01 18:15:34 | 20           | 32           |                         |
| **2**        | 1             | 2020-01-01 19:10:54 | 20           | 27           |                         |
| **3**        | 1             | 2020-01-03 00:12:37 | 13.4         | 20           |                         |
| **4**        | 2             | 2020-01-04 13:53:03 | 23.4         | 40           |                         |
| **5**        | 3             | 2020-01-08 21:10:57 | 10           | 15           |                         |
| **6**        | 3             |                     |              |              | Restaurant Cancellation |
| **7**        | 2             | 2020-01-08 21:30:45 | 25           | 25           |                         |
| **8**        | 2             | 2020-01-10 00:15:02 | 23.4         | 15           |                         |
| **9**        | 2             |                     |              |              | Customer Cancellation   |
| **10**       | 1             | 2020-01-11 18:50:20 | 10           | 10           |                         |
***
#### A. Pizza Metrics

**1. How many pizzas were ordered?**

````sql
SELECT COUNT(*) orders_num
FROM new_customer_orders;
````

*Answer:*

| **orders_num** |
| -------------- |
| 14             |
***
**2. How many unique customer orders were made?**

````sql
SELECT COUNT(DISTINCT order_id) unique_order_num
FROM new_customer_orders;
````

*Answer:*

| **unique_order_num** |
| -------------------- |
| 10                   |
***
**3. How many successful orders were delivered by each runner?**

````sql
SELECT runner_id, count(*) success_order_num
FROM new_runner_orders
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **runner_id** | **success_order_num** |
| ------------- | --------------------- |
| **1**         | 4                     |
| **2**         | 3                     |
| **3**         | 1                     |
***
**4. How many of each type of pizza was delivered?**

````sql
SELECT n.pizza_name, count(*)
FROM new_customer_orders c
JOIN new_runner_orders r ON c.order_id = r.order_id
JOIN pizza_names n ON c.pizza_id = n.pizza_id
WHERE r.cancellation IS NULL
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **pizza_name** | **count** |
| -------------- | --------- |
| **Meatlovers** | 9         |
| **Vegetarian** | 3         |
***
**5. How many Vegetarian and Meatlovers were ordered by each customer?**

````sql
SELECT c.customer_id, n.pizza_name, count(*) num_order
FROM new_customer_orders c
JOIN pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY 1, 2
ORDER BY 1;
````

*Answer:*

| **customer_id** | **pizza_name** | **num_order** |
| --------------- | -------------- | ------------- |
| **101**         | Meatlovers     | 2             |
| **101**         | Vegetarian     | 1             |
| **102**         | Meatlovers     | 2             |
| **102**         | Vegetarian     | 1             |
| **103**         | Meatlovers     | 3             |
| **103**         | Vegetarian     | 1             |
| **104**         | Meatlovers     | 3             |
| **105**         | Vegetarian     | 1             |
***
**6. What was the maximum number of pizzas delivered in a single order?

````sql
SELECT c.order_id, count(*) max_pizza_num
FROM new_customer_orders c
JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
````

*Answer:*

| **order_id** | **max_pizza_num** |
| ------------ | ----------------- |
| **4**        | 3                 |
***
**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**

````sql
SELECT 
	c.customer_id,
	SUM(
		CASE WHEN exclusions IS NULL AND extras IS NULL
			THEN 0 ELSE 1 END
	) AS change,
	SUM(
		CASE WHEN exclusions IS NULL AND extras IS NULL
			THEN 1 ELSE 0 END
	) AS no_change
FROM new_customer_orders c
JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **customer_id** | **change** | **no_change** |
| --------------- | ---------- | ------------- |
| **101**         | 0          | 2             |
| **102**         | 0          | 3             |
| **103**         | 3          | 0             |
| **104**         | 2          | 1             |
| **105**         | 1          | 0             |
***
**8. How many pizzas were delivered that had both exclusions and extras?**

````sql
SELECT count(*)
FROM new_customer_orders c
	JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
	AND exclusions IS NOT NULL AND extras IS NOT NULL;
````

*Answer:*

| **count** |
| --------- |
| 1         |
***
**9. What was the total volume of pizzas ordered for each hour of the day?**

````sql
SELECT
	TO_CHAR(
		order_time, 'HH24') AS hour_of_the_day,
	count(*)
FROM new_customer_orders
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **hour_of_the_day** | **count** |
| ------------------- | --------- |
| **11**              | 1         |
| **13**              | 3         |
| **18**              | 3         |
| **19**              | 1         |
| **21**              | 3         |
| **23**              | 3         |
***
**10. What was the volume of orders for each day of the week?**

````sql
SELECT
	TO_CHAR(
		order_time, 'Dy') AS day_of_the_week,
	count(DISTINCT order_id) AS order_num
FROM new_customer_orders
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **day_of_the_week** | **order_num** |
| ------------------- | ------------- |
| **Fri**             | 1             |
| **Sat**             | 2             |
| **Thu**             | 2             |
| **Wed**             | 5             |
***
#### B. Runner and Customer Experience

**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**

````sql
SELECT 
	TO_CHAR(registration_date, 'WW') AS week,
	COUNT(*) regis_runners_num
FROM runners
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **week** | **regis_runners_num** |
| -------- | --------------------- |
| **1**    | 2                     |
| **2**    | 1                     |
| **3**    | 1                     |
***
**2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?**

````sql
SELECT
	r.runner_id,
	AVG((EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)))/60) AS avg_arrival_time
FROM new_runner_orders r
	JOIN new_customer_orders c ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **runner_id** | **avg_arrival_time_in_minute** |
| ------------- | ------------------------------ |
| **1**         | 15.68                          |
| **2**         | 23.72                          |
| **3**         | 10.47                          |
***
**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**

````sql
WITH prepare_table AS(
	SELECT
		c.order_id,
		count(*) AS pizza_num,
		(EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)))/60 AS prepare_time
	FROM new_customer_orders c
		JOIN new_runner_orders r ON r.order_id = c.order_id
	WHERE r.pickup_time IS NOT NULL
	GROUP BY 1,3
	ORDER BY 1
)
SELECT
	pizza_num,
	ROUND(AVG(prepare_time),2) avg_prepare_time_in_minute
FROM prepare_table
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **pizza_num** | **avg_prepare_time_in_minute** |
| ------------- | ------------------------------ |
| **1**         | 12.36                          |
| **2**         | 18.38                          |
| **3**         | 29.28                          |

Look at the result, we see the number of pizzas does have relationship with preparation time.
The more pizzas ordered, the longer preparation time.
***
**4. What was the average distance travelled for each customer?**
=> Join new_customer_orders and new_runner_orders, group by customer_id, avg(distance)
***
**5. What was the difference between the longest and shortest delivery times for all orders?**

````sql
SELECT 
	MAX(duration) - MIN(duration) AS time_diff_in_minute
FROM new_runner_orders;
````

*Answer:*

| **time_diff_in_minute** |
| ----------------------- |
| 30                      |
***
**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**

We calculate the runners' average speed with calculation unit is km/h:

````sql
SELECT 
	runner_id,
	ROUND(AVG(distance/(duration/60)),2) AS avg_speed_kmh
FROM 
	new_runner_orders
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **runner_id** | **avg_speed_kmh** |
| ------------- | ----------------- |
| **1**         | 45.54             |
| **2**         | 62.90             |
| **3**         | 40.00             |

From the result, we could see the runner_id = 3 has the lowest speed, it might because he is newbie.

We also could see runner_id 2 is much faster than other two, we could take a look at his orders to have more insights:

````sql
SELECT 
	order_id,
	ROUND(distance/(duration/60),2) AS speed
FROM 
	new_runner_orders
WHERE runner_id = 2;
````

| **order_id** | **speed** |
| ------------ | --------- |
| **4**        | 35.10     |
| **7**        | 60.00     |
| **8**        | 93.60     |
| **9**        |           |

We could see with order_id = 8, the runner 2 might violate the law with a too high speed which could bring good experience to customer but actually could harm the runner as well as the business.
***
**7. What is the successful delivery percentage for each runner?**

````sql
SELECT 
	runner_id,
	100*COUNT(pickup_time)/COUNT(*) successful_order_percentage
FROM new_runner_orders
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **runner_id** | **successful_order_percentage** |
| ------------- | ------------------------------- |
| **1**         | 100                             |
| **2**         | 75                              |
| **3**         | 50                              |
***
#### C. Ingredient Optimisation
