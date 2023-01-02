DROP TABLE IF EXISTS goldusers_signup
CREATE TABLE goldusers_signup 
(userid integer,
gold_signup_date date)

INSERT INTO goldusers_signup VALUES 
(1,'09-22-2017'),
(3,'04-21-2017')

DROP TABLE IF EXISTS users
CREATE TABLE users
(userid integer,
signup_date date)

INSERT INTO users VALUES 
(1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014')

DROP TABLE IF EXISTS sales;
CREATE TABLE sales
(userid integer,
created_date date,
product_id integer)

INSERT INTO sales VALUES 
(1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3)


DROP TABLE IF EXISTS product;
CREATE TABLE product
(product_id integer,
product_name text,
price integer)

INSERT INTO product VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330)

SELECT *
FROM sales

SELECT *
FROM product

SELECT *
FROM goldusers_signup

SELECT *
FROM users


--What is the total amount each customer spent on Zomato?
SELECT a.userid, SUM(b.price) total_amt_spent
FROM sales a
	INNER JOIN product b
	ON a.product_id=b.product_id
GROUP BY a.userid



--How many days has each customer visited Zomato?
SELECT userid, COUNT(DISTINCT created_date) total_cust_visit
FROM sales
GROUP BY userid



--What was the first product purchased by each customer?
SELECT a.* 
FROM
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk
FROM sales) a
WHERE a.rnk=1



--What is the most purchased item on the the menu and how many times was it purchased by all customers?
SELECT userid, COUNT(product_id) cnt
FROM sales
WHERE product_id=
(SELECT TOP 1 product_id
FROM sales
GROUP BY product_id
ORDER BY COUNT(product_id) DESC)
GROUP BY userid



--Which item was the most popular for each customer?
SELECT b.*
FROM
(SELECT a.*, RANK() OVER(PARTITION BY a.userid ORDER BY a.cnt DESC) rnk
FROM 
(SELECT userid, product_id, COUNT(product_id) cnt
FROM sales
GROUP BY userid, product_id) a) b
WHERE b.rnk=1



--Which item was purchsed first by the customer after they became a member?
SELECT d.*
FROM
(SELECT c.*, RANK() OVER(PARTITION BY c.userid ORDER BY c.created_date) rnk
FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
	INNER JOIN goldusers_signup b
	ON a.userid=b.userid
	AND a.created_date>=b.gold_signup_date) c) d
WHERE d.rnk=1



--Which item was purchased just before the customer became a member?
SELECT d.*
FROM
(SELECT c.*, RANK() OVER(PARTITION BY c.userid ORDER BY c.created_date DESC) rnk
FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
	INNER JOIN goldusers_signup b
	ON a.userid=b.userid
	AND a.created_date<=b.gold_signup_date) c) d
WHERE d.rnk=1



--What is the total orders and amount spent for each member before they became a member?
SELECT e.userid, COUNT(e.created_date) total_orders, SUM(e.price) total_amt_spent
FROM
(SELECT c.*, d.price 
FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
	INNER JOIN goldusers_signup b
	ON a.userid=b.userid
	AND a.created_date<=b.gold_signup_date) c
	INNER JOIN product d
	ON c.product_id=d.product_id) e
GROUP BY e.userid



/*If buying each product generates points, for ex 5 rupees=2 zomato 
points, and each product has different purchasing points, for example
p1 5 rupees=1 zomato point, p2 10 rupees=5 zomato points (2 rupees=1 zomato point), 
and p3 5 rupees=1 zomato point*/

--Calculate points collected by each customer and for which product most points have been given till now
SELECT f.userid, SUM(f.total_points)*2.5 total_money_earned
FROM
(SELECT e.*, amt/points total_points
FROM
(SELECT d.*,
	CASE WHEN product_id=1 THEN 5 
	WHEN product_id=2 THEN 2
	WHEN product_id=3 THEN 5
	ELSE 0 END points
FROM
(SELECT c.userid, c.product_id, SUM(c.price) amt
FROM
(SELECT a.*, b.price
FROM sales a
	INNER JOIN product b
	on a.product_id=b.product_id) c
GROUP BY c.userid, c.product_id) d) e) f
GROUP BY f.userid



SELECT h.*
FROM
(SELECT g.*, RANK() OVER(ORDER BY g.total_points_earned DESC) rnk
FROM
(SELECT f.product_id, SUM(f.total_points) total_points_earned
FROM
(SELECT e.*, amt/points total_points
FROM
(SELECT d.*,
	CASE WHEN product_id=1 THEN 5 
	WHEN product_id=2 THEN 2
	WHEN product_id=3 THEN 5
	ELSE 0 END points
FROM
(SELECT c.userid, c.product_id, SUM(c.price) amt
FROM
(SELECT a.*, b.price
FROM sales a
	INNER JOIN product b
	on a.product_id=b.product_id) c
GROUP BY c.userid, c.product_id) d) e) f
GROUP BY f.product_id) g) h
WHERE h.rnk=1



/*In the first one year after a customer joins the gold program (including their join date), irrespective of what
the customer has purchased, they earn 5 zomato points for every 10 rupees spent (1 rps=0.5 zp)*/

--Who earned more, 1 or 3, and what was their points earning in their first year?
SELECT c.*, d.price*0.5 total_points_earned 
FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
	INNER JOIN goldusers_signup b
	ON a.userid=b.userid
	AND a.created_date>=b.gold_signup_date 
	AND a.created_date<=DATEADD(YEAR,1,gold_signup_date)) c
	INNER JOIN product d
	ON c.product_id=d.product_id



--Rnk all the transactions of the customers
SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk_from_sales
FROM sales



--Rank all the transactions for each member whenever they are a zomato gold member; for every non gold member transaction, mark as na
SELECT d.*,
	CASE WHEN d.rnk=0 THEN 'na'
	ELSE d.rnk END rnkk
FROM
(SELECT c.*, 
	CAST((CASE WHEN c.gold_signup_date IS NULL THEN 0
	ELSE RANK() OVER(PARTITION BY c.userid ORDER BY c.created_date DESC) END) AS varchar) rnk
FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
	LEFT JOIN goldusers_signup b
	ON a.userid=b.userid
	AND a.created_date>=b.gold_signup_date) c) d