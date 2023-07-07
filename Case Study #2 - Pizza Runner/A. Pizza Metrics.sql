-- Take a look at the customer_orders table:

SELECT * FROM pizza_runner.customer_orders;

-- The exclusions and extras columns will need to be cleaned up before using them in queries
-- We will create a temporary table named new_customer_orders with cleaned data:

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

-- Take a look at the new_customer_orders to see it's good to use now

SELECT * FROM new_customer_orders

-- Take a look at the runner_orders table:

SELECT * FROM pizza_runner.runner_orders;

-- The distance and duration columns need to be cleaned before any analysing
-- We will create a temporary table named new_runner_orders with cleaned data:

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

-- Take a look at the new_customer_orders to see it's good to use now

SELECT * FROM new_runner_orders;
	
-- 1. How many pizzas were ordered?

SELECT COUNT(*) orders_num
FROM new_customer_orders;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) unique_order_num
FROM new_customer_orders;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id, count(*) success_order_num
FROM new_runner_orders
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 1;

-- 4. How many of each type of pizza was delivered?

SELECT n.pizza_name, count(*)
FROM new_customer_orders c
JOIN new_runner_orders r ON c.order_id = r.order_id
JOIN pizza_names n ON c.pizza_id = n.pizza_id
WHERE r.cancellation IS NULL
GROUP BY 1
ORDER BY 1;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT c.customer_id, n.pizza_name, count(*) num_order
FROM new_customer_orders c
JOIN pizza_names n ON c.pizza_id = n.pizza_id
GROUP BY 1, 2
ORDER BY 1;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT c.order_id, count(*) max_pizza_num
FROM new_customer_orders c
JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

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

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT count(*)
FROM new_customer_orders c
	JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE r.cancellation IS NULL
	AND exclusions IS NOT NULL AND extras IS NOT NULL;
	
-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT
	TO_CHAR(
		order_time, 'HH24') AS hour_of_the_day,
	count(*)
FROM new_customer_orders
GROUP BY 1
ORDER BY 1;

-- 10. What was the volume of orders for each day of the week?

SELECT
	TO_CHAR(
		order_time, 'Dy') AS day_of_the_week,
	count(DISTINCT order_id) AS order_num
FROM new_customer_orders
GROUP BY 1
ORDER BY 1;