# Olist-Store-Analysis

# Table of Contents
1. [Overview](#overview)
2. [Data Cleaning and Understanding](#data-cleaning-and-understanding)
3. [Analysis](#analysis)
4. [Power BI Dashboard](#dashboard-building)

## Overview
- In this dateset, I go through the performance of an online retail store in Brazil to gather insights on its operation for data the data provided running from a part of 2016 to a bigger part of 2018.

Tools Used: SQL, Power BI

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

> The actual sales made can only be determined by the deliveries made since we do not have information on when the payment for the products are/were made. Also, actual sales should be considered when the customer actually received the product.

Number of items ordered overtime and for all order statuses: 112650.

<img width="96" height="52" alt="image" src="https://github.com/user-attachments/assets/53e3bf79-6ba9-40e5-994d-c221081ea354" />

Number of Products offered: 32951.

<img width="111" height="54" alt="image" src="https://github.com/user-attachments/assets/d9edd87d-c51f-48be-a01d-cef68703912a" />

Total Number of Unique Customers: 96096.
Unique Repeat Customers: 2997, About 3% of the all customers

<img width="133" height="54" alt="image" src="https://github.com/user-attachments/assets/18eccee7-70a5-4b1a-9d4e-a661883cbe89" />
</br>
<img width="266" height="60" alt="image" src="https://github.com/user-attachments/assets/cc7d9a09-7477-4ae5-be08-78e780f61944" />

Number of Sellers in the dataset: 3095

<img width="102" height="56" alt="image" src="https://github.com/user-attachments/assets/1d2cdb76-6a2e-4161-b54a-f08889449920" />

Delivered orders sales: 13,221,498.11, covering ~97% of all sales
```sql
SELECT 
	ROUND(SUM(t1.price), 2) total_sales,
    ROUND((SUM(t1.price)/(SELECT SUM(price) FROM olist_order_items_dataset))*100, 2) percentage
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered";
```
Other Facts:
- The highest repeat seller by orders made has done 17 orders. 
- The largest order contains 21 items.
- The higest order ever made in the years covered: $13,440.00
- The biggest seller of all time earning: $226,987.93. For delivered orders only.
- The largest number of sellers and buyers come from Sao Paulo (SP).


##### Yearly Sales & Other Metrics
- 2018 leads in sales made for all delivered orders despite not having all the data for orders made that year.
```sql
SELECT 
	YEAR(t2.order_purchase_timestamp) `year`,
	ROUND(SUM(t1.price), 2) total_sales
FROM olist_order_items_dataset t1
JOIN olist_orders_dataset t2
	ON t1.order_id = t2.order_id
WHERE t2.order_status = "delivered"
GROUP BY YEAR(t2.order_purchase_timestamp)
ORDER BY ROUND(SUM(t1.price), 2) DESC;
```

<img width="146" height="92" alt="image" src="https://github.com/user-attachments/assets/7450301f-d90d-4cff-9510-cbe6c40f78bd" />

- Data quality issues identified during the analysis: 2016 orders data starts from September and goes all the way to December but skips November, which would signify that there were no sales made in November.

- The leading 3 months are not consitent from 2017-2018.
	- The leading 3 months in sales in 2017 are not consistent in 2018.
	```sql
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
	WHERE t2.order_status = "delivered"
	GROUP BY YEAR(t2.order_purchase_timestamp), MONTH(t2.order_purchase_timestamp)
	ORDER BY  YEAR(t2.order_purchase_timestamp)
	)
	SELECT *  FROM leading_months_yearly
	WHERE mr <= 3
	;
	```
	
	<img width="251" height="226" alt="image" src="https://github.com/user-attachments/assets/031399f4-8637-42f0-8bda-5c3f3bc75f75" />

	- Considering that data for the year 2018 covers orders up to October, I did a comparison between the years 2017 and 2018 months upto October for each year and still, no definitive trend was found in the two years.
	- The leading months after exclusion of the November and December months from the dataset in 2017 are October, September then August, while the leading ones in 2018 are May, April and March. Confirming no specific trend identified for the two years.
 	```sql
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
  	```
 	<img width="246" height="200" alt="image" src="https://github.com/user-attachments/assets/ad1af0c2-0b9f-4c18-95cd-e4c5106878d3" />

- The trailing 3 months.
	- Also, no specific trend was consistent in the two months.
 	- The only thing worth noting is that February appeared in both years in the trailing months, and it leads in 2018.
	```sql
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
 	```
 
 	<img width="245" height="222" alt="image" src="https://github.com/user-attachments/assets/9b90701d-42da-4721-b062-824d36ace93e" />

- Leading 3 months by item count
	- 2017 data for the leading 3 months in the year suggest that item purchase for the month meant high sales since the leading months data by revenue is consitent with the sum of bought items.
	- The narrative is altered in 2018 seeing that the trend differs from the revenue sales trend. But 2 of the best performing months by revenue sales are in the top 3 of the leading months by item count.
	```sql
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
	```
 
	<img width="294" height="217" alt="image" src="https://github.com/user-attachments/assets/c105921f-521c-4801-92a0-94405dcb1543" />

	- The trailing months trend for 2017 is consistent with the one identified with the trend for revenue sales for the year, but there is a slight change for the year 2018 where the leading year in revenue sales is replaced by July, with the others remaining the same.
	- Conclusion: Item count is not always directly proportional to revenue sales, but they relate slightly in this dataset since most of the months appearing in the top 3 revenue sales trend also appear in the top 3 order item count trend.

- Best Performing Product categories
	- Here, I try and find the top 10 best performing products in 2017 and look up if any of the leading products in the year are also leading in revenue sales in 2018.
	- I find that 8 out of 10 leading products in 2017 also appear in 2018's leading product list.
	```sql
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
	```

	<img width="535" height="204" alt="image" src="https://github.com/user-attachments/assets/720e6b5f-87e5-4f15-9002-718bbebe68d3" />

	- Further investigation shows that the high ranking products by revenue have price ranges ranging between $80-$200 and their order counts are above 1400.

- Least Performing Product categories
	- Here, I try and find the top 10 least performing products in 2017 and look up if any of them are trailing in the year 2018, by revenue sales.
	- I find that 5 out of 10 trailing products in 2017 also appear in 2018's trailing product list.
	```sql
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
 	```
 
 	<img width="559" height="143" alt="image" src="https://github.com/user-attachments/assets/4d1e8cc8-2670-4488-ac33-b8858482c233" />

	- After investigating, I find most of the trailing products price range ranges from $15 to $65, with one outlier going for $200, and they generally have a low demand.
 	- The five identified have items below 26 items.

- Product Delivery analysis
	- The average time of delivery for all the orders averages at around 12 days.
   	- The estimated time of delivery averages at around 23 days.
   	- This is generally good considering that this would mean that most of the orders reach the clients days before the actual estimated delivery date and time.
   	- However, some orders take longer than that time by great amounts of time. Their analysis are as below:
  	1. 30212 orders were delivered later than the average time found above, 12 days:
 	```sql
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
  	```

  	<img width="90" height="57" alt="image" src="https://github.com/user-attachments/assets/c1a5c4ce-1130-454d-9416-b3228a6adb62" />

  	2. 7078 orders got delivered past the average days of delivery, 12 days, and even got delivered past the expected delivery date.
 	```sql
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
	```
  	- With the worst delivery taking 188 day, 6 month, for it to get delived.
  	- All orders were approved in and within 30 days.
  	- Shipping the orders was done in and witin 4 months, which is quiet long considering that the average time of approval is about 10 hrs. Only 6 orders too longer than a month to be reach the carrier for delivery to the client.
  	- About 218 orders took more than a month to get delivered to the client after they were delivered to the carrier. Generally, the average time of delivery of the order from the carrier to the client is 9 days.

  	<img width="123" height="59" alt="image" src="https://github.com/user-attachments/assets/4fd478d9-594b-498c-8b95-5205f1c77dd0" />

- Reviews: No of reviews 98410 reviews
	- The average of all reviews is 4 which is good considering that rating is out of 5 generally.
 	- 5 star revies lead by a big margin, ~56% followed by 4 star reviews ~19% then 1 star reviews at ~11% and 3 and 2 star reviews follow.
   	
    <img width="151" height="53" alt="image" src="https://github.com/user-attachments/assets/a452bb81-9625-41dc-882b-6d6393ff4199" />
	</br>
	<img width="570" height="175" alt="image" src="https://github.com/user-attachments/assets/16f7c1b1-81a1-4e35-9c4b-47d0382706d1" />


These were my findings while exploring the olist data set for 2017 full data and 2018&2016 partial data. More analysis can be found in the `Analysis` file attached in this repository. Also see the data cleaning file, `Data Cleaning and Standardization`, attached.

### Dashboard Building
- Below are screenshots of dashboards providing more insughts on the the findings above.
- The dashboard was created using Power BI.

##### Financials
<img width="1445" height="809" alt="image" src="https://github.com/user-attachments/assets/5120198c-e78e-4b75-9afd-7de524db2273" />

##### Seller Demographics
<img width="1447" height="810" alt="image" src="https://github.com/user-attachments/assets/3a38baca-098d-421c-aa5e-9ca95c2fb27e" />

##### Customer Demographics
<img width="1450" height="811" alt="image" src="https://github.com/user-attachments/assets/273f9424-06a9-43b2-bc36-95df3c7ca6a7" />


- The dashboard Power BI file has been attached in this repository as `Olist Store Dashboard.pbix` [Olist Store Dashboard](https://github.com/evansmwangik/Olist-Store-Analysis/blob/master/Olist%20Store%20Dashboard.pbix).



This dataset was gotton from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data).
