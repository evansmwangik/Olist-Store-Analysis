-- Total number of orders
SELECT COUNT(*) FROM olist_orders_dataset;
-- There are 99441 orders in total
SELECT 
	order_status, 
    COUNT(order_status) orders_count
FROM olist_orders_dataset
GROUP BY order_status;


-- No. of items ordered over time
SELECT 
	COUNT(*) order_count
FROM olist_order_items_dataset;
-- The number of items ordered overtime are 112650 products

-- Total No. of Products offered
SELECT COUNT(*) product_count FROM olist_products_dataset;
-- There are 32951 products being offered

-- Total No. of customers that ordered in the platform
SELECT COUNT(DISTINCT customer_unique_id) unique_customers FROM olist_customers_dataset;
-- There are 96096 unique customers that used the platform

-- No. of repeat customers
WITH repeat_customers AS
(
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY customer_unique_id) rc
FROM olist_customers_dataset
)
SELECT 
	COUNT(DISTINCT customer_unique_id) unique_customers,
    ROUND(COUNT(DISTINCT customer_unique_id)/(SELECT COUNT(DISTINCT customer_unique_id) FROM olist_customers_dataset)*100, 2) repeat_percentage
FROM repeat_customers
WHERE rc > 1
;
-- There are 2997 repeat customers out of the total unique 96096 customers.That's only about 3% of the total no. of customers in the platform

-- No. of sellers in the platform
SELECT COUNT(*) sellers_count FROM olist_sellers_dataset;
-- There are 3095 sellers in the platform

-- Sales Years covered in the dataset
SELECT DISTINCT YEAR(order_purchase_timestamp) years
FROM olist_orders_dataset
ORDER BY YEAR(order_purchase_timestamp);
-- We are working with data for the years 2016 to 2018



-- Financials
-- Yearly sales made
	-- Which year leads by sales made
-- Monthly breakdown
	-- Leading months by sales for all the years
    -- Trailing 3 months by sales for all the years
-- Who sells the most and by how much
-- What are the sipping rates to various regions from various regions
-- What is the highest selling product
-- Which cusotmer has used the platfor the most
-- Provide insights using a summary of the reviews given o products

/* Yearly Sales Overview*/
SELECT * FROM olist_order_items_dataset;
-- Total Sales
SELECT 
	ROUND(SUM(price), 2) 
FROM olist_order_items_dataset;
-- Sales made over the 3 years 13,591,643.7 -- For all statuses including unfulfilled

-- Confirmed delivered orders
SELECT 
	ROUND(SUM(t1.price), 2) total_sales,
    ROUND((SUM(t1.price)/(SELECT SUM(price) FROM olist_order_items_dataset))*100, 2) percentage
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered";
-- Delivered orders sales 13,221,498.11
-- 97% of all the sales amount previously identified are from delivered orders

-- Yearly Breakdown
SELECT * FROM olist_orders_dataset;
SELECT 
	YEAR(t2.order_purchase_timestamp) `year`,
	ROUND(SUM(t1.price), 2) total_sales
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered"
GROUP BY YEAR(t2.order_purchase_timestamp)
ORDER BY ROUND(SUM(t1.price), 2) DESC;
-- There was a progressive increase in sales from year to year going by the sum of product sales of the orders delivered
-- 2018 leads in sales despite not having the fill dataset for the year provided. The last month of the data provided is October

-- The first order month in 2016
SELECT DISTINCT MONTH(order_purchase_timestamp)
FROM olist_orders_dataset
WHERE YEAR(order_purchase_timestamp) = 2016
ORDER BY MONTH(order_purchase_timestamp);
-- 2016 orders start from September so we cannot conclusively say if there was any kind of growth from 2016 to 2017

SELECT DISTINCT MONTH(order_purchase_timestamp)
FROM olist_orders_dataset
WHERE YEAR(order_purchase_timestamp) = 2017
ORDER BY MONTH(order_purchase_timestamp) DESC; -- 2017 has all months data provided

SELECT DISTINCT MONTH(order_purchase_timestamp)
FROM olist_orders_dataset
WHERE YEAR(order_purchase_timestamp) = 2018
ORDER BY MONTH(order_purchase_timestamp) DESC; -- 2018 has data for upto month 10 from month 1

