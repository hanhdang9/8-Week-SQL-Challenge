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


-- 1. What are the standard ingredients for each pizza?

-- Firstly, we will create a temporary table named "new_pizza_recipes" with long format for the recipe of each pizza.

DROP TABLE IF EXISTS new_pizza_recipes;
CREATE TEMP TABLE new_pizza_recipes AS
(
	SELECT 
		pizza_id,
		trim(unnest(string_to_array(toppings, ','))):: integer topping_id
	FROM 
		pizza_runner.pizza_recipes
);
-- Then, we join pizza_name, new_pizza_recipes and pizza_toppings together to get the answer for the question:

SELECT 
	pizza_name,
	r.topping_id,
	topping_name
FROM pizza_names n
	JOIN new_pizza_recipes r ON n.pizza_id = r.pizza_id
	JOIN pizza_toppings t ON r.topping_id = t.topping_id
ORDER BY 1,2;

-- We could make it easier to see as below:

SELECT 
	pizza_name,
	STRING_AGG(topping_name, ', ')
FROM pizza_names n
	JOIN new_pizza_recipes r ON n.pizza_id = r.pizza_id
	JOIN pizza_toppings t ON r.topping_id = t.topping_id
GROUP BY 1;

-- 2. What was the most commonly added extra?

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
	
-- 3. What was the most common exclusion?

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
	
/* 
4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

-- Step 1: we create a complete_table adding 3 columns (pizza name, exclusion topping names and extra topping names) to new_customer_orders table.
-- Step 2: we create order item column by concatenating 3 columns above.

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



		
	