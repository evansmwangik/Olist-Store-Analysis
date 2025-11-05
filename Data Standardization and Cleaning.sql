SELECT * FROM olist_customers_dataset;
SELECT * FROM olist_geolocation_dataset;
SELECT * FROM olist_order_items_dataset;
SELECT * FROM olist_order_payments_dataset;
SELECT * FROM olist_order_reviews_dataset;
SELECT * FROM olist_orders_dataset;
SELECT * FROM olist_products_dataset;
SELECT * FROM olist_sellers_dataset;
SELECT * FROM product_category_name_translation;

-- Olist Customers Dataset Cleaning
SELECT * FROM olist_customers_dataset;
-- Cheking any missing customer_id's or repeated id's
SELECT * FROM olist_customers_dataset
WHERE customer_id IS NULL; -- No nulls found

SELECT 
	DISTINCT customer_id,
    COUNT(customer_id)
FROM olist_customers_dataset
GROUP BY customer_id
HAVING COUNT(customer_id)>1; -- No repeated customer Id's

-- Null values across the dataset
SELECT
	SUM(customer_unique_id IS NULL),
    SUM(customer_zip_code_prefix IS NULL),
    SUM(customer_city IS NULL),
    SUM(customer_state IS NULL)
FROM olist_customers_dataset; -- No missing values


-- Checking and cleaning the olist_geolocation_dataset
SELECT * FROM olist_geolocation_dataset;
SELECT
	SUM(geolocation_zip_code_prefix IS NULL),
    SUM(geolocation_lat IS NULL),
    SUM(geolocation_lng IS NULL),
    SUM(geolocation_city IS NULL),
    SUM(geolocation_state IS NULL)
FROM olist_geolocation_dataset; -- No missing values

-- Checking and cleaning the olist_order_items_dataset
SELECT * FROM olist_order_items_dataset;

SELECT
	SUM(order_id IS NULL),
    SUM(order_item_id IS NULL),
    SUM(product_id IS NULL),
    SUM(seller_id IS NULL),
    SUM(shipping_limit_date IS NULL),
    SUM(price IS NULL),
    SUM(freight_value IS NULL)
FROM olist_order_items_dataset; -- NO missing values


-- Checking and cleaning olist_order_payments_dataset
SELECT * FROM olist_order_payments_dataset;
-- CHecking for null values
SELECT
	SUM(order_id IS NULL),
    SUM(payment_sequential IS NULL),
    SUM(payment_type IS NULL),
    SUM(payment_installments IS NULL),
    SUM(payment_value IS NULL)
FROM olist_order_payments_dataset; -- No missing values

-- Checking and cleaning olist_reviews_dataset
SELECT * FROM olist_order_reviews_dataset;
-- Checking for any repeated review ids
SELECT 
	DISTINCT review_id,
    COUNT(review_id)
FROM olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(review_id)>1; 

WITH repeat_review_ids AS
(
SELECT 
	*,
	COUNT(*) OVER(PARTITION BY review_id ORDER BY review_creation_date) appearances
FROM olist_order_reviews_dataset
)
SELECT * FROM olist_order_reviews_dataset
WHERE review_id IN (SELECT review_id FROM repeat_review_ids WHERE appearances >1)
ORDER BY review_id
;
-- Some repeated review id's identified for different orders. We'll keep one in each case and drop any other duplicated one since the review_ids should be unique.
-- Duplicating the reviews dataset
CREATE TABLE olist_order_reviews_copy1
LIKE olist_order_reviews_dataset;

INSERT INTO olist_order_reviews_copy1
SELECT * FROM olist_order_reviews_dataset;

SET SQL_SAFE_UPDATES = 0;
SET SESSION net_read_timeout = 600;

DELETE t1
FROM olist_order_reviews_copy1 AS t1
INNER JOIN (
    SELECT
        review_id,
        order_id,
        ROW_NUMBER() OVER(PARTITION BY review_id ORDER BY review_creation_date) AS rn
    FROM
        olist_order_reviews_copy1
) AS t2 
	ON t1.review_id = t2.review_id AND t1.order_id = t2.order_id
WHERE t2.rn > 1;

SELECT 
	DISTINCT review_id,
    COUNT(review_id)
FROM olist_order_reviews_copy1
GROUP BY review_id
HAVING COUNT(review_id)>1; -- Deletion successful

SELECT * FROM olist_order_reviews_copy1;

SELECT * FROM olist_order_reviews_copy1
WHERE review_score IS NULL OR review_creation_date IS NULL OR review_answer_timestamp IS NULL; -- No nulls found in the three columns


-- Checking and cleaning olist_orders_dataset
SELECT * FROM olist_orders_dataset;
-- Checking repeated Ids
SELECT 
	DISTINCT order_id,
    COUNT(order_id)
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(order_id)>1; -- No duplicated order_ids

SELECT
	SUM(order_id IS NULL),
    SUM(customer_id IS NULL),
    SUM(order_status IS NULL),
    SUM(order_purchase_timestamp IS NULL),
    SUM(order_approved_at IS NULL),
    SUM(order_delivered_carrier_date IS NULL),
    SUM(order_delivered_customer_date IS NULL),
    SUM(order_estimated_delivery_date IS NULL)
FROM olist_orders_dataset;
-- We have missing values in the columns order_approved_at (160), order_delivered_carrier_date (1783), order_delivered_customer_date (2965)
-- Investigating the missing values
SELECT * FROM olist_orders_dataset;

SELECT * FROM olist_orders_dataset
WHERE order_approved_at IS NULL; 
SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
WHERE order_approved_at IS NULL
GROUP BY order_status; 
-- 141 orders that were not approved were cancelled, 14 un-approved orders were delivered, 5 unapproved were created

