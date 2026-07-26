-- DQL CheckPoint

--Display in descending order of seniority the male employees whose net salary (salary + commission) is greater than or equal to 8000. The resulting table should include the following columns: Employee Number, First Name and Last Name, Age, and Seniority

SELECT
	EMPLOYEE_int,
	FIRST_NAME,
	LAST_NAME,
	Age,
	Seniority
FROM (
 SELECT
	*,
	DATEDIFF(YEAR, HIRE_DATE, GETDATE()) AS Seniority,
	DATEDIFF(YEAR, BIRTH_DATE, GETDATE()) AS Age,
	SALARY + COALESCE(COMMISSION, 0) AS net_salary
 FROM EMPLOYEES
 WHERE TITLE IN ('Dr.', 'Mr.')
) AS net_salary
WHERE net_salary >= 8000
ORDER BY Seniority DESC


--Display products that meet the following criteria: (C1) quantity is packaged in bottle(s), (C2) the third character in the product name is 't' or 'T', (C3) supplied by suppliers 1, 2, or 3, (C4) unit price ranges between 70 and 200, and (C5) units ordered are specified (not null). The resulting table should include the following columns: product number, product name, supplier number, units ordered, and unit price.


SELECT
	PRODUCT_REF,
	PRODUCT_NAME,
	SUPPLIER_int,
	UNITS_ON_ORDER,
	UNIT_PRICE
FROM (
	SELECT
	*,
	SUBSTRING(PRODUCT_NAME, 3, 1) AS third_char
FROM PRODUCTS 
) AS table_char
WHERE QUANTITY LIKE ('%bottle%') AND
	third_char IN ('t', 'T') AND
	SUPPLIER_int IN (1, 2, 3) AND
	UNIT_PRICE BETWEEN 70 AND 200 AND
	UNITS_ON_ORDER IS NOT NULL


--Display customers who reside in the same region as supplier 1, meaning they share the same country, city, and the last three digits of the postal code. The query should utilize a single subquery. The resulting table should include all columns from the customer table.


SELECT *
FROM CUSTOMERS
WHERE COUNTRY = (
    SELECT COUNTRY
    FROM SUPPLIERS
    WHERE SUPPLIER_int = 1
)
AND CITY = (
    SELECT CITY
    FROM SUPPLIERS
    WHERE SUPPLIER_int = 1
)
AND RIGHT(POSTAL_CODE, 3) = (
    SELECT RIGHT(POSTAL_CODE, 3)
    FROM SUPPLIERS
    WHERE SUPPLIER_int = 1
);

/*
For each order number between 10998 and 11003, do the following:  
-Display the new discount rate, which should be 0% if the total order amount before discount (unit price * quantity) is between 0 and 2000, 5% if between 2001 and 10000, 10% if between 10001 and 40000, 15% if between 40001 and 80000, and 20% otherwise.
-Display the message "apply old discount rate" if the order number is between 10000 and 10999, and "apply new discount rate" otherwise. 
*/


SELECT
	*,
	CASE 
		WHEN totalPrice BETWEEN 0 AND 2000 THEN 0
		WHEN totalPrice BETWEEN 2001 AND 10000 THEN 0.05
		WHEN totalPrice BETWEEN 10001 AND 40000 THEN 0.1
		WHEN totalPrice BETWEEN 40001 AND 80000 THEN 0.15
		ELSE 0.2
	END AS new_discount
FROM (
	SELECT
		O.ORDER_int,
		SUM(UNIT_PRICE * QUANTITY) AS totalPrice,
		CASE
			WHEN O.ORDER_int BETWEEN 10000 AND 10999 THEN 'apply old discount rate'
			ELSE 'apply new discount rate'
		END AS Message
	FROM ORDERS AS O
	LEFT JOIN ORDER_DETAILS AS OD
		ON O.ORDER_int = OD.ORDER_int
	GROUP BY O.ORDER_int
) AS Distcount_application
WHERE ORDER_int BETWEEN 10998 AND 11003

--Display suppliers of beverage products. The resulting table should display the columns: supplier number, company, address, and phone number.

SELECT DISTINCT
	S.SUPPLIER_int,
	COMPANY,
	ADDRESS,
	PHONE
FROM SUPPLIERS AS S
JOIN PRODUCTS AS P
	ON S.SUPPLIER_int = P.SUPPLIER_int
