/*  ------------------ 
CASE STUDY QUESTION
------------------------ */


-- 1. What is the total amount each customer spent at the restaurant? --

SELECT 
    S.customer_id, SUM(price) AS TOTAL_AMOUNT_SPENT
FROM
    sales AS S
        INNER JOIN
    menu AS M ON S.product_id = M.product_id
GROUP BY customer_id;



-- 2. How many days has each customer visited the restaurant? --

SELECT 
    customer_id, COUNT(distinct order_date) AS VISTED_DAYS
FROM
    sales
GROUP BY customer_id



-- 3.What was the first item from the menu purchased by each customer? --

WITH CTE1 AS
(
SELECT SALES.CUSTOMER_ID, MENU.PRODUCT_NAME,
	ROW_NUMBER() OVER (PARTITION BY SALES.CUSTOMER_ID ORDER BY SALES.ORDER_DATE) AS ROW_NUM
FROM 
SALES JOIN MENU
ON
SALES.PRODUCT_ID = MENU.PRODUCT_ID
)
SELECT 
    CUSTOMER_ID, PRODUCT_NAME
FROM
    CTE1
WHERE
    ROW_NUM = 1




-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers? --

SELECT 
    M.PRODUCT_NAME, COUNT(M.PRODUCT_NAME) AS PRODUCT_COUNT
FROM
    SALES AS S
        JOIN
    MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY (PRODUCT_NAME)
ORDER BY COUNT(M.PRODUCT_NAME) DESC
LIMIT 1



-- 5. Which item was the most popular for each customer? --

WITH CTE2 AS
(
	SELECT S.CUSTOMER_ID, M.PRODUCT_NAME, 
	COUNT(*) AS ORDER_COUNT,
		DENSE_RANK() OVER (PARTITION BY S.CUSTOMER_ID ORDER BY COUNT(*) DESC) AS RN
	FROM 
	SALES AS S JOIN MENU AS M 
	ON S.PRODUCT_ID = M.PRODUCT_ID 
	GROUP BY S.CUSTOMER_ID, M.PRODUCT_NAME
)
SELECT CUSTOMER_ID,PRODUCT_NAME
FROM CTE2
WHERE RN = 1



-- 6. Which item was purchased first by the customer after they became a member? --

WITH CTE3 AS
(
	SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, MB.JOIN_DATE,
		DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE) AS RN1
	FROM MENU AS M JOIN SALES AS S 
	ON 
	M.PRODUCT_ID = S.PRODUCT_ID
	JOIN MEMBERS AS MB
	ON 
	S.CUSTOMER_ID = MB.CUSTOMER_ID
	WHERE S.ORDER_DATE > MB.JOIN_DATE
)
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM CTE3
WHERE RN1 = 1;


 -- 7.Which item was purchased just before the customer became a member? --
 
 WITH CTE3 AS
(
 	SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, MB.JOIN_DATE,
		DENSE_RANK() OVER (PARTITION BY CUSTOMER_ID ORDER BY ORDER_DATE DESC) AS RN2
	FROM MENU AS M JOIN SALES AS S 
	ON 
	M.PRODUCT_ID = S.PRODUCT_ID
	JOIN MEMBERS AS MB
	ON 
	S.CUSTOMER_ID = MB.CUSTOMER_ID
	WHERE S.ORDER_DATE < MB.JOIN_DATE
)
SELECT CUSTOMER_ID, PRODUCT_NAME
FROM CTE3
WHERE RN2 = 1;   
    
    
    
 
-- 8.What is the total items and amount spent for each member before they became a member? --

SELECT S.CUSTOMER_ID, S.ORDER_DATE, MB.JOIN_DATE,
	COUNT(M.PRODUCT_ID) AS TOTAL_ITEM_PURCHASED,
	SUM(PRICE) AS TOTAL_AMOUNT_SPENT
FROM SALES AS S JOIN MENU AS M
ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS AS MB
ON S.CUSTOMER_ID = MB.CUSTOMER_ID
WHERE S.ORDER_DATE < MB.JOIN_DATE
group by S.CUSTOMER_ID, S.ORDER_DATE, MB.JOIN_DATE;




-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have? --

WITH CTE4 AS
(
	SELECT S.CUSTOMER_ID, M.PRODUCT_NAME, M.PRICE,
	CASE
	WHEN M.PRODUCT_NAME = 'sushi' THEN m.price*10*2
	ELSE M.PRICE*10
	END AS TOTAL_POINT
	FROM SALES AS S JOIN MENU AS M
	ON
	S.PRODUCT_ID = M.PRODUCT_ID
)
SELECT CUSTOMER_ID, sum(TOTAL_POINT) AS POINTS
FROM CTE4
GROUP BY(CUSTOMER_ID)
ORDER BY POINTS DESC;




 -- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? --
 

 WITH CTE5 AS
(
SELECT 
    S.CUSTOMER_ID, 
    M.PRODUCT_NAME, 
    M.PRICE, 
    S.ORDER_DATE, 
    MB.JOIN_DATE,
    CASE
        WHEN S.ORDER_DATE BETWEEN MB.JOIN_DATE AND DATE_ADD(MB.JOIN_DATE, INTERVAL 7 DAY)
		THEN M.PRICE * 10 * 2
        WHEN M.PRODUCT_NAME = 'sushi'
        THEN M.PRICE * 10 * 2
        ELSE
            M.PRICE * 10 
    END AS POINTS
FROM
    SALES AS S 
JOIN 
    MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN 
    MEMBERS AS MB ON S.CUSTOMER_ID = MB.CUSTOMER_ID
WHERE 
    S.ORDER_DATE < '2021-02-01'
    order by customer_id ASC
)
SELECT CUSTOMER_ID, SUM(POINTS) AS TOTAL_POINT 
FROM CTE5 
GROUP BY CUSTOMER_ID 
ORDER BY CUSTOMER_ID ASC;



-- 11. Determine the name and price of the product ordered by each customer on all order dates & find out whether the customer was a memeber on the order date or not? --

SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, M.PRICE,
CASE
	WHEN MB.JOIN_DATE <= S.ORDER_DATE THEN 'YES'
    ELSE 'NO'
    END AS MEMBERSHIP
FROM 
MENU AS M JOIN SALES AS S 
ON 
M.PRODUCT_ID = S.PRODUCT_ID
LEFT JOIN MEMBERS AS MB
ON 
MB.CUSTOMER_ID = S.CUSTOMER_ID




-- 12. Rank the previous output from Q-11 based on the order_date for each customer. Display NULL if customer was not memeber? --

WITH CTE6 AS
(
SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_NAME, M.PRICE,
CASE
	WHEN MB.JOIN_DATE <= S.ORDER_DATE THEN 'YES'
    ELSE 'NO'
    END AS MEMBERSHIP
FROM 
MENU AS M JOIN SALES AS S 
ON 
M.PRODUCT_ID = S.PRODUCT_ID
LEFT JOIN MEMBERS AS MB
ON 
MB.CUSTOMER_ID = S.CUSTOMER_ID
)
SELECT *,
CASE
	WHEN MEMBERSHIP = 'YES' THEN 
    RANK() OVER (PARTITION BY CUSTOMER_ID, MEMBERSHIP ORDER BY ORDER_DATE)
    ELSE NULL
    END AS RANK_NO
FROM CTE6
