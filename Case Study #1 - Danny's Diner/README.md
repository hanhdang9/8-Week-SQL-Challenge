# Case Study #1 - Danny's Diner
![1](https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/deb475c8-ff07-4023-9c28-10947259d593)


## Table of Contents
* [Context](#context)
* [Dataset](#dataset)
* [Questions and Answers](#questions-and-answers)
***
### Context
Danny is opening up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen. 
Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation.
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.
***
### Dataset
#### Entity Relationship Diagram
<img width="583" alt="Ảnh màn hình 2023-07-04 lúc 17 03 30" src="https://github.com/hanhdang9/8-Week-SQL-Challenge/assets/122140143/2b4e0357-ad37-4a73-b1fc-b8a37dc62cbc">


#### Example Datasets
* Table 1: sales

| customer_id | order_date | product_id |
| ----------- | ---------- | ---------- |
| A           | 2021-01-01 | 1          |
| A           | 2021-01-01 | 2          |
| A           | 2021-01-07 | 2          |
| A           | 2021-01-10 | 3          |
| A           | 2021-01-11 | 3          |
| A           | 2021-01-11 | 3          |
| B           | 2021-01-01 | 2          |
| B           | 2021-01-02 | 2          |
| B           | 2021-01-04 | 1          |
| B           | 2021-01-11 | 1          |
| B           | 2021-01-16 | 3          |
| B           | 2021-02-01 | 3          |
| C           | 2021-01-01 | 3          |
| C           | 2021-01-01 | 3          |
| C           | 2021-01-07 | 3          |

* Table 2: menu

| product_id | product_name | price |
| ---------- | ------------ | ----- |
| 1          | sushi        | 10    |
| 2          | curry        | 15    |
| 3          | ramen        | 12    |

* Table 3: members

| customer_id | join_date  |
| ----------- | ---------- |
| A           | 2021-01-07 |
| B           | 2021-01-09 |
***
### Questions and Answers
**1. What is the total amount each customer spent at the restaurant?**

````sql
SET search_path = dannys_diner;
SELECT 
	s.customer_id,
	SUM(m.price) total_spend
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **customer_id** | **total_spend** |
| --------------- | --------------- |
| **A**           | 76              |
| **B**           | 74              |
| **C**           | 36              |
***
**2. How many days has each customer visited the restaurant?**

````sql
SELECT 
	customer_id,
	COUNT (DISTINCT order_date) number_of_days_visited
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **customer_id** | **number_of_days_visited** |
| --------------- | -------------------------- |
| **A**           | 4                          |
| **B**           | 6                          |
| **C**           | 2                          |
***
**3. What was the first item from the menu purchased by each customer?**

````sql
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
WHERE r.ranking = 1;
````

*Answer:*

| **customer_id** | **first_item**   |
| --------------- | ---------------- |
| **A**           | sushi            |
| **B**           | curry            |
| **C**           | ramen            |
***
**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

````sql

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
ON p.product_id = m.product_id;
````

*Answer:*

| **most_purchased_item** | **purchased_times** |
| ----------------------- | ------------------- |
| **ramen**               | 8                   |
***
**5. Which item was the most popular for each customer?**

````sql

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
ORDER BY 1;
````
*Answer:*

| **customer_id** | **most_popular_item** | **purchased_times** |
| --------------- | --------------------- | ------------------- |
| **A**           | ramen                 | 3                   |
| **B**           | sushi                 | 2                   |
| **B**           | curry                 | 2                   |
| **B**           | ramen                 | 2                   |
| **C**           | ramen                 | 3                   |
***
**6. Which item was purchased first by the customer after they became a member?**

````sql
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
ORDER BY 1;
````

*Answer:*

| **customer_id** | **member_date** | **order_date** | **product_name** |
| --------------- | --------------- | -------------- | ---------------- |
| **A**           | 2021-01-07      | 2021-01-10     | ramen            |
| **B**           | 2021-01-09      | 2021-01-11     | sushi            |
***
**7. Which item was purchased just before the customer became a member?**

````sql
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
ORDER BY 1;
````

*Answer:*

| **customer_id** | **member_date** | **order_date** | **product_name** |
| --------------- | --------------- | -------------- | ---------------- |
| **A**           | 2021-01-07      | 2021-01-01     | sushi            |
| **B**           | 2021-01-09      | 2021-01-04     | sushi            |
***
**8. What is the total items and amount spent for each member before they became a member?**

````sql
SELECT 
	s.customer_id,
	COUNT(s.product_id) AS item_count,
	SUM(m.price) AS amount_spend
FROM dannys_diner.sales s
JOIN dannys_diner.menu m ON s.product_id = m.product_id
JOIN dannys_diner.members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY 1
ORDER BY 1;
````

*Answer:*

| **customer_id** | **item_count** | **amount_spend** |
| --------------- | -------------- | ---------------- |
| **A**           | 2              | 25               |
| **B**           | 3              | 40               |
***
**9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**

````sql
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
ORDER BY 1;
````

*Answer:*

| **customer_id** | **point** |
| --------------- | --------- |
| **A**           | 860       |
| **B**           | 940       |
| **C**           | 360       |
***
**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

````sql
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
ORDER BY 1;
````

*Answer:*

| **customer_id** | **point** |
| --------------- | --------- |
| **A**           | 1370      |
| **B**           | 820       |
***
**Join All The Things**

````sql
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
ORDER BY 1, 2;
````

*Answer:*

| **customer_id** | **order_date** | **product_name** | **price** | **member** |
| --------------- | -------------- | ---------------- | --------- | ---------- |
| **A**           | 2021-01-01     | sushi            | 10        | N          |
| **A**           | 2021-01-01     | curry            | 15        | N          |
| **A**           | 2021-01-07     | curry            | 15        | Y          |
| **A**           | 2021-01-10     | ramen            | 12        | Y          |
| **A**           | 2021-01-11     | ramen            | 12        | Y          |
| **A**           | 2021-01-11     | ramen            | 12        | Y          |
| **B**           | 2021-01-01     | curry            | 15        | N          |
| **B**           | 2021-01-02     | curry            | 15        | N          |
| **B**           | 2021-01-04     | sushi            | 10        | N          |
| **B**           | 2021-01-11     | sushi            | 10        | Y          |
| **B**           | 2021-01-16     | ramen            | 12        | Y          |
| **B**           | 2021-02-01     | ramen            | 12        | Y          |
| **C**           | 2021-01-01     | ramen            | 12        | N          |
| **C**           | 2021-01-01     | ramen            | 12        | N          |
| **C**           | 2021-01-07     | ramen            | 12        | N          |
***
**Rank All The Things**

````sql
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
FROM join_table;
````

*Answer:*

| **customer_id** | **order_date** | **product_name** | **price** | **member** | **ranking** |
| --------------- | -------------- | ---------------- | --------- | ---------- | ----------- |
| **A**           | 2021-01-01     | sushi            | 10        | N          | NULL        |
| **A**           | 2021-01-01     | curry            | 15        | N          | NULL        |
| **A**           | 2021-01-07     | curry            | 15        | Y          | 1           |
| **A**           | 2021-01-10     | ramen            | 12        | Y          | 2           |
| **A**           | 2021-01-11     | ramen            | 12        | Y          | 3           |
| **A**           | 2021-01-11     | ramen            | 12        | Y          | 3           |
| **B**           | 2021-01-01     | curry            | 15        | N          | NULL        |
| **B**           | 2021-01-02     | curry            | 15        | N          | NULL        |
| **B**           | 2021-01-04     | sushi            | 10        | N          | NULL        |
| **B**           | 2021-01-11     | sushi            | 10        | Y          | 1           |
| **B**           | 2021-01-16     | ramen            | 12        | Y          | 2           |
| **B**           | 2021-02-01     | ramen            | 12        | Y          | 3           |
| **C**           | 2021-01-01     | ramen            | 12        | N          | NULL        |
| **C**           | 2021-01-01     | ramen            | 12        | N          | NULL        |
| **C**           | 2021-01-07     | ramen            | 12        | N          | NULL        |