-- Leading Months by sales in the months with complete data
WITH leading_months_yearly AS
(
SELECT 
	YEAR(t2.order_purchase_timestamp) `year`,
    MONTH(t2.order_purchase_timestamp) `month`,
	ROUND(SUM(t1.price), 2) total_sales,
    RANK() OVER(PARTITION BY YEAR(t2.order_purchase_timestamp) ORDER BY SUM(t1.price) DESC) mr
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered" AND MONTH(t2.order_purchase_timestamp) != 12 AND MONTH(t2.order_purchase_timestamp) != 11
GROUP BY YEAR(t2.order_purchase_timestamp), MONTH(t2.order_purchase_timestamp)
ORDER BY  YEAR(t2.order_purchase_timestamp)
)
SELECT *  FROM leading_months_yearly
WHERE mr <= 3
;
-- No general trend by months seeing that the leading months leading in sales in 2017 are not consistent with the ones in 2018
-- Even while excluding the last two months of the year from 2017, there is no general trend

-- Trailing 3 months
WITH trailing_months_yearly AS
(
SELECT 
	YEAR(t2.order_purchase_timestamp) `year`,
    MONTH(t2.order_purchase_timestamp) `month`,
	ROUND(SUM(t1.price), 2) total_sales,
    RANK() OVER(PARTITION BY YEAR(t2.order_purchase_timestamp) ORDER BY SUM(t1.price)) mr
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered"
GROUP BY YEAR(t2.order_purchase_timestamp), MONTH(t2.order_purchase_timestamp)
ORDER BY  YEAR(t2.order_purchase_timestamp)
)
SELECT *  FROM trailing_months_yearly
WHERE mr <= 3
;
-- Also no overall trend. Only that February appears twice in two years

-- Number of items purchased within the years
SELECT
	COUNT(*)
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered"
;
-- 110197 orders generally sold, including the ones in the few months of 2016

WITH leading_months_yearly AS
(
SELECT 
	YEAR(t2.order_purchase_timestamp) `year`,
    MONTH(t2.order_purchase_timestamp) `month`,
	COUNT(*) items_count,
    RANK() OVER(PARTITION BY YEAR(t2.order_purchase_timestamp) ORDER BY COUNT(*) DESC) count_rank
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered"
GROUP BY YEAR(t2.order_purchase_timestamp), MONTH(t2.order_purchase_timestamp)
ORDER BY  YEAR(t2.order_purchase_timestamp)
)
SELECT *  FROM leading_months_yearly
WHERE count_rank <= 3
;
-- High item count does not mean higher sales amount
-- In both years, 2017 and 2018, the month order trend does not match the trend for total sales amount. 2018 is the biggest indicator of this.

-- Trailing months by items count
WITH trailing_months_yearly AS
(
SELECT 
	YEAR(t2.order_purchase_timestamp) `year`,
    MONTH(t2.order_purchase_timestamp) `month`,
	COUNT(*) items_count,
    RANK() OVER(PARTITION BY YEAR(t2.order_purchase_timestamp) ORDER BY COUNT(*)) count_rank
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered"
GROUP BY YEAR(t2.order_purchase_timestamp), MONTH(t2.order_purchase_timestamp)
ORDER BY  YEAR(t2.order_purchase_timestamp)
)
SELECT *  FROM trailing_months_yearly
WHERE count_rank <= 3
;


-- Sellers Performance
-- To sellers
SELECT 
	DISTINCT t2.seller_id,
    SUM(t1.price) total_rev
FROM olist_order_items_dataset t1
JOIN olist_sellers_dataset t2
	ON t1.seller_id = t2.seller_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY t2.seller_id
ORDER BY total_rev DESC
;

WITH top_sellers_yearly AS
(
SELECT 
	DISTINCT t2.seller_id,
	YEAR(t3.order_purchase_timestamp),
    ROUND(SUM(t1.price), 2) total_rev,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY SUM(t1.price) DESC) sr
FROM olist_order_items_dataset t1
JOIN olist_sellers_dataset t2
	ON t1.seller_id = t2.seller_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY t2.seller_id,YEAR(t3.order_purchase_timestamp)
ORDER BY YEAR(t3.order_purchase_timestamp)
)
SELECT * FROM top_sellers_yearly
WHERE sr <= 3
;

WITH top_sellers_yearly AS
(
SELECT 
	DISTINCT t2.seller_id,
	YEAR(t3.order_purchase_timestamp),
    ROUND(SUM(t1.price), 2) total_rev,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY SUM(t1.price) DESC) sr
