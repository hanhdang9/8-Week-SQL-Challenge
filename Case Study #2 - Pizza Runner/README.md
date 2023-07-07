# Case Study #2 - Pizza Runner

![2](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/71d97d06-c491-463b-a7a1-e35d8eeb1076)

## Table of Contents
* [Context](#context)
* [Dataset](#dataset)
* [Questions and Answer](#question-and-answer)
  * [Clean data](#clean-data)
  * [A. Pizza Metrics](#a-pizza-metrics)
  * [B. Runner and Customer Experience](#b-runner-and-customer-experience)
  * [C. Ingredient Optimisation](#c-ingredient-optimisation)
  * [D. Pricing and Ratings](#d-pricing-and-ratings)
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

* Take a look at the customer_orders table, we see the exclusions and extras columns will need to be cleaned up before using them in queries. We will create a temporary table named new_customer_orders with cleaned data.

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
* Take a look at the new_customer_orders to see it's good to use now:

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
* Take a look at the runner_orders table, we see the distance and duration columns need to be cleaned before any analysing. We will create a temporary table named new_runner_orders with cleaned data.

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

* Take a look at the new_customer_orders to see it's good to use now:

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

* Look at the result, we see the number of pizzas does have relationship with preparation time.
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

* We calculate the runners' average speed with calculation unit is km/h:

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

* From the result, we could see the runner_id = 3 has the lowest speed, it might because he is newbie.

* We also could see runner_id 2 is much faster than other two, we could take a look at his orders to have more insights:

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

* We could see with order_id = 8, the runner 2 might violate the law with a too high speed which could bring good experience to customer but actually could harm the runner as well as the business.
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

**1. What are the standard ingredients for each pizza?**

- Firstly, we will create a temporary table named "new_pizza_recipes" with long format for the recipe of each pizza.
````sql
DROP TABLE IF EXISTS new_pizza_recipes;
CREATE TEMP TABLE new_pizza_recipes AS(
	SELECT 
		pizza_id,
		trim(unnest(string_to_array(toppings, ','))):: integer topping_id
	FROM 
		pizza_runner.pizza_recipes
);
````
- Then, we join pizza_name, new_pizza_recipes and pizza_toppings together to get the answer for the question:
````sql
SELECT 
	pizza_name,
	r.topping_id,
	topping_name
FROM pizza_names n
	JOIN new_pizza_recipes r ON n.pizza_id = r.pizza_id
	JOIN pizza_toppings t ON r.topping_id = t.topping_id
ORDER BY 1,2;
````

*Answer:*

| **pizza_name** | **topping_id** | **topping_name** |
| -------------- | -------------- | ---------------- |
| **Meatlovers** | 1              | Bacon            |
| **Meatlovers** | 2              | BBQ Sauce        |
| **Meatlovers** | 3              | Beef             |
| **Meatlovers** | 4              | Cheese           |
| **Meatlovers** | 5              | Chicken          |
| **Meatlovers** | 6              | Mushrooms        |
| **Meatlovers** | 8              | Pepperoni        |
| **Meatlovers** | 10             | Salami           |
| **Vegetarian** | 4              | Cheese           |
| **Vegetarian** | 6              | Mushrooms        |
| **Vegetarian** | 7              | Onions           |
| **Vegetarian** | 9              | Peppers          |
| **Vegetarian** | 11             | Tomatoes         |
| **Vegetarian** | 12             | Tomato Sauce     |

- We could make it easier to see by this way as below:

````sql
SELECT 
	pizza_name,
	STRING_AGG(topping_name, ', ')
FROM pizza_names n
	JOIN new_pizza_recipes r ON n.pizza_id = r.pizza_id
	JOIN pizza_toppings t ON r.topping_id = t.topping_id
GROUP BY 1;
````
| **pizza_name** | **string_agg**                                                        |
| -------------- | --------------------------------------------------------------------- |
| **Meatlovers** | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| **Vegetarian** | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce            |
***
**2. What was the most commonly added extra?**

````sql
SELECT
	topping_name most_common_add
FROM
	(
	SELECT
		COUNT(*),
		UNNEST(string_to_array(extras, ',')):: numeric as topping_id
	FROM new_customer_orders
	WHERE extras IS NOT NULL
	GROUP BY 2
	ORDER BY 1 DESC
	LIMIT 1
	) AS most_common_extra 
	JOIN pizza_toppings t ON most_common_extra.topping_id = t.topping_id;
````

*Answer:*

| **most_common_add** |
| ------------------- |
| Bacon               |
***
**3. What was the most common exclusion?**

````sql
SELECT
	topping_name most_common_exclu
FROM
	(
	SELECT
		COUNT(*),
		TRIM(UNNEST(string_to_array(exclusions, ','))):: numeric as topping_id
	FROM new_customer_orders
	WHERE exclusions IS NOT NULL
	GROUP BY 2
	ORDER BY 1 DESC
	LIMIT 1
	) AS most_exclu 
	JOIN pizza_toppings t ON most_exclu.topping_id = t.topping_id;
````

*Answer:*

| **most_common_exclu** |
| --------------------- |
| Cheese                |
***
**4. Generate an order item for each record in the customers_orders table in the format of one of the following:**

`Meat Lovers`;

`Meat Lovers - Exclude Beef`;

`Meat Lovers - Extra Bacon`;

`Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`;

*Step 1: we create a complete_table adding 3 columns (pizza name, exclusion topping names and extra topping names) to new_customer_orders table.*

*Step 2: we create order item column by concatenating 3 columns above.*

````sql
-- To create pizza_name column, `JOIN` new_customer_orders and pizza_names table `ON` the same pizza_id.
-- To create exclusion topping name and extra topping name columns, we use `UNNEST` AND `STRING_AGG` function.

DROP TABLE IF EXISTS complete_table;
CREATE TEMP TABLE complete_table AS(

-- Firstly, create table1 which transfer NULL exclusions and NULL extras orders to '0' then we could use UNNEST function with exclusions and extras and still can retrieve the whole data

	WITH 
		table1 AS(
			SELECT
				order_id,
				customer_id,
				pizza_id,
				CASE WHEN exclusions IS NULL THEN '0' ELSE exclusions END,
				CASE WHEN extras IS NULL THEN '0' ELSE extras END,
				order_time
			FROM new_customer_orders
		),

-- Then, we UNNEST exclusions and extras to get separate exclusion and extra topping ids, we also `JOIN` pizza_names table to get pizza_name column

 		table2 AS(
			SELECT
				order_id,
				customer_id,
				tbl1.pizza_id,
				ROW_NUMBER() OVER(PARTITION BY order_id),
				UNNEST(string_to_array(exclusions, ',')):: numeric exclu_topping_id,
				UNNEST(string_to_array(extras, ',')):: numeric extra_topping_id,
				order_time,
				pizza_name
			FROM table1 tbl1
				JOIN pizza_names n ON tbl1.pizza_id = n.pizza_id
			ORDER BY 1
		),

-- Next, we `JOIN` table2 with pizza_toppings table to get the exclusion and extra topping names

		table3 AS(
			SELECT tbl2.*,
					p.topping_name exclu_topping_name
			FROM table2 tbl2
				LEFT JOIN pizza_toppings p ON tbl2.exclu_topping_id = p.topping_id
		),
		table4 AS(
			SELECT 
				tbl3.*,
				topping_name extra_topping_name
			FROM table3 tbl3
				LEFT JOIN pizza_toppings p ON tbl3.extra_topping_id = p.topping_id
		),
-- Next, we aggregate exclu_topping_name and extra_topping_name

		table5 AS(
			SELECT 
				order_id,
				customer_id,
				pizza_id,
				row_number,
				string_agg(exclu_topping_id :: text,', ') exclu_id,
				string_agg(extra_topping_id :: text,', ') extra_id,
				order_time,
				pizza_name,
				string_agg(exclu_topping_name,', ') exclu_name,
				string_agg(extra_topping_name,', ') extra_name
			FROM table4
			GROUP BY 1,2,3,4,7,8
			ORDER BY order_id
		)

-- table5 is the complete_table we want.

	SELECT * FROM table5
);
-- Finally, we concatenate pizza_name, exclu_name, extra_name columns to get the answer for the question
SELECT 
	order_id,
	customer_id,
	pizza_id,
	CASE WHEN exclu_id = '0' THEN NULL ELSE exclu_id END AS exclusions,
	CASE WHEN extra_id = '0' THEN NULL ELSE extra_id END AS extras,
	order_time,
	CASE
		WHEN exclu_name IS NULL AND extra_name IS NULL THEN pizza_name
		WHEN exclu_name IS NULL AND extra_name IS NOT NULL THEN pizza_name||' - Extra '||extra_name
		WHEN exclu_name IS NOT NULL AND extra_name IS NULL THEN pizza_name||' - Exclude '||exclu_name
		WHEN exclu_name IS NOT NULL AND extra_name IS NOT NULL THEN pizza_name||' - Exclude '||exclu_name||' - Extra '||extra_name
	END AS order_item
FROM complete_table;
````

*Answer:*

| **order_id** | **customer_id** | **pizza_id** | **exclusions** | **extras** | **order_time**      | **order_item**                                                  |
| ------------ | --------------- | ------------ | -------------- | ---------- | ------------------- | --------------------------------------------------------------- |
| **1**        | 101             | 1            |                |            | 2020-01-01 18:05:02 | Meatlovers                                                      |
| **2**        | 101             | 1            |                |            | 2020-01-01 19:00:52 | Meatlovers                                                      |
| **3**        | 102             | 1            |                |            | 2020-01-02 23:51:23 | Meatlovers                                                      |
| **3**        | 102             | 2            |                |            | 2020-01-02 23:51:23 | Vegetarian                                                      |
| **4**        | 103             | 1            | 4              |            | 2020-01-04 13:23:46 | Meatlovers - Exclude Cheese                                     |
| **4**        | 103             | 2            | 4              |            | 2020-01-04 13:23:46 | Vegetarian - Exclude Cheese                                     |
| **4**        | 103             | 1            | 4              |            | 2020-01-04 13:23:46 | Meatlovers - Exclude Cheese                                     |
| **5**        | 104             | 1            |                | 1          | 2020-01-08 21:00:29 | Meatlovers - Extra Bacon                                        |
| **6**        | 101             | 2            |                |            | 2020-01-08 21:03:13 | Vegetarian                                                      |
| **7**        | 105             | 2            |                | 1          | 2020-01-08 21:20:29 | Vegetarian - Extra Bacon                                        |
| **8**        | 102             | 1            |                |            | 2020-01-09 23:54:33 | Meatlovers                                                      |
| **9**        | 103             | 1            | 4              | 1, 5       | 2020-01-10 11:22:59 | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| **10**       | 104             | 1            | 2, 6           | 1, 4       | 2020-01-11 18:34:49 | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |
| **10**       | 104             | 1            |                |            | 2020-01-11 18:34:49 | Meatlovers                                                      |
***
#### D. Pricing and Ratings

**1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?**

````sql
SELECT
	SUM(
		CASE
			WHEN pizza_id = 1 THEN 12 
			WHEN pizza_id = 2 THEN 10
		END) AS income
FROM new_customer_orders c
	JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL;
````

*Answer:*

| **income** |
| ---------- |
| 138        |
***
**2.1 What if there was an additional $1 charge for any pizza extras?**

````sql
WITH income_table AS(
	SELECT 
		*,
		CASE 
			WHEN (ROW_NUMBER() OVER(PARTITION BY order_id)) = 1
			THEN 0 ELSE 1 END extra_pizza_fee,
		CASE
			WHEN pizza_id = 1 THEN 12 
			WHEN pizza_id = 2 THEN 10
		END AS income
	FROM 
		new_customer_orders
)
SELECT 
	SUM(extra_pizza_fee + income) income
FROM 
	income_table i
	JOIN new_runner_orders r ON i.order_id = r.order_id
WHERE r.cancellation IS NULL;
````

*Answer:*

| **income** |
| ---------- |
| 142        |

**2.2. What if adding cheese is $1 extra?**

- Create a temporary table named complete_table combining new_customer_orders and extra_pizza_fee column with $1 extra for every additional pizza and $1 extra for adding cheese:

````sql
WITH 
	n_new_customer_orders AS(
		SELECT
			order_id,
			customer_id,
			pizza_id,
			CASE WHEN exclusions IS NULL THEN '0' ELSE exclusions END,
			CASE WHEN extras IS NULL THEN '0' ELSE extras END,
			order_time
		FROM new_customer_orders
	),
 	complete_table AS(
		SELECT
			order_id,
			customer_id,
			c.pizza_id,
			UNNEST(string_to_array(exclusions, ',')):: numeric exclu_topping_id,
			UNNEST(string_to_array(extras, ',')):: numeric extra_topping_id,
			ROW_NUMBER() OVER(PARTITION BY order_id) pizza_num,
			CASE 
				WHEN (ROW_NUMBER() OVER(PARTITION BY order_id)) = 1
				THEN 0 ELSE 1 END extra_pizza_fee,
			CASE
				WHEN c.pizza_id = 1 THEN 12 
				WHEN c.pizza_id = 2 THEN 10
			END AS income
		FROM n_new_customer_orders c
		ORDER BY 1
	)
SELECT 
	SUM(income + extra_pizza_fee + cheese_adding_fee) AS income
FROM
	(SELECT 
		*,
		CASE 
			WHEN extra_topping_id = 4 
			THEN 1 ELSE 0 END AS cheese_adding_fee
	FROM complete_table) AS t
JOIN new_runner_orders r
ON t.order_id = r.order_id
WHERE cancellation IS NULL;
````

*Answer:*

| **income** |
| ---------- |
| 156        |
***
**3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**

````sql
DROP TABLE IF EXISTS rating;
CREATE TABLE rating (
	"order_id" INTEGER,
	"rating" INTEGER
);
INSERT INTO rating
	("order_id","rating")
VALUES
	('1','4'),
	('2','5'),
	('3','3'),
	('4','5'),
	('5','2'),
	('7','1'),
	('8','5'),
	('10','5');
````

*Result:*

````sql
SELECT * FROM rating;
````

| **order_id** | **rating** |
| ------------ | ---------- |
| **1**        | 4          |
| **2**        | 5          |
| **3**        | 3          |
| **4**        | 5          |
| **5**        | 2          |
| **7**        | 1          |
| **8**        | 5          |
| **10**       | 5          |
***
**4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?**

`customer_id`

`order_id`

`runner_id`

`rating`

`order_time`

`pickup_time`

Time between order and pickup

Delivery duration

Average speed

Total number of pizzas

````sql
SELECT
	customer_id,
	c.order_id,
	r.runner_id,
	rating,
	order_time,
	pickup_time,
	TO_CHAR(pickup_time - order_time,'MI') AS prepare_time,
	duration AS deli_duration,
	ROUND(distance/(duration/60),2) AS speed_in_kmh,
	COUNT(*) num_of_pizza
FROM
	new_customer_orders c
	JOIN new_runner_orders r ON c.order_id = r.order_id AND r.cancellation IS NULL
	JOIN rating rt ON c.order_id = rt.order_id
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY 2;
````

*Answer:*

| **customer_id** | **order_id** | **runner_id** | **rating** | **order_time**      | **pickup_time**     | **prepare_time** | **deli_duration** | **speed_in_kmh** | **num_of_pizza** |
| --------------- | ------------ | ------------- | ---------- | ------------------- | ------------------- | ---------------- | ----------------- | ---------------- | ---------------- |
| **101**         | 1            | 1             | 4          | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10               | 32                | 37.50            | 1                |
| **101**         | 2            | 1             | 5          | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10               | 27                | 44.44            | 1                |
| **102**         | 3            | 1             | 3          | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21               | 20                | 40.20            | 2                |
| **103**         | 4            | 2             | 5          | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29               | 40                | 35.10            | 3                |
| **104**         | 5            | 3             | 2          | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10               | 15                | 40.00            | 1                |
| **105**         | 7            | 2             | 1          | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10               | 25                | 60.00            | 1                |
| **102**         | 8            | 2             | 5          | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20               | 15                | 93.60            | 1                |
| **104**         | 10           | 1             | 5          | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15               | 10                | 60.00            | 2                |
***
