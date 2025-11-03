# Olist-Store-Analysis

# Table of Contents
1. Overview
2. Data Cleaning and Understanding
3. Analysis

## Overview
- In this dateset, I go through the performance of an online retail store in Brazil to gather insights on its operation for data the data provided running from a part of 2016 to a bigger part of 2018.

## Data Cleaning and Understanding
- I go through each dataset provided and find the following issues in the below listed datasets:
#### olist_order_reviews_dataset
- Some reviews are repeated for different orders made by customers.
- After running the below query, which basically checks repeated review ids' for all the listed review and the orders they were raised for, I find quite a number of repeated review ids' which should ideally not be the case. 
  ```sql
  SELECT 
  	DISTINCT review_id,
      COUNT(review_id)
  FROM olist_order_reviews_dataset
  GROUP BY review_id
  HAVING COUNT(review_id)>1; 
  ```
  
  <img width="392" height="350" alt="image" src="https://github.com/user-attachments/assets/af7565c8-b817-4b57-a6ac-e011d70151e9" />

- 789 of 99224 ids have been repeated
  ```sql
  SELECT COUNT(*) FROM olist_order_reviews_dataset;
  
  WITH repeated_ids AS
  (
  SELECT 
  	DISTINCT review_id,
      COUNT(review_id)
  FROM olist_order_reviews_dataset
  GROUP BY review_id
  HAVING COUNT(review_id)>1
  )
  SELECT COUNT(*) FROM repeated_ids;
  ```
- To delete them, I first create a copy of the main dataset and it's data,then proceed to drop the repeated ids in the copy, which will be the dataset we are going to work with `olist_order_reviews_copy1`.
  ```sql
  CREATE TABLE olist_order_reviews_copy1
  LIKE olist_order_reviews_dataset;
  
  INSERT INTO olist_order_reviews_copy1
  SELECT * FROM olist_order_reviews_dataset;
  
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
  ``` 
- Successful creation of a usable and accurate dataset.
 
#### olist_orders_dataset
- I found missing values in columns that would ideally have data based on certain conditions in the dataset for this dataset. For example, the orders were classified by some statuses i.e. delivered, cancelled shipped etc...
- For a delivered order, the customer delivery date and time ought to have been provided, for shipped orders, the carrier delivery date ought to have been provided etc. hence the need for data in the necessary columns using the column conditions.
- I had the following query help me find whether there were missing values and invetigated them using the logic flow:
  ```sql
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
  ```
  <img width="1530" height="80" alt="image" src="https://github.com/user-attachments/assets/d12b9626-7016-489c-9cd8-a74efc4ba7ef" />
  
##### order_approved_at
- There were delivered orders(14 in number) that had not been approved, which should have ideally been impossible but they had the rest of the details availed, so I had the same remain in the dataset since the other details can be a used for analysis later.
  - The other statuses that lacked the approval date were `cancelled` and `created`. These are okay.
  ```sql
  SELECT 
  	order_status, 
      COUNT(order_status) 
  FROM olist_orders_dataset
  WHERE order_approved_at IS NULL
  GROUP BY order_status;
  ```
##### order_delivered_carrier_date
- I found the following status missing the order_delivered_carrier date values:
  ```sql
  SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
  WHERE order_delivered_carrier_date IS NULL
  GROUP BY order_status;
  ```

  <img width="255" height="181" alt="image" src="https://github.com/user-attachments/assets/62e6d48a-7569-4467-bcbf-7d20fb36e756" />

  - Upon further investigation of the missing vaues in this column, I found that:
    - All invoiced orders were approved but did not have the customer delivery date. Invoiced orders should mean that they were billed to the customer and ought to have been delivered.
    - All orders under processing also lack the customer delivery date, which is okay.
    - All unavailable orders are approved which should not have been the case. Their status should have been cancelled since that should mean the product being orderd was unavailable.
    - All canceled orders lacked the carrier delivery date which is good.
    - Created orders are only five and they also lack the carrier delivery date.
    - Approved orders that lacked values in this column also did no have the customer delivery date which is good.
    - Delivered orders found are approved, and one lacks the customer date delivery date and time. If the products were delivered, the missing data ought to have been provided.
  - No data is dropped from this process and findings. Conditions can be used later to query data according to what we need.
   
##### order_delivered_carrier_date
- The following statuses were missing vaues from this column:
  ```sql
  SELECT order_status, COUNT(order_status) FROM olist_orders_dataset
  WHERE order_delivered_customer_date IS NULL
  GROUP BY order_status;
  ```

  <img width="252" height="199" alt="image" src="https://github.com/user-attachments/assets/67b1cda5-0faf-4fb3-88c1-e1d08145a58b" />

  - Findings:
    - All approved orders lacking values in this column also lack values in the carrier delivery date column. This is okay.
    - All shipped orders lack values in this column but are approved and all have the carrier delivery date values. Good.
    - Processing orders and unavailable stand as analysed previously. Good.
    - 69 cancelled orderslack values in this column but have the carrier delivery date filled signifying that they were cancelled after shipping.
      - 478 orders were approved then later cancelled.
  - No rows or columns were dropped. The data in the column can be filtered using logical operators while querying data.
    
  ##### olist_products_dataset
  - 610 out of 32951 lack the name of the product

- All the other datasets, attached in this repositiry, had their data standardized and ready for analysis.


### Analysis
#### Store Performance
There are 99441 orders in the whole dataset - All statuses included. Below is an image of the breakdown by status:

<img width="202" height="203" alt="image" src="https://github.com/user-attachments/assets/69ed1704-3c6d-4ef7-896c-01723ac6d180" />

> The actual sales made can only be determined by the deliveries made since we do not have information on when the payment for the products are made. Also, actual sales should be considered when the customer actually received the product.





  

  

  
  
  
  


