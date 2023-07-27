SELECT DISTINCT market
FROM dim_customer
WHERE customer = "Atliq Exclusive"
AND region = "APAC";

-- Request 2

WITH cte1 AS
(
SELECT COUNT(DISTINCT product_code) AS unique_products_2020
FROM fact_sales_monthly
WHERE fiscal_year = 2020
),
cte2 AS
(
SELECT COUNT(DISTINCT product_code) AS unique_products_2021
FROM fact_sales_monthly
WHERE fiscal_year = 2021
)
SELECT unique_products_2020,
unique_products_2021,
ROUND((unique_products_2021/unique_products_2020-1) * 100, 2) AS percentage_chg
FROM cte1
cross JOIN 
cte2;

-- Request3
SELECT DISTINCT segment,
COUNT(product_code) AS product_count
FROM 
dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Request 4

WITH product_2020 AS
(
SELECT DISTINCT p.segment,
COUNT(DISTINCT p.product_code) AS product_count_2020
FROM 
dim_product p
JOIN
fact_sales_monthly f
ON p.product_code = f.product_code
WHERE f.fiscal_year = 2020
GROUP BY p.segment
),
product_2021 AS
(
SELECT DISTINCT p.segment,
COUNT(DISTINCT p.product_code) AS product_count_2021
FROM 
dim_product p
JOIN
fact_sales_monthly f
ON p.product_code = f.product_code
WHERE f.fiscal_year = 2021
GROUP BY p.segment
)
SELECT pp.segment,
product_count_2020,
product_count_2021,
(product_count_2021 - product_count_2020) AS difference
FROM product_2020 pp
JOIN
product_2021 pc
ON pp.segment = pc.segment
ORDER BY difference DESC
;
-- Request 5
SELECT p.product_code,
p.product,
m.manufacturing_cost
FROM dim_product p
JOIN
fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost) 
OR
m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

-- Request 6
SELECT c.customer_code,
c.customer,
pre.pre_invoice_discount_pct AS average_discount_percentage
FROM
dim_customer c
JOIN 
fact_pre_invoice_deductions pre
ON c.customer_code = pre.customer_code
WHERE pre.fiscal_year = 2021
AND c.market = "India"
AND pre.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions)
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- Request 7
SELECT f.fiscal_year AS year,
f.date AS month,
ROUND(SUM(g.gross_price * f.sold_quantity)/1000000,2) AS gross_sales_amount
FROM 
dim_customer c
JOIN
fact_sales_monthly f
ON c.customer_code = f.customer_code
JOIN
fact_gross_price g
ON f.product_code = g.product_code
-- AND f.fiscal_year = g.fiscal_year
WHERE c.customer = "Atliq Exclusive"
GROUP BY f.date, f.fiscal_year
ORDER BY year, month
;

-- Request 8

WITH cte AS
(
SELECT sold_quantity,
date,
CASE WHEN MONTH(date) IN (9, 10, 11) THEN "Q1"
WHEN MONTH(date) IN (12, 1, 2) THEN "Q2"
WHEN MONTH(date) IN (3, 4, 5) THEN "Q3"
ELSE "Q4"
END AS quarter
 FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2020
)
SELECT 
ROUND(SUM(sold_quantity)/1000000,2) AS total_sold_quantity,
quarter
FROM cte
GROUP BY quarter
ORDER BY total_sold_quantity DESC;

-- Request 9
WITH cte AS
(
SELECT c.channel,
ROUND(SUM(g.gross_price * f.sold_quantity)/1000000,2) AS gross_sales_amount
FROM 
dim_customer c
JOIN
fact_sales_monthly f
ON c.customer_code = f.customer_code
JOIN
fact_gross_price g
ON f.product_code = g.product_code
-- AND f.fiscal_year = g.fiscal_year
WHERE f.fiscal_year = 2021
GROUP BY c.channel
)
SELECT *,
ROUND(gross_sales_amount * 100/SUM(gross_sales_amount) over(), 2) AS percentage
FROM cte
ORDER BY gross_sales_amount DESC
;

-- Request 10
WITH cte1 AS
(
SELECT 
p.division,
p.product_code,
p.product,
p.variant,
SUM(f.sold_quantity) AS total_sold_quantity
FROM 
fact_sales_monthly f
JOIN 
dim_product p
ON p.product_code = f.product_code
WHERE f.fiscal_year = 2021
GROUP BY p.product, p.product_code, p.division, p.variant
),
cte2 AS
(
SELECT 
division,
product_code,
total_sold_quantity,
CONCAT(product,'(',variant,')'),
dense_rank() over (partition by division ORDER BY total_sold_quantity DESC) as drnk
FROM cte1
)
SELECT * FROM
cte2
WHERE drnk <4
;
