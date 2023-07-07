-- Clean customer_orders and runner_orders tables:
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


-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
	TO_CHAR(registration_date, 'WW') AS week,
	COUNT(*) regis_runners_num
FROM runners
GROUP BY 1
ORDER BY 1;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT
	r.runner_id,
	ROUND(AVG((EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)))/60),2) AS avg_arrival_time_in_minute
FROM new_runner_orders r
	JOIN new_customer_orders c ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

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
/* Look at the result, we see the number of pizzas does have relationship with preparation time.
The more pizzas ordered, the longer preparation time.*/

-- 4. What was the average distance travelled for each customer?
-- Join new_customer_orders and new_runner_orders, group by customer_id, avg(distance)

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
	MAX(duration) - MIN(duration) AS time_diff_in_minute
FROM new_runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

-- We calculate the runners' average speed with calculation unit is km/h:

SELECT 
	runner_id,
	ROUND(AVG(distance/(duration/60)),2) AS avg_speed_kmh
FROM 
	new_runner_orders
WHERE pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1;
-- From the result, we could see the runner_id = 3 has the lowest speed, it might because he is newbie.
-- We also could see runner_id 2 is much faster than other two, we could take a look at his orders to have more insights:
SELECT 
	order_id,
	ROUND(distance/(duration/60),2) AS speed
FROM 
	new_runner_orders
WHERE runner_id = 2;
-- We could see with order_id = 8, the runner 2 might violate the law with a too high speed which could bring good experience to customer but actually could harm the runner as well as the business.

-- 7. What is the successful delivery percentage for each runner?

SELECT 
	runner_id,
	100*COUNT(pickup_time)/COUNT(*) successful_order_percentage
FROM new_runner_orders
GROUP BY 1
ORDER BY 1;
