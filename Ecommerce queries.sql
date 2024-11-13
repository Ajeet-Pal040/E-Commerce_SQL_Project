CREATE DATABASE IF NOT EXISTS ECOMMERCE;
/* 
Imported  4 csv data into the database
*/


use ecommerce;

SHOW TABLES;

-- Analyze the tables 
Describe customers;
DESCRIBE ORDERDETAILS;
DESCRIBE PRODUCTS;
DESCRIBE ORDERS;


-- TO IDENTIFY THE KEY MARKET FOR TARGET MARKETING AND LOGISTIC OPTIMIZATION
-- HERE IDENTIFYING THE TOP 3 CITIES 

select location,
            count(customer_id) as number_of_customers 
            from customers
            Group by location
            order by number_of_customers  desc
            limit 3;
            
-- DELHI,CHENNAI AND JAIPUR ARE THE CITIES WHERE WE MUST BE FOCUSED AS A PART OF MARKETING STATERGIES

-- DETERMINING THE CUSTOMERS BASED ON THEIR ORDERS 
SELECT NUMBEROFORDERS
            , COUNT(CUSTOMER_ID) CUSTOMERCOUNT
FROM
(
SELECT CUSTOMER_ID
            ,COUNT(ORDER_DATE) NUMBEROFORDERS
FROM ORDERS
GROUP BY CUSTOMER_ID) ORDER_COUNT
GROUP BY NUMBEROFORDERS
ORDER BY NUMBEROFORDERS;

-- WE CAN  SEE THE TREND OF NUMBEROFORDERS AND CUSTOMERCOUNT  WHICH IS INCRESING ORDERS TENDS TO DECREASES OF CUSTOMER COUNT. 


-- THE COMPANY EXPERIENCE MORE OCCASIONSAL SHOPPERS WHO ARE PLACING ORDER COUNT IS BETWEEN 2 TO 4 
WITH TERMS AS 
(
SELECT NumberOfOrders
		,CASE
			WHEN NumberOfOrders = 1 THEN 'One-Time buyer'
			WHEN NumberOfOrders BETWEEN 2 AND 4 THEN 'Occasional Shoppers'
			ELSE 'Regular Customers'
		END TERMS
FROM	
(
SELECT CUSTOMER_ID
		, COUNT(ORDER_DATE) NumberOfOrders 
FROM ORDERS 
GROUP BY CUSTOMER_ID 
) AS ORDER_COUNT 
) 
SELECT COUNT(NUMBEROFORDERS) AS NUMBEROFORDERS 
	, TERMS
FROM TERMS 
GROUP BY TERMS;


/*
IDENTIFYING THE PRODUCTS WHERE THE AVERAGE PURCHASE QUANTITY PER ORDER IS 2 BUT WITH A HIGH TOTAL REVENUE
 WHICH WILL HELP US TO IDENTIFY THE PREMIUM PRODUCT TRENDS. 
*/
SELECT PRODUCT_ID
            ,AVG(QUANTITY) AVGQUANTITY
            ,SUM(QUANTITY*PRICE_PER_UNIT) TOTALREVENUE            
FROM ORDERDETAILS
GROUP BY PRODUCT_ID
HAVING AVGQUANTITY =2
ORDER BY TOTALREVENUE DESC;
-- PRODUCT 1 & 8 ARE COMING UNDER PREMIUM PRODUCT TRENDS AND PRODUCT 1 IS EXIBITS HIGHEST TOTAL REVENUE


-- IDENTITYING WHICH CATEGORIES HAVE WIDER APPEAL ACROSS THE CUSTOMER BASE 
SELECT  P.CATEGORY
	,COUNT(DISTINCT O.CUSTOMER_ID) UNIQUE_CUSTOMERS
FROM PRODUCTS P 
	JOIN ORDERDETAILS OD 
		ON OD.PRODUCT_ID = P.PRODUCT_ID 
	JOIN ORDERS O 
		ON O.ORDER_ID = OD.ORDER_ID
GROUP BY P.CATEGORY
ORDER BY UNIQUE_CUSTOMERS DESC;
-- ELECTRONICS CATEGORY HAS MOST WIDER APPEAL AMOUNG THE CUSTOMER FOLLOWING BY WEARABLE TECH AND PHOTOGRAPHY
-- THE COMPANY CAN FOCUS MORE ON ELECTRONICS CATEGORY AS IT HAS HIGH DEMAND.


-- Analyzing the month-on-month percentage change in total sales to identify growth trends. 
SELECT MONTH
	,TOTALSALES
	,ROUND(((TOTALSALES- LAG(TOTALSALES) OVER (ORDER BY MONTH))/LAG(TOTALSALES) OVER (ORDER BY MONTH))*100,2) AS PERCENTCHANGE
