-- 1. What is the total amount each customer spent at the restaurant?

SET search_path = dannys_diner;
SELECT 
	s.customer_id,
	SUM(m.price) total_spend
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1

-- 2. How many days has each customer visited the restaurant?

SELECT 
	customer_id,
	COUNT (DISTINCT order_date) number_of_days_visited
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1

-- 3. What was the first item from the menu purchased by each customer?

WITH rank_date AS
	(SELECT 
		customer_id,
		order_date,
	 	product_id,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date)
		AS ranking
	FROM dannys_diner.sales)
SELECT 
	r.customer_id,
	m.product_name first_item
FROM rank_date r
LEFT JOIN dannys_diner.menu m
ON r.product_id = m.product_id
WHERE r.ranking = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- Step 1: find the most purchased product_id by COUNT purchased times of each product_id on sales table, ORDER BY DESC then LIMIT 1 with product_id has the highest count
-- Step 2: JOIN with menu table to find product_name of that product_id
WITH most_purchased AS
	(SELECT
		product_id,
		COUNT(*) purchased_times
	FROM dannys_diner.sales
	GROUP BY 1
	ORDER BY 2 DESC
	LIMIT 1)
SELECT 
	m.product_name most_purchased_item,
	p.purchased_times
FROM most_purchased p
JOIN dannys_diner.menu m
ON p.product_id = m.product_id

-- 5. Which item was the most popular for each customer?

-- Step 1: create purchase_table with purchased times of each product_id per customer_id, then rank them in DESC order by DESEN_RANK function
-- Step 2: JOIN the most purchased product_id of each customer with menu table to find the product_name
WITH purchase_table AS
	(SELECT
		customer_id,
		product_id,
		COUNT(*) purchased_times,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(*) DESC)
		AS ranking
	FROM dannys_diner.sales
	GROUP BY 1, 2)
SELECT 
	p.customer_id,
	m.product_name most_popular_item,
	p.purchased_times
FROM purchase_table p
JOIN dannys_diner.menu m
ON p.product_id = m.product_id
WHERE p.ranking = 1
ORDER BY 1

-- 6. Which item was purchased first by the customer after they became a member?

WITH sub_table AS(
	SELECT 
		s.customer_id,
		s.order_date,
		s.product_id,
		mb.join_date AS member_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date)
		AS ranking
	FROM dannys_diner.sales s
	JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date > mb.join_date
)
SELECT
	sub.customer_id,
	sub.member_date,
	sub.order_date,
	m.product_name
FROM sub_table sub
JOIN dannys_diner.menu m
ON sub.product_id = m.product_id
WHERE ranking = 1
ORDER BY 1

-- 7. Which item was purchased just before the customer became a member?

WITH sub_table AS(
	SELECT 
		s.customer_id,
		s.order_date,
		s.product_id,
		mb.join_date AS member_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC)
		AS ranking
	FROM dannys_diner.sales s
	JOIN dannys_diner.members mb
	ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
)
SELECT
	sub.customer_id,
	sub.member_date,
	sub.order_date,
	m.product_name
FROM sub_table sub
JOIN dannys_diner.menu m
ON sub.product_id = m.product_id
WHERE ranking = 1
ORDER BY 1

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id,
	COUNT(s.product_id) AS item_count,
	SUM(m.price) AS amount_spend
FROM dannys_diner.sales s
JOIN dannys_diner.menu m ON s.product_id = m.product_id
JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY 1
ORDER BY 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- Step 1: join the table menu with sales, create "point" column which meets the criterion if product_name = 'sushi' then point = price*20, else point = price*10
-- Step 2: sum the point of each customer, group by customer_id
SELECT
	s.customer_id,
	SUM(CASE WHEN m.product_name = 'sushi' THEN price*20 
	ELSE price*10 END) AS point
FROM dannys_diner.sales s
JOIN dannys_diner.menu m 
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
	s.customer_id,
	SUM(CASE WHEN (s.order_date <= mb.join_date + 6) AND s.order_date >= mb.join_date THEN price*20
    ELSE 
    CASE WHEN m.product_name = 'sushi' THEN m.price*20 
	ELSE price*10 END
    END) AS point
FROM sales s
JOIN members mb ON s.customer_id = mb.customer_id
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY 1
ORDER BY 1

-- Join All The Things

SELECT 
	s.customer_id,
	order_date,
	product_name,
	price,
	CASE WHEN order_date < join_date OR join_date IS null THEN 'N' ELSE 'Y' END as member
FROM
	sales s
	JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY 1, 2

-- Rank All The Things

WITH join_table AS (
		SELECT 
			s.customer_id,
			order_date,
			product_name,
			price,
			CASE WHEN order_date < join_date OR join_date IS null THEN 'N' ELSE 'Y' END as member
		FROM
			sales s
			JOIN menu m ON s.product_id = m.product_id
			LEFT JOIN members mb ON s.customer_id = mb.customer_id
		ORDER BY 1, 2
)
SELECT
	*,
	CASE
		WHEN member = 'N' THEN null ELSE
		DENSE_RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) 
		END AS ranking
FROM join_table
		


	