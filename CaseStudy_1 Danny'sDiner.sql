

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

create database dannys_dinner;
use dannys_dinner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
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
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');



/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(m.price) as ta
from sales s
join menu m
on s.product_id=m.product_id
group by customer_id;

--Ans. A-$74, B-$74 and C-$36


-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct(order_date)) as total_visits
from sales
group by customer_id;

--Ans. A-4, B-6 and C-2


-- 3. What was the first item from the menu purchased by each customer?

select customer_id, product_name
from 
	(select s.customer_id, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join menu m
	on s.product_id = m.product_id) as sq
where sq.r=1;
--result shows more than one product since rank based on order date is same.

--Ans. A- Sushi & Curry, B- Curry and C-Ramen


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 m.product_name, count(s.product_id) as cc
from sales s
join menu m
on s.product_id = m.product_id
group by product_name
order by cc desc;

--Ans. Ramen (8 times)


-- 5. Which item was the most popular for each customer?

select customer_id, product_name
from 
	(select s.customer_id, m.product_name, 
	count(s.product_id) as cc,
	dense_rank() over(partition by s.customer_id order by count(s.customer_id) desc) as r
	from sales s
	join menu m
	on s.product_id = m.product_id
	group by s.customer_id, m.product_name) as sq
where sq.r=1;

--Ans. A-Ramen, B-Sushi, Curry & Ramen(all are equal) and C-Ramen

-- 6. Which item was purchased first by the customer after they became a member?

select *
from
	(select s.customer_id, mem.join_date, s.order_date, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join members mem
	on s.customer_id = mem.customer_id
	join menu m
	on s.product_id = m.product_id
	where s.order_date>=mem.join_date) as sq
where sq.r=1;

--Ans. A-Curry and B-Sushi


-- 7. Which item was purchased just before the customer became a member?


select *
from
	(select s.customer_id, mem.join_date, s.order_date, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join members mem
	on s.customer_id = mem.customer_id
	join menu m
	on s.product_id = m.product_id
	where s.order_date<mem.join_date) as sq
where sq.r=1;

--Ans. A-Sushi & Curry and B-Curry


-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id) as total_items, sum(m.price) as amt_spent
from sales s
join members mem
on s.customer_id=mem.customer_id
join menu m
on s.product_id=m.product_id
where s.order_date<mem.join_date
group by s.customer_id;

--Ans. A-$25 for 2 items and B-$40 for 3 items


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id, sum(pt.points) as total_points
from
	(select *,
		case
			when product_id=1 then price*10*2
			else price*10
			end as points
	from menu) as pt
join sales s
on s.product_id=pt.product_id
group by s.customer_id;

--Ans. A-860, B-940 and C-360


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select mdr.customer_id, mdr.join_date, mdr.first_week, mdr.last_date,
	sum(
		case
			when m.product_name='sushi' then m.price*10*2
			when s.order_date between mdr.join_date and mdr.first_week then m.price*10*2
			else m.price*10
			end) as points
from
	(select * , dateadd(day,6,join_date) as first_week, eomonth('2021-01-31') as last_date
	from  members) as mdr
join sales s
on mdr.customer_id=s.customer_id
join menu m
on s.product_id=m.product_id
where s.order_date<mdr.last_date
group by mdr.customer_id, mdr.join_date, mdr.first_week, mdr.last_date;


--Ans. A-1370 and B-820



--Bonus Question: 
--1. Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

select s.customer_id,s.order_date,m.product_name,m.price,
	case
		when mem.join_date>s.order_date then 'N'
		when mem.join_date<=s.order_date then 'Y'
		else 'N'
		end as member
from sales s
left join members mem
on s.customer_id=mem.customer_id
left join menu m
on s.product_id=m.product_id;

--Make sure to use left join to get the required result

--2. Ranking All Things

select *,
	case
		when mm.member='N' then null
		else rank() over(partition by customer_id, member order by order_date)
		end as product_rank

from (select s.customer_id,s.order_date,m.product_name,m.price,
	case
		when mem.join_date>s.order_date then 'N'
		when mem.join_date<=s.order_date then 'Y'
		else 'N'
		end as member
from sales s
left join members mem
on s.customer_id=mem.customer_id
left join menu m
on s.product_id=m.product_id) as mm

























































































































































