select * from city;
select * from customers;
select * from products;
select * from sales;

-- 1. How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
    city_name,
    ROUND(population * 0.25, 0) AS coffee_consumers,
    city_rank
FROM
    city
ORDER BY 2 DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2.What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
    ci.city_name, SUM(s.total) AS revenue
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
WHERE
    YEAR(s.sale_date) = 2023
        AND QUARTER(s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY 2 DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. How many units of each coffee product have been sold?
SELECT 
    p.product_name, COUNT(s.sale_id) AS totalOrders
FROM
    sales s
        RIGHT JOIN
    products p ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4. What is the average sales amount per customer in each city?
SELECT 
    ci.city_name,
    SUM(s.total) AS revenue,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND((SUM(s.total) / COUNT(DISTINCT c.customer_id)),
            1) AS AvgSalesPerCustomer
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5. Provide a list of cities along with their populations and estimated coffee consumers.
with city_table as (SELECT 
    city_name, population * 0.25 AS coffee_consumers
FROM
    city),
customer_table as (SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM
    city ci
        JOIN
    customers c ON c.city_id = ci.city_id
GROUP BY ci.city_name)
SELECT 
    c.city_name, c.unique_customers, ci.coffee_consumers
FROM
    city_table ci
        JOIN
    customer_table c ON c.city_name = ci.city_name
ORDER BY ci.coffee_consumers desc;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6. What are the top 3 selling products in each city based on sales volume?
with cte as (SELECT 
    ci.city_name, p.product_name, COUNT(s.sale_id) AS totalsales, rank() over (partition by ci.city_name order by COUNT(s.sale_id) desc) as rn
FROM
    sales s
        JOIN
    products p ON s.product_id = p.product_id
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
    group by 1,2)
    
SELECT 
    city_name, product_name, totalsales
FROM
    cte
WHERE
    rn <= 3;
    
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 7. How many unique customers are there in each city who have purchased coffee products?
SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM
    customers c
        JOIN
    sales s ON s.customer_id = c.customer_id
        JOIN
    city ci ON c.city_id = ci.city_id
WHERE
    s.product_id BETWEEN 1 AND 14
GROUP BY ci.city_name;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. Find each city and their average sale per customer and avg rent per customer
with cte1 as 
(
SELECT 
    ci.city_name,
    SUM(s.total) AS revenue,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND((SUM(s.total) / COUNT(DISTINCT c.customer_id)),
            1) AS AvgSalesPerCustomer
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY revenue DESC
),
cte2 as 
(
select city_name,estimated_rent from city
)
select c1.city_name, c2.estimated_rent, c1.customers, c1.AvgSalesPerCustomer,

round(c2.estimated_rent/c1.customers,2) as avgRentPerCustomer
 from cte1 c1 join cte2 c2 on c1.city_name = c2.city_name;
 
 -- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 9. Calculate the percentage growth (or decline) in sales over different time periods (monthly)

select city_name,month,year,total_sales,concat(round(((total_sales-previous_sale)/previous_sale)*100,1),'%') as MoMPercentage from (
with cte as (
SELECT 
    ci.city_name,
    MONTHNAME(s.sale_date) AS month,
    MONTH(s.sale_date) AS monthNumber,
    YEAR(s.sale_date) AS year,
    SUM(s.total) AS total_sales
FROM
    city ci
        JOIN
    customers c ON c.city_id = ci.city_id
        JOIN
    sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name , MONTHNAME(s.sale_date) , MONTH(s.sale_date) , YEAR(s.sale_date)
ORDER BY ci.city_name , YEAR(s.sale_date) , MONTH(s.sale_date)
)
(select city_name,month,year,total_sales,lag(total_sales,1) over (partition by city_name order by year, monthNumber ) as previous_sale from cte) 
) t;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
with cte1 as 
(
SELECT 
    ci.city_name,
    SUM(s.total) AS revenue,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND((SUM(s.total) / COUNT(DISTINCT c.customer_id)),
            1) AS AvgSalesPerCustomer
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY revenue DESC
),
cte2 as 
(
SELECT 
    city_name,
    estimated_rent AS total_rent,
    (population * 0.25) AS coffee_consumers
FROM
    city
    
)
SELECT 
    c1.city_name,
    c1.revenue,
    c2.total_rent,
    c1.customers,
    c1.AvgSalesPerCustomer,
    c2.coffee_consumers,
    ROUND(c2.total_rent / c1.customers, 2) AS avgRentPerCustomer
FROM
    cte1 c1
        JOIN
    cte2 c2 ON c1.city_name = c2.city_name
    order by c1.revenue desc limit 3;
 
 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- 11. Identify customers who have purchased more than 3 different products.
SELECT 
    s.customer_id,
    c.customer_name,
    COUNT(DISTINCT s.product_id) AS uniqueProductsPurchased
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
GROUP BY s.customer_id , c.customer_name
HAVING COUNT(DISTINCT s.product_id) > 10;
 
 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 12. Identify customers who made purchases in 2023 but did not make any purchases in 2024
with cte as (SELECT DISTINCT
    c.customer_id, c.customer_name, YEAR(s.sale_date) AS year
FROM
    sales s
        JOIN
    customers c ON c.customer_id = s.customer_id
WHERE
    YEAR(s.sale_date) = 2023) ,
cte2 as (SELECT DISTINCT
    c.customer_id, c.customer_name, YEAR(s.sale_date) AS year
FROM
    sales s
        JOIN
    customers c ON c.customer_id = s.customer_id
WHERE
    YEAR(s.sale_date) = 2024)
SELECT 
    c1.customer_id, c1.customer_name
FROM
    cte c1
        LEFT OUTER JOIN
    cte2 c2 ON c1.customer_id = c2.customer_id
WHERE
    c2.customer_id IS NULL;

 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 13. Classify customers into "low spenders," "medium spenders," and "high spenders" based on their total spend.
SELECT 
    c.customer_name,
    SUM(s.total) total,
    CASE
        WHEN SUM(s.total) > 20000 THEN 'High spenders'
        WHEN
            SUM(s.total) > 10000
                AND SUM(s.total) < 20000
        THEN
            'Medium Spenders'
        ELSE 'Low spenders'
    END AS Classification
FROM
    customers c
        JOIN
    sales s ON s.customer_id = c.customer_id
GROUP BY c.customer_name;

 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 14. Calculate year-over-year sales (Jan to Oct) growth for each product.
select year, concat(round(((total-previous)/previous)*100,1),'%') as YoYPercentage from (
with cte as (select year(sale_date) as year, sum(total) as total from sales where month(sale_date) between 1 and 10
group by year(sale_date) order by year) 

select *,lag(total,1) over(order by year) as previous from cte 
) t;

 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 15. Identify products that were never purchased in specific cities.
SELECT 
    ci.city_name, p.product_name
FROM
    city ci
        LEFT JOIN
    customers c ON c.city_id = ci.city_id
        LEFT JOIN
    sales s ON s.customer_id = c.customer_id
        RIGHT JOIN
    products p ON p.product_id = s.product_id
WHERE
    s.sale_id IS NULL;

 -- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 16. Find the top ranked product for each city
with cte as (
select ci.city_name,p.product_name,sum(s.total) as totalsales, rank() over(partition by  ci.city_name order by sum(s.total) desc) as rn
 from sales s join products p on s.product_id = p.product_id 
join customers c on s.customer_id = c.customer_id join city ci on c.city_id = ci.city_id group by  ci.city_name,p.product_name
) 
select city_name,product_name,totalsales from cte where rn=1;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 17. List all sales made on weekends in 2023.
SELECT 
    s.sale_id,
    s.sale_date,
    p.product_name,
    c.customer_name,
    s.total
FROM 
    sales s
JOIN 
    products p ON s.product_id = p.product_id
JOIN 
    customers c ON s.customer_id = c.customer_id
WHERE 
    YEAR(s.sale_date) = 2023
    AND DAYOFWEEK(s.sale_date) IN (1, 7); 