-- Investigating the ones that were delivered but were unapproved
SELECT * FROM olist_orders_dataset
WHERE order_approved_at IS NULL AND order_status = "delivered"; 
SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
WHERE order_approved_at IS NULL AND order_status = "delivered"
GROUP BY order_status; 
-- All the 14 unapproved-delivered orders have the other delivery details provided hence good to proceed for analysis

-- Investigating the created orders
SELECT * FROM olist_orders_dataset
WHERE order_approved_at IS NULL AND order_status = "created"; 
SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
WHERE order_approved_at IS NULL AND order_status = "created"
GROUP BY order_status;
-- These will be treated as unfulfilled orders since they are missing the rest of the details

-- Investigating the cancelled orders
SELECT * FROM olist_orders_dataset
WHERE order_approved_at IS NULL AND order_status = "canceled" AND order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL; 
SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
WHERE order_approved_at IS NULL AND order_status = "canceled"
GROUP BY order_status;
-- All canceled orders do not have delivery information as well which is good

-- order_delivered_carrier_date missing values
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL; 
SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL
GROUP BY order_status;

-- Investigating invoiced
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "invoiced" AND (order_delivered_customer_date IS NOT NULL OR order_approved_at IS NULL);
-- All invoiced orders that lack order_delivered_carrier_date also lack order_delivered_customer_date and none of them were not approved

-- Investigating orders that are processing
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "processing" AND (order_delivered_customer_date IS NOT NULL OR order_approved_at IS NULL);
-- All processing orders that lack order_delivered_carrier_date also lack the order_delivered_customer_date but are all approved.

-- Investigating unavailable orders
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "unavailable" AND (order_delivered_customer_date IS NOT NULL OR order_approved_at IS NULL);
-- All unavailable orders that lack order_delivered_carrier_date also lack the order_delivered_customer_date but are all approved.

-- Canceled Orders
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "canceled" AND (order_delivered_customer_date IS NOT NULL OR order_approved_at IS NULL);
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "canceled" AND (order_delivered_customer_date IS NOT NULL);
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "canceled" AND (order_approved_at IS NULL);
SELECT COUNT(*) FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "canceled" AND (order_approved_at IS NULL);

-- All canceled orders that lack order_delivered_carrier_date also lack the order_delivered_customer_date.
-- 141 cancelled orders that lack order_delivered_carrier_date were approved.

-- Created stand at 5 still as found above

-- Investigating approved and delivered
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "approved" AND (order_delivered_customer_date IS NULL);
-- Two orders found here also lack order_delivered_customer_date but were approved
SELECT * FROM olist_orders_dataset
WHERE order_delivered_carrier_date IS NULL AND order_status = "delivered";
-- Both orders were approved lack the carriers' delivery date and but one has a customers delivery date but lacks the same

-- Investigating order_delivered_customer_date
SELECT * FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL; 
SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL
GROUP BY order_status;

-- Investigating invoiced
SELECT * FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "invoiced" AND (order_delivered_carrier_date IS NOT NULL OR order_approved_at IS NULL);
-- All invoiced orders that lack the order_delivered_customer_date also lack the order_delivered_carrier_date but were approved

-- Investigating shipped
SELECT * FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "shipped" AND (order_delivered_carrier_date IS NOT NULL OR order_approved_at IS NULL);
SELECT COUNT(*) FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "shipped" AND (order_delivered_carrier_date IS NOT NULL OR order_approved_at IS NULL);
-- All shipped orders that lack order_delivered_customer_date have both the order_delivered_carrier_date and the order_approved_at details filled

-- Processing orders stand at 301 as was previously
-- Unavailable stand at 609
-- Investigating canceled
SELECT * FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "canceled" AND (order_delivered_carrier_date IS NOT NULL);
SELECT COUNT(*) FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "canceled" AND (order_delivered_carrier_date IS NOT NULL);
SELECT * FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "canceled" AND (order_approved_at IS NULL);
SELECT COUNT(*) FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL AND order_status = "canceled" AND (order_approved_at IS NOT NULL);
-- 69 orders that lack order_delivered_customer_date details have the order_delivered_carrier_date filled - signifying they were cancelled after shipping
-- 478 orders were approved then later cancelled


-- olist_products_dataset
SELECT * FROM olist_products_dataset;
-- Checking repeated Ids
SELECT 
	DISTINCT product_id,
    COUNT(product_id)
FROM olist_products_dataset
GROUP BY product_id
HAVING COUNT(product_id)>1; -- No duplicated product_ids

SELECT
	SUM(product_id IS NULL),
    SUM(product_category_name IS NULL),
    SUM(product_name_lenght IS NULL),
    SUM(product_description_lenght IS NULL),
    SUM(product_photos_qty IS NULL),
    SUM(product_weight_g IS NULL),
    SUM(product_length_cm IS NULL),
    SUM(product_height_cm IS NULL),
    SUM(product_width_cm IS NULL)
FROM olist_products_dataset;
-- 610 products lack the product category name etc. We'll keep the products but keep these in mind

-- olist_sellers_dataset
SELECT * FROM olist_sellers_dataset;
-- Checking repeated Ids
SELECT 
	DISTINCT seller_id,
    COUNT(seller_id)
FROM olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(seller_id)>1; -- No duplicated seller_ids

SELECT
	SUM(seller_id IS NULL),
    SUM(seller_zip_code_prefix IS NULL),
    SUM(seller_city IS NULL),
    SUM(seller_state IS NULL)
FROM olist_sellers_dataset; -- No seller Data missing







