/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(m.price) as ta
from sales s
join menu m
on s.product_id=m.product_id
group by customer_id;



-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct(order_date))
from sales
group by customer_id


-- 3. What was the first item from the menu purchased by each customer?

select customer_id, product_name
from 
	(select s.customer_id, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join menu m
	on s.product_id = m.product_id) as sq
where sq.r=1
--result shows more than one product since rank based on order date is same.

--Aliter using with function

with sq as
	(select s.customer_id, s.order_date, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join menu m
	on s.product_id = m.product_id)
select customer_id, product_name
from sq
where r=1
group by customer_id, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 m.product_name, count(s.product_id) as cc
from sales s
join menu m
on s.product_id = m.product_id
group by product_name
order by cc desc



-- 5. Which item was the most popular for each customer?

select customer_id, product_name
from 
	(select s.customer_id, m.product_name, 
	count(s.product_id) as cc,
	dense_rank() over(partition by s.customer_id order by count(s.customer_id) desc) as r
	from sales s
	join menu m
	on s.product_id = m.product_id
	group by s.customer_id, m.product_name) as sq
where sq.r=1

--Aliter using with function

with sq as
	(select s.customer_id, m.product_name,
	count(s.product_id) as cc,
	dense_rank() over(partition by s.customer_id order by count(s.customer_id) desc) as r
	from sales s
	join menu m
	on s.product_id = m.product_id
	group by s.customer_id, m.product_name)
select customer_id, product_name
from sq
where r=1
group by customer_id, product_name;

-- 6. Which item was purchased first by the customer after they became a member?

select *
from
	(select s.customer_id, mem.join_date, s.order_date, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join members mem
	on s.customer_id = mem.customer_id
	join menu m
	on s.product_id = m.product_id
	where s.order_date>=mem.join_date) as sq
where sq.r=1



-- 7. Which item was purchased just before the customer became a member?


select *
from
	(select s.customer_id, mem.join_date, s.order_date, m.product_name, 
	dense_rank() over(partition by s.customer_id order by s.order_date) as r
	from sales s
	join members mem
	on s.customer_id = mem.customer_id
	join menu m
	on s.product_id = m.product_id
	where s.order_date<mem.join_date) as sq
where sq.r=1


-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, count(s.product_id) as total_items, sum(m.price) as amt_spent
from sales s
join members mem
on s.customer_id=mem.customer_id
join menu m
on s.product_id=m.product_id
where s.order_date<mem.join_date
group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id, sum(pt.points) as total_points
from
	(select *,
		case
			when product_id=1 then price*10*2
			else price*10
			end as points
	from menu) as pt
join sales s
on s.product_id=pt.product_id
group by s.customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select mdr.customer_id, mdr.join_date, mdr.first_week, mdr.last_date,
	sum(
		case
			when m.product_name='sushi' then m.price*10*2
			when s.order_date between mdr.join_date and mdr.first_week then m.price*10*2
			else m.price*10
			end) as points
from
	(select * , dateadd(day,6,join_date) as first_week, eomonth('2021-01-31') as last_date
	from  members) as mdr
join sales s
on mdr.customer_id=s.customer_id
join menu m
on s.product_id=m.product_id
where s.order_date<mdr.last_date
group by mdr.customer_id, mdr.join_date, mdr.first_week, mdr.last_date




select mdr.customer_id, s.order_date, mdr.join_date, mdr.first_week, mdr.last_date, m.product_name, m.price,
	sum(
		case
			when m.product_name='sushi' then m.price*10*2
			when s.order_date between mdr.join_date and mdr.first_week then m.price*10*2
			else m.price*10
			end) as points
from
	(select * , dateadd(day,6,join_date) as first_week, eomonth('2021-01-31') as last_date
	from  members) as mdr
join sales s
on mdr.customer_id=s.customer_id
join menu m
on s.product_id=m.product_id
where s.order_date<mdr.last_date
group by mdr.customer_id, s.order_date, mdr.join_date, mdr.first_week, mdr.last_date, m.product_name, m.price