FROM olist_order_items_dataset t1
JOIN olist_sellers_dataset t2
	ON t1.seller_id = t2.seller_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY t2.seller_id,YEAR(t3.order_purchase_timestamp)
ORDER BY YEAR(t3.order_purchase_timestamp)
)
SELECT DISTINCT seller_id, COUNT(seller_id) FROM top_sellers_yearly
WHERE sr <= 3
GROUP BY seller_id
;
-- Top suppliers changed in all the years. None of them appear twice in the top 3 in all the years


-- Best performing product categories. Top 10
-- How many product categories are present in the dataset
SELECT * FROM olist_products_dataset;
SELECT COUNT(DISTINCT product_category_name) FROM olist_products_dataset;
-- There are 73 item categories in the dataset

-- Best Performing and trailing product categories
SELECT
	DISTINCT t2.product_category_name,
    ROUND(SUM(t1.price), 2) total_rev,
    ROUND((SUM(t1.price)/(SELECT SUM(price) FROM olist_order_items_dataset))*100, 2) total_percentage
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
GROUP BY t2.product_category_name
ORDER BY total_rev DESC;

WITH top_ten_products AS
(
SELECT
	DISTINCT t2.product_category_name,
    YEAR(t3.order_purchase_timestamp) `year`,
    ROUND(SUM(t1.price), 2) total_rev,
    ROUND((SUM(t1.price)/(SELECT SUM(price) FROM olist_order_items_dataset))*100, 2) total_percentage,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY ROUND(SUM(t1.price), 2) DESC) rank_number
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY YEAR(t3.order_purchase_timestamp), t2.product_category_name
ORDER BY YEAR(t3.order_purchase_timestamp) ASC, total_rev DESC
)
SELECT * FROM top_ten_products
WHERE rank_number <=10 AND 
	`year` = 2018 AND 
    product_category_name IN (SELECT product_category_name FROM top_ten_products WHERE rank_number <= 10 AND `year` = 2017)
ORDER BY rank_number
;
-- 8 out of 10 of the leading products in 2017 are also present in the top ten leading products of 2018

-- Bottom 10 products
WITH bottom_ten_products AS
(
SELECT
	DISTINCT t2.product_category_name,
    YEAR(t3.order_purchase_timestamp) `year`,
    ROUND(SUM(t1.price), 2) total_rev,
    ROUND((SUM(t1.price)/(SELECT SUM(price) FROM olist_order_items_dataset))*100, 2) total_percentage,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY ROUND(SUM(t1.price), 2) ASC) rank_number
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY YEAR(t3.order_purchase_timestamp), t2.product_category_name
ORDER BY YEAR(t3.order_purchase_timestamp) ASC, total_rev DESC
)
SELECT * FROM bottom_ten_products
WHERE rank_number <=10 AND 
	`year` = 2018 AND 
    product_category_name IN (SELECT product_category_name FROM bottom_ten_products WHERE rank_number <= 10 AND `year` = 2017)
ORDER BY rank_number
;
-- 5 not good performing products from 2017 are also present in 2018 trailing ones

-- Evaluating why the top products are leading and the trailing ones are trailing
-- Checking the number of items bought, the average value of each product and how they compare
SELECT AVG(price), MAX(price), MIN(price) FROM olist_order_items_dataset;
-- The average price for the whole dataset is $120
SELECT
	DISTINCT t2.product_category_name,
    ROUND(SUM(t1.price), 2) total_rev,
    COUNT(t2.product_category_name) products_count,
    ROUND(AVG(t1.price), 2) avg_price,
    CASE
		WHEN ROUND(AVG(t1.price), 2) <= 40 THEN "low"
		WHEN ROUND(AVG(t1.price), 2) <= 80 THEN "medium"
		WHEN ROUND(AVG(t1.price), 2) <= 200 THEN "high"
        WHEN ROUND(AVG(t1.price), 2) > 200 THEN "very high"
	END AS price_category
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
GROUP BY t2.product_category_name
ORDER BY total_rev DESC;

