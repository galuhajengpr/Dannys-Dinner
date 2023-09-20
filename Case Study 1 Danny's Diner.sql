-- Creating Tables
CREATE TABLE sales_dannys (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales_dannys
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu_dannys (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu_dannys
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members_dannys (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members_dannys
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  ----------------------------------

-- Reviewing Data
 SELECT * FROM members_dannys;
 SELECT * FROM menu_dannys;
 SELECT * FROM sales_dannys;

 -----------------------------------

-- REFERENCES 
-- https://github.com/katiehuangx/8-Week-SQL-Challenge/blob/main/Case%20Study%20%231%20-%20Danny's%20Diner/Solution.md
-- https://github.com/manaswikamila05/8-Week-SQL-Challenge/blob/main/Case%20Study%20%23%201%20-%20Danny's%20Diner/Danny's%20Diner%20Solution.md
-- https://medium.com/@orkunaran/8-weeks-sql-challenge-case-study-week-1-dannys-diner-c90013af6797

 -------------------------------------

 -- 1. What is the total amount each customer spent at the restaurant?
 SELECT s.customer_id, SUM(price) total_amount
 FROM sales_dannys s
 JOIN menu_dannys m
 ON s.product_id = m.product_id
 GROUP BY s.customer_id;

 -- 2. How many days has each customer visited the restaurant?
 SELECT customer_id, COUNT( DISTINCT order_date) visited FROM sales_dannys 
 GROUP BY customer_id;

 -- 3. What was the first item from the menu purchased by each customer?
 SELECT s.customer_id, product_name
 FROM sales_dannys s
 JOIN menu_dannys m 
 ON s.product_id = m.product_id
 WHERE s.order_date = ANY ( SELECT MIN(order_date) FROM sales_dannys 
 GROUP BY customer_id);
 -- References : https://www.w3schools.com/sql/sql_any_all.asp
 --              https://medium.com/@orkunaran/8-weeks-sql-challenge-case-study-week-1-dannys-diner-c90013af6797
 
 -- Cara lain dengan menggunakan DENSE RANK
 WITH ordered_sales_cte AS 
 ( SELECT customer_id, order_date, product_name,
		DENSE_RANK () OVER(PARTITION BY s.customer_id
		ORDER BY s.order_date) AS rank
	FROM sales_dannys s
	JOIN menu_dannys m
	ON s.product_id= m.product_id
)

SELECT customer_id, product_name 
FROM ordered_sales_cte WHERE rank = 1 GROUP BY customer_id, product_name;
-- References : https://github.com/katiehuangx/8-Week-SQL-Challenge/blob/main/Case%20Study%20%231%20-%20Danny's%20Diner/Solution.md
--			    https://docs.aws.amazon.com/id_id/redshift/latest/dg/r_WF_DENSE_RANK.html
-- Temporary table :	https://www.geeksforgeeks.org/sql-with-clause/

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  m.product_name, COUNT(s.product_id) as purchased
FROM  menu_dannys m
JOIN sales_dannys s
ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY purchased DESC;

-- 5. Which item was the most popular for each customer?
WITH popular_item_cte AS
(SELECT s.customer_id, m.product_name, COUNT(s.product_id) order_count,
		DENSE_RANK() OVER(PARTITION BY s.customer_id
		ORDER BY COUNT(s.customer_id)DESC) AS rank
	FROM sales_dannys s
	JOIN menu_dannys m
	ON s.product_id= m.product_id
	GROUP BY customer_id, product_name
)

SELECT customer_id, product_name, order_count
FROM popular_item_cte WHERE rank = 1 ;

-- Note : Bagian partition by menjelaskan kolom mana yang akan dibagi lalu setelah pembagian tersebut, order by digunakan untuk mengurutkan ranking
-- Reference lebih untuk dense rank : https://medium.com/@byanjati/berkenalan-dengan-window-function-pada-query-a62548a307b2

-- 6. Which item was purchased first by the customer after they became a member?
WITH purchase_first_cte AS
(SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
	DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
FROM sales_dannys as s
JOIN members_dannys as m
	ON s.customer_id = m.customer_id
WHERE s.order_date >= m.join_date
)

SELECT p.customer_id, p.order_date, m2.product_name
FROM purchase_first_cte p
JOIN menu_dannys m2
	ON p.product_id = m2.product_id
WHERE RANK = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH purchased_before_cte AS
(SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
	DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
FROM sales_dannys as s
JOIN members_dannys as m
	ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
)

SELECT p.customer_id, p.order_date, m2.product_name
FROM purchased_before_cte p
JOIN menu_dannys m2
	ON p.product_id = m2.product_id
WHERE RANK = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(DISTINCT s.product_id) total_item, SUM(m.price) amount_spent
FROM sales_dannys s
JOIN menu_dannys m
ON s.product_id = m.product_id
JOIN members_dannys m2
ON s.customer_id = m2.customer_id
WHERE s.order_date < m2.join_date
GROUP BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?
--- buat temp query untuk define sushi $1 20 point dan selainnya $1 10 point dengan CASE WHEN
WITH points_cte AS
(SELECT *, 
	CASE WHEN product_id = 1 THEN price * 20
	ELSE price * 10
END AS points
FROM menu_dannys)

SELECT s.customer_id, SUM(p.points) total_point
FROM sales_dannys s
JOIN points_cte p
ON s.product_id = p.product_id
GROUP BY s.customer_id;

-- 10.  In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?
WITH date_cte AS
( SELECT *, 
	DATEADD(DAY, 6, join_date) first_week,
	EOMONTH('2021-01-31') last_date
	FROM members_dannys m2)

SELECT d.customer_id,
	SUM(CASE 
		WHEN m.product_name = 'sushi' THEN 2*10*m.price
		WHEN s.order_date BETWEEN d.join_date AND d.first_week THEN 2*10*m.price
		ELSE 10*m.price
		END) points
FROM date_cte d
JOIN sales_dannys s
	ON d.customer_id = s.customer_id
JOIN menu_dannys m
	ON s.product_id = m.product_id
WHERE s.order_Date < d.last_date
GROUP BY d.customer_id
ORDER BY d.customer_id;

-- BONUS QUESTIONS

--- Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
SELECT s.customer_id, s.order_date, m.product_name, m.price,
	(CASE
	WHEN s.order_date >= mm.join_date THEN 'Y'
	ELSE 'N'
	END) member
FROM sales_dannys s
JOIN menu_dannys m
ON s.product_id = m.product_id
JOIN members_dannys mm
ON s.customer_id = mm.customer_id;

--- Rank All The Things - Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
WITH summary_cte AS
(SELECT s.customer_id, s.order_date, m.product_name, m.price,
	(CASE
	WHEN s.order_date >= mm.join_date THEN 'Y'
	ELSE 'N'
	END) member
FROM sales_dannys s
JOIN menu_dannys m
ON s.product_id = m.product_id
JOIN members_dannys mm
ON s.customer_id = mm.customer_id)

SELECT *, CASE 
WHEN member = 'N' then NULL 
ELSE RANK () OVER(PARTITION BY customer_id, member ORDER BY order_date) 
END AS ranking 
FROM summary_cte;