FROM
	(
	SELECT DATE_FORMAT(ORDER_DATE,'%Y-%m') AS MONTH
			,SUM(TOTAL_AMOUNT)  AS TOTALSALES
	FROM ORDERS
	GROUP BY MONTH
) monthly_sales ;

-- In the Month of the February 2024 the sales declined the most and April 2023 the Sales percentage increase upto 115.97 % 
-- Also the sales percentage are flactuating m-o-m with no clear trend 



-- Checking how the average order value changing month on month. This will help to pricing and promotional strategies to enhance order value . 
SELECT MONTH
            ,AVGORDERVALUE
            ,ROUND(AVGORDERVALUE-LAG(AVGORDERVALUE) OVER (ORDER BY MONTH),2) AS CHANGEINVALUE
FROM
(
SELECT DATE_FORMAT(ORDER_DATE,'%Y-%m') AS MONTH
            ,AVG(TOTAL_AMOUNT)  AS AVGORDERVALUE
FROM ORDERS
GROUP BY MONTH
) AVG_ORDER
ORDER BY CHANGEINVALUE DESC;
-- In the Month of December 2023 there is a highest change in the average order value. 


--  Identifying  products with the fastest turnover rates, suggesting high demand and the need for frequent restocking.
SELECT PRODUCT_ID
	,SALESFREQUENCY 
FROM 
(
SELECT PRODUCT_ID
            ,SUM(QUANTITY *PRICE_PER_UNIT) TOTALSALES
            ,COUNT(PRODUCT_ID) SALESFREQUENCY
FROM ORDERDETAILS
GROUP BY PRODUCT_ID
ORDER BY SALESFREQUENCY DESC 
) ORDER_D
LIMIT 5;
-- Product 7 has the highest turnover rates and it needs to be restocked frequently. 


/*
List products purchased by less than 40% of the customer base, 
indicating potential mismatches between inventory and customer interest.
*/
SELECT PRODUCT_ID
            ,NAME
            ,UNIQUECUSTOMERCOUNT
FROM
(
SELECT P.PRODUCT_ID
	,P.NAME 
	,COUNT( DISTINCT C.CUSTOMER_ID) UNIQUECUSTOMERCOUNT
FROM 
PRODUCTS P 
JOIN ORDERDETAILS OD 
ON OD.PRODUCT_ID = P.PRODUCT_ID 
JOIN ORDERS O 
ON O.ORDER_ID = OD.ORDER_ID
JOIN CUSTOMERS C 
ON C.CUSTOMER_ID = O.CUSTOMER_ID
WHERE P.PRODUCT_ID IS NOT NULL
GROUP BY P.PRODUCT_ID,P.NAME
) Unique_customers

WHERE UNIQUECUSTOMERCOUNT <(0.4* 
(SELECT COUNT(DISTINCT CUSTOMER_ID) AS TOTAL_CUSTOMER
FROM CUSTOMERS));
-- Product 1 & 8 are brought by the unique customers who belongs to 40% of customer pool. 
-- There may be a poor visibility of the product on the platform which is the cause of purchasing rate below 40% 
-- Implement targeted marketing campaigns to raise awarness and interest which can improve the sales. 


-- To understand the effectiveness of marketing campaigns and market expansion efforts evaluating the month-on-month growth rate in the customer base
SELECT FirstPurchaseMonth
	,COUNT(DISTINCT CUSTOMER_ID) TOTALNEWCUSTOMERS
FROM
	(
	SELECT CONCAT(YEAR(ORDER_DATE),'-',DATE_FORMAT(ORDER_DATE,'%m')) PURCHASE_MONTH
		, CUSTOMER_ID 
		,First_value(CONCAT(YEAR(ORDER_DATE),'-',DATE_FORMAT(ORDER_DATE,'%m'))) 
			over (PARTITION BY CUSTOMER_ID ORDER BY CONCAT(YEAR(ORDER_DATE),'-',DATE_FORMAT(ORDER_DATE,'%m'))  ) AS FirstPurchaseMonth
	FROM ORDERS 
	ORDER BY CUSTOMER_ID
	)CUSTOMER_WISE_FIRSTPURCHASE_MONTH
GROUP BY FirstPurchaseMonth
ORDER BY FirstPurchaseMonth;
-- Customer growth is in downward trend which means the marketing campaign are not effective. 


-- Planning for stock levels, marketing efforts, and staffing in anticipation of peak demand periods identifying the months with the highest sales volume.
SELECT CONCAT(YEAR(ORDER_DATE),'-',DATE_FORMAT(ORDER_DATE,'%m')) MONTH
            ,SUM(TOTAL_AMOUNT) AS TOTALSALES
FROM ORDERS 
GROUP BY MONTH 
ORDER BY TOTALSALES DESC
LIMIT 3;


-- As per the data we need to require major restocking of product and increased staffs in the month of September and December.