WITH top_ten_products AS
(
SELECT
	DISTINCT t2.product_category_name,
    YEAR(t3.order_purchase_timestamp) `year`,
    ROUND(SUM(t1.price), 2) total_rev,
    COUNT(t2.product_category_name) products_count,
    ROUND(AVG(t1.price), 2) avg_price,
    CASE
		WHEN ROUND(AVG(t1.price), 2) <= 40 THEN "low"
		WHEN ROUND(AVG(t1.price), 2) <= 80 THEN "medium"
		WHEN ROUND(AVG(t1.price), 2) <= 200 THEN "high"
        WHEN ROUND(AVG(t1.price), 2) > 200 THEN "very high"
	END AS price_category,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY ROUND(SUM(t1.price), 2) DESC) rank_number
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY YEAR(t3.order_purchase_timestamp), t2.product_category_name
ORDER BY YEAR(t3.order_purchase_timestamp) ASC, total_rev DESC
)
SELECT * FROM top_ten_products
WHERE rank_number <=10 AND 
	`year` = 2018 AND 
    product_category_name IN (SELECT product_category_name FROM top_ten_products WHERE rank_number <= 10 AND `year` = 2017)
ORDER BY rank_number
;
-- Most of the leading products have their price between 80 t0 200
-- The quantity of the products bought as well as the price contribute to the ranking of the products in the top 10

SELECT
	DISTINCT t2.product_category_name,
    ROUND(SUM(t1.price), 2) total_rev,
    COUNT(t2.product_category_name) products_count,
    ROUND(AVG(t1.price), 2) avg_price,
    CASE
		WHEN ROUND(AVG(t1.price), 2) <= 40 THEN "low"
		WHEN ROUND(AVG(t1.price), 2) <= 80 THEN "medium"
		WHEN ROUND(AVG(t1.price), 2) <= 200 THEN "high"
        WHEN ROUND(AVG(t1.price), 2) > 200 THEN "very high"
	END AS price_category
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
GROUP BY t2.product_category_name
ORDER BY total_rev;


WITH trailing_ten_products AS
(
SELECT
	DISTINCT t2.product_category_name,
    YEAR(t3.order_purchase_timestamp) `year`,
    ROUND(SUM(t1.price), 2) total_rev,
    COUNT(t2.product_category_name) products_count,
    ROUND(AVG(t1.price), 2) avg_price,
    CASE
		WHEN ROUND(AVG(t1.price), 2) <= 40 THEN "low"
		WHEN ROUND(AVG(t1.price), 2) <= 80 THEN "medium"
		WHEN ROUND(AVG(t1.price), 2) <= 200 THEN "high"
        WHEN ROUND(AVG(t1.price), 2) > 200 THEN "very high"
	END AS price_category,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY ROUND(SUM(t1.price), 2)) rank_number
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY YEAR(t3.order_purchase_timestamp), t2.product_category_name
ORDER BY YEAR(t3.order_purchase_timestamp) ASC, total_rev DESC
)
SELECT * FROM trailing_ten_products
WHERE rank_number <=10 AND 
	`year` = 2018 AND 
    product_category_name IN (SELECT product_category_name FROM trailing_ten_products WHERE rank_number <= 10 AND `year` = 2017)
ORDER BY rank_number
;
WITH trailing_ten_products AS
(
SELECT
	DISTINCT t2.product_category_name,
    YEAR(t3.order_purchase_timestamp) `year`,
    ROUND(SUM(t1.price), 2) total_rev,
    COUNT(t2.product_category_name) products_count,
    ROUND(AVG(t1.price), 2) avg_price,
    CASE
		WHEN ROUND(AVG(t1.price), 2) <= 40 THEN "low"
		WHEN ROUND(AVG(t1.price), 2) <= 80 THEN "medium"
		WHEN ROUND(AVG(t1.price), 2) <= 200 THEN "high"
        WHEN ROUND(AVG(t1.price), 2) > 200 THEN "very high"
	END AS price_category,
    RANK() OVER(PARTITION BY YEAR(t3.order_purchase_timestamp) ORDER BY ROUND(SUM(t1.price), 2)) rank_number
FROM olist_order_items_dataset t1
JOIN olist_products_dataset t2
	ON t1.product_id = t2.product_id
JOIN olist_orders_dataset t3
	ON t1.order_id = t3.order_id
GROUP BY YEAR(t3.order_purchase_timestamp), t2.product_category_name
ORDER BY YEAR(t3.order_purchase_timestamp) ASC, total_rev DESC
)
SELECT * FROM trailing_ten_products
WHERE rank_number <= 10
;
-- The trailing products generally have a low demand. Despite some of the ranking high in terms of pricing.
-- All the trailing categories for each year have less than 26 orders

-- Average delivery time analysis from day of order
SELECT * FROM olist_orders_dataset;

