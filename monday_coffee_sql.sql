-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- -- -- -- -- -- -- -- -- -- -- MONDAY-COFFEE ANALYSIS -- -- -- -- -- -- -- -- -- -- -- --  
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
USE coffee_db;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

Select 
city_name,
ROUND((population * 0.25 / 1000000),2) as consumers_in_mill
From city
Order by 2 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.2 Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

Select
c.city_name,
SUM(s.total) as total_revenue
From sales as s JOIN 
customers as cx ON
s.customer_id = cx.customer_id
JOIN city as c ON
c.city_id = cx.city_id
Where  EXTRACT(YEAR FROM s.sale_date) = 2023 AND
        EXTRACT(QUARTER FROM s.sale_date) = 4
Group by 1
Order by 2 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
        
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.3 Sales Count for Each Product
-- How many units of each coffee product have been sold?

Select
p.product_name,
COUNT(s.sale_id) as total_orders
From products as p
LEFT JOIN sales as s
ON s.product_id = p.product_id
Group by 1
Order by 2 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.4 Average Sales Amount per City
-- What is the average sales amount per customer in each city?

Select
c.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT cx.customer_id) as unique_cx,
ROUND(SUM(s.total) / COUNT(DISTINCT cx.customer_id),2)  as avg_sales_per_cust
From sales as s JOIN
customers as cx ON
s.customer_id = cx.customer_id
JOIN city as c ON
c.city_id = cx.city_id
Group by 1
Order by 4 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH current_cx as(
Select
c.city_name,
c.population,
COUNT(DISTINCT cx.customer_id) as unique_cx
From city as c JOIN
customers as cx ON
c.city_id = cx.city_id
Group by 1, 2
),
coffee_consumer as(
Select
city_name,
ROUND((population * 0.25/ 1000000),2) as coffee_con_in_mill
From current_cx
)
Select
coffee_consumer.city_name,
current_cx.unique_cx,
coffee_consumer.coffee_con_in_mill
From coffee_consumer JOIN
current_cx ON
coffee_consumer.city_name = current_cx.city_name
Order by 3 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.6 Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

WITH city_table as(
Select 
c.city_name,
p.product_name,
COUNT(s.sale_id) total_orders
From sales as s JOIN
customers as cx ON
s.customer_id = cx.customer_id
JOIN city as c ON
c.city_id = cx.customer_id
JOIN products as p ON
p.product_id = s.product_id
Group by 1, 2
),
ranked_city as(
Select
city_name,
product_name,
total_orders,
ROW_NUMBER() OVER(PARTITION BY city_name ORDER BY total_orders DESC) as rnk
From city_table
)
Select
city_name,
product_name,
total_orders
From ranked_city
Where rnk <=3
Order by 1, 3 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.7 Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

Select
c.city_name,
COUNT(DISTINCT cx.customer_id) as unique_cx
From city as c 
LEFT JOIN customers as cx
ON c.city_id = cx.city_id
JOIN sales as s ON 
s.customer_id = cx.customer_id
Where s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
Group by 1
Order by 2 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.8 Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

Select
c.city_name,
COUNT(DISTINCT cx.customer_id) as unique_cx,
ROUND(SUM(s.total) / COUNT(DISTINCT cx.customer_id),2) as avg_sale_per_cust,
ROUND(MAX(c.estimated_rent) / COUNT(DISTINCT cx.customer_id),2) as avg_rent_per_cust
From sales as s JOIN
customers as cx ON
s.customer_id = cx.customer_id
JOIN city as c ON
c.city_id = cx.city_id
Group by 1
Order by 3 DESC;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
 -- Q.9 Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city

WITH monthly_sales as(
Select
c.city_name,
EXTRACT(MONTH FROM s.sale_date) as month,
EXTRACT(YEAR FROM s.sale_date) as year,
SUM(s.total) as total_sale
From sales as s JOIN 
customers as cx ON
s.customer_id = cx.customer_id
JOIN city as c ON
c.city_id = cx.customer_id
Group by 1, 2, 3
Order by 1, 3, 2 DESC
),
growth_ratio as(
Select
city_name,
month,
year,
total_sale as cr_month_sales,
LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sales
From monthly_sales
)
Select
city_name,
month,
year,
cr_month_sales,
last_month_sales,
ROUND((cr_month_sales - last_month_sales) / last_month_sales * 100 , 2) as growth_ratio
From growth_ratio
Where last_month_sales is not null;
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
-- Q.10 Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table as(
Select
c.city_name,
SUM(s.total) as total_sales,
MAX(c.estimated_rent) as total_rent,
COUNT(DISTINCT cx.customer_id) as unique_cx,
ROUND((c.population * 0.25 / 1000000), 2) as coffee_con_in_mill
From sales as s JOIN customers as cx
ON s.customer_id = cx.customer_id
JOIN city as c ON
c.city_id = cx.city_id
Group by c.city_name, c.population
)
Select
city_name,
total_sales,
total_rent,
unique_cx,
coffee_con_in_mill
From city_table
Order by total_sales DESC;
 -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -
 
 /*
 -- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.















