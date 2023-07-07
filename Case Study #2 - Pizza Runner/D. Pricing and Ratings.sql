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

SET search_path = pizza_runner;
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


-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT
	SUM(
	CASE
		WHEN pizza_id = 1 THEN 12 
		WHEN pizza_id = 2 THEN 10
	END) AS income
FROM new_customer_orders c
	JOIN new_runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL

-- 2. What if there was an additional $1 charge for any pizza extras?

WITH income_table AS
(
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
	SUM(extra_pizza_fee + income)
FROM 
	income_table i
	JOIN new_runner_orders r ON i.order_id = r.order_id
WHERE r.cancellation IS NULL

-- What if adding cheese is $1 extra?
/* Create a temporary table named complete_table combining new_customer_orders
and extra_pizza_fee column with $1 extra for every additional pizza and $1 extra
for adding cheese:
*/

WITH n_new_customer_orders AS
(
	SELECT
		order_id,
		customer_id,
		pizza_id,
		CASE WHEN exclusions IS NULL THEN '0' ELSE exclusions END,
		CASE WHEN extras IS NULL THEN '0' ELSE extras END,
		order_time
	FROM new_customer_orders
),
 	complete_table AS
(
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
SELECT SUM(income + extra_pizza_fee + cheese_adding_fee) AS total
FROM
	(SELECT 
		*,
		CASE 
			WHEN extra_topping_id = 4 
			THEN 1 ELSE 0 END AS cheese_adding_fee
	FROM complete_table) AS t
JOIN new_runner_orders r
ON t.order_id = r.order_id
WHERE cancellation IS NULL

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--how would you design an additional table for this new dataset - generate a schema for this new table and 
--insert your own data for ratings for each successful customer order between 1 to 5.
SET search_path = pizza_runner;
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
-- Result:
SELECT * FROM rating

/*
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
*/

SELECT
	customer_id,
	c.order_id,
	r.runner_id,
	rating,
	order_time,
	pickup_time,
	TO_CHAR(pickup_time - order_time,'MI') AS prepare_time,
	duration AS deli_duration,
	distance/(duration/60) AS speed,
	COUNT(*) num_of_pizza
FROM
	new_customer_orders c
	JOIN new_runner_orders r ON c.order_id = r.order_id AND r.cancellation IS NULL
	JOIN rating rt ON c.order_id = rt.order_id
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY 2
	