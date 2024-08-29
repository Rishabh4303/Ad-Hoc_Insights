
#1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select 
	distinct market 
from dim_customer
where customer="Atliq Exclusive" and region="APAC";



#2. What is the percentage of unique product increase in 2021 vs. 2020?
SELECT 
	X.A AS unique_product_2020, 
	Y.B AS unique_products_2021, 
    ROUND((B-A)*100/A, 2) AS percentage_chg
FROM
     (
      (SELECT COUNT(DISTINCT(product_code)) AS A FROM fact_sales_monthly
      WHERE fiscal_year = 2020) X,
      (SELECT COUNT(DISTINCT(product_code)) AS B FROM fact_sales_monthly
      WHERE fiscal_year = 2021) Y 
	 );
     
     
     
#3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
select
	segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;



#4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
WITH CTE1 AS 
	(SELECT P.segment AS A , COUNT(DISTINCT(FS.product_code)) AS B 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2020"),
CTE2 AS
    (
	SELECT P.segment AS C , COUNT(DISTINCT(FS.product_code)) AS D 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2021"
    )     
    
SELECT CTE1.A AS segment, 
	   CTE1.B AS product_count_2020, 
	   CTE2.D AS product_count_2021, (CTE2.D-CTE1.B) AS difference  
FROM CTE1, CTE2
WHERE CTE1.A = CTE2.C ;



#5. Get the products that have the highest and lowest manufacturing costs.
select 
	c.product_code,
    c.manufacturing_cost,
    p.product,
    p.segment
from fact_manufacturing_cost c
join dim_product p
on c.product_code=p.product_code
where manufacturing_cost 
in (
	select max(manufacturing_cost) from fact_manufacturing_cost
    union
    select min(manufacturing_cost) from fact_manufacturing_cost
	)
order by manufacturing_cost desc;



#6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
select 
	fp.customer_code,
    dc.customer,
    round(avg(fp.pre_invoice_discount_pct)*100,2) as avg_discount_pct
from fact_pre_invoice_deductions fp
join dim_customer dc
on dc.customer_code=fp.customer_code
where fp.fiscal_year=2021 and dc.market="India"
group by fp.customer_code
order by avg_discount_pct desc
limit 5;



#7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions.
select
    concat(monthname(s.date),' (',year(s.date),')') as month,
    s.fiscal_year as fiscal_year,
    round(sum(s.sold_quantity*gp.gross_price),2) as gross_sales_amt
from fact_sales_monthly s
join fact_gross_price gp 
on gp.product_code=s.product_code
join dim_customer c
on c.customer_code=s.customer_code
where c.customer="Atliq Exclusive"
group by month, s.fiscal_year
order by s.fiscal_year;



#8. In which quarter of 2020, got the maximum total_sold_quantity?
SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;


SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then CONCAT('[',1,'] ',MONTHNAME(date))  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then CONCAT('[',2,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then CONCAT('[',3,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then CONCAT('[',4,'] ',MONTHNAME(date))
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters;



#9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
with channels as (
	select 
		channel,
		round((sum(sold_quantity*gross_price)/1000000),2) as gross_sales_mln
	from fact_sales_monthly s
	join fact_gross_price g
	on g.product_code=s.product_code
	join dim_customer c
	on c.customer_code=s.customer_code
	where s.fiscal_year=2021
	group by channel
	order by gross_sales_mln desc
)
select
	*,
    round(gross_sales_mln*100 / (select sum(gross_sales_mln) from channels) ,2) as pct_contribution
from channels;



#10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
with ranked_product as (
		with top_product as (
						select
					    -- creating a table with total_sold_qty and rank_order_colums
							s.product_code,
							product,
							division,
							sum(sold_quantity) as total_sold_quantity
						from fact_sales_monthly s
						join dim_product p
						on p.product_code=s.product_code
						where fiscal_year=2021
						group by s.product_code,division
						order by total_sold_quantity desc 
					)
		select 
			*,
            -- creating a rank column
            rank() over (partition by division
            order by total_sold_quantity desc) as rank_order
		from top_product
	)
select
	*
from ranked_product
where rank_order in (1,2,3);
                