WHERE CATEGORY_CODE = 1



--Display customers from Berlin who have ordered at most 1 (0 or 1) dessert product. The resulting table should display the column: customer code.

SELECT 
	C.CUSTOMER_CODE
FROM CUSTOMERS AS C
LEFT JOIN ORDERS AS O
    ON C.CUSTOMER_CODE = O.CUSTOMER_CODE
LEFT JOIN ORDER_DETAILS AS OD
    ON O.ORDER_int = OD.ORDER_int
LEFT JOIN PRODUCTS AS P
	ON OD.PRODUCT_REF = P.PRODUCT_REF
WHERE CITY = 'Berlin'
GROUP BY C.CUSTOMER_CODE
HAVING SUM(CASE
        WHEN P.CATEGORY_CODE = 3 THEN 1
        ELSE 0
    END)
<= 1


--Display customers who reside in France and the total amount of orders they placed every Monday in April 1998 (considering customers who haven't placed any orders yet). The resulting table should display the columns: customer number, company name, phone number, total amount, and country.

SELECT
	C.CUSTOMER_CODE,
	COMPANY,
	PHONE,
	COUNTRY,
	SUM(CASE
		WHEN YEAR(ORDER_DATE) = 1998 AND DATENAME(WEEKDAY, ORDER_DATE) = 'Monday' AND DATENAME(MONTH, ORDER_DATE) = 'April'THEN 1
		ELSE 0
	END) AS total_amount
FROM CUSTOMERS AS C
LEFT JOIN ORDERS AS O
	ON O.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE COUNTRY = 'France'
GROUP BY C.CUSTOMER_CODE, COMPANY, PHONE, COUNTRY;

--Display customers who have ordered all products. The resulting table should display the columns: customer code, company name, and telephone number.
WITH rank_table AS (
SELECT 
	CUSTOMER_CODE, 
	COMPANY, 
	PHONE, 
	PRODUCT_REF, 
	ROW_NUMBER () OVER (PARTITION BY CUSTOMER_CODE ORDER BY PRODUCT_REF) AS RANK_ 
FROM ( 
	SELECT DISTINCT 
		C.CUSTOMER_CODE, 
		COMPANY, 
		PHONE, 
		P.PRODUCT_REF 
	FROM CUSTOMERS AS C 
	LEFT JOIN ORDERS AS O 
		ON C.CUSTOMER_CODE = O.CUSTOMER_CODE 
	LEFT JOIN ORDER_DETAILS AS OD 
		ON O.ORDER_int = OD.ORDER_int 
	JOIN PRODUCTS AS P 
		ON OD.PRODUCT_REF = P.PRODUCT_REF
) AS T 
) 
SELECT 
	CUSTOMER_CODE, 
	COMPANY, 
	PHONE 
FROM rank_table 
WHERE RANK_ = ( 
				SELECT 
					COUNT(*) 
				FROM PRODUCTS 
			  )


--Display for each customer from France the number of orders they have placed. The resulting table should display the columns: customer code and number of orders.


SELECT 
	C.CUSTOMER_CODE,
	COUNT(*) AS number_of_orders
FROM CUSTOMERS AS C
JOIN ORDERS AS O
	ON C.CUSTOMER_CODE = O.CUSTOMER_CODE
WHERE COUNTRY = 'France'
GROUP BY C.CUSTOMER_CODE
ORDER BY C.CUSTOMER_CODE


--Display the number of orders placed in 1996, the number of orders placed in 1997, and the difference between these two numbers. The resulting table should display the columns: orders in 1996, orders in 1997, and Difference.


SELECT
	*,
	ABS(orders_in_1996 - orders_in_1997) AS difference
FROM (
	SELECT
		SUM(CASE WHEN YEAR(ORDER_DATE) = 1996 THEN 1 ELSE 0 END) AS orders_in_1996,
		SUM(CASE WHEN YEAR(ORDER_DATE) = 1997 THEN 1 ELSE 0 END) AS orders_in_1997
	FROM ORDERS
) AS diff_table


SELECT * FROM CUSTOMERS
SELECT * FROM EMPLOYEES
SELECT * FROM PRODUCTS
SELECT * FROM ORDER_DETAILS
SELECT * FROM CATEGORIES
SELECT * FROM ORDERS