-- Carrier Date
SELECT AVG(TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_carrier_date)) avg_carrier_del_time
FROM olist_orders_dataset
WHERE order_status = "delivered";
-- The average carrier date delivery time for the dataset is 3 days
-- This generally means that the orders are taken to the carrier mostly in and within the 3 days for delivery to the customer

-- Customer Date
SELECT AVG(TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) avg_cust_del_time
FROM olist_orders_dataset
WHERE order_status = "delivered";
-- The average time of delivery for the customers is 12 days from when they make a purchase

-- Average order approval time
SELECT AVG(TIMESTAMPDIFF(hour, order_purchase_timestamp, order_approved_at)) avg_appr_time
FROM olist_orders_dataset
WHERE order_approved_at IS NOT NULL;
-- The average order approval time for all orders is 10 hrs

-- Order delivery time from the carrier
SELECT AVG(TIMESTAMPDIFF(day, order_delivered_carrier_date, order_delivered_customer_date)) avg_cust_del_time
FROM olist_orders_dataset
WHERE order_status = "delivered";
-- Order delivery time from the carriers to the customer is about 9 days

-- Estimate delivery date comparison
SELECT 
	AVG(TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) avg_cust_del_time,
    AVG(TIMESTAMPDIFF(day, order_purchase_timestamp, order_estimated_delivery_date)) avg_est_cust_del_time
FROM olist_orders_dataset
WHERE order_status = "delivered" and order_status IS NOT NULL;
-- The average estimated delivery date from the date of purchase to the customer is 23 days. This is almost twice of what the actual time of delivery is.

-- Orders that may have taken longer to deliver than the averages
WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT COUNT(*)
FROM over_del_avg;
-- 30212 orders exceed the average delivery time, 12 days

WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT AVG(TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) avg_over_del_orders
FROM over_del_avg;

WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT COUNT(TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date)) over_del_orders
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date;
-- 7078 orders had their orders both over the average delivery time for all orders and were delivered later than the expected delivery date

WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT TIMESTAMPDIFF(day, order_estimated_delivery_date, order_delivered_customer_date) over_del_orders
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date
ORDER BY over_del_orders DESC;
-- The highest being an order that was delivered 188 days after the espected delivery date. 6 months

-- Were the orders, approved, and shipped on time
WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT TIMESTAMPDIFF(day, order_purchase_timestamp, order_approved_at) order_appr_time
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date
ORDER BY order_appr_time DESC;

WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT MAX(TIMESTAMPDIFF(day, order_purchase_timestamp, order_approved_at))
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date;
-- All orders delivered afew days after the estimate delivery days were approved within 30 days

WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT TIMESTAMPDIFF(month, order_approved_at, order_delivered_carrier_date) order_del_carr_time
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date
ORDER BY order_del_carr_time DESC;

WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT COUNT(TIMESTAMPDIFF(month, order_approved_at, order_delivered_carrier_date))
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date AND TIMESTAMPDIFF(month, order_approved_at, order_delivered_carrier_date) > 1;
-- All orders that were delivered days after the expected delivery time were shipped to the carrier within 4 months.
-- Only 6 of them were delivered to the carrier later that one month

-- Excluding orders that took longer than 10 days to deliver after they were shipped to the carrier
WITH over_del_avg AS 
(
SELECT 
	*
FROM olist_orders_dataset
WHERE order_status = "delivered"
HAVING TIMESTAMPDIFF(day, order_purchase_timestamp, order_delivered_customer_date) > 13
)
SELECT COUNT(TIMESTAMPDIFF(month, order_delivered_carrier_date, order_delivered_customer_date)) over_order_del
FROM over_del_avg
WHERE order_delivered_customer_date > order_estimated_delivery_date AND TIMESTAMPDIFF(month, order_delivered_carrier_date, order_delivered_customer_date) > 1
ORDER BY over_order_del DESC;
--  218 orders out of 7077 were delivered over 1 month later after their delivery to the carrier


SELECT * FROM olist_orders_dataset;

-- REVIEWS ANALYSIS
SELECT * FROM olist_order_reviews_copy1;
SELECT COUNT(*) FROM olist_order_reviews_copy1;

SELECT AVG(review_score) FROM olist_order_reviews_copy1;
SELECT 
	review_score, 
    COUNT(review_score),
    ROUND((COUNT(review_score)/(SELECT COUNT(*) FROM olist_order_reviews_copy1))*100,2)
FROM olist_order_reviews_copy1
GROUP BY review_score
ORDER BY COUNT(review_score) DESC;












































