
/* The following code are meant to be exercises
that allow me to practice SQL logic. There are no
real datasets. Therefore, no results will be produced. 

orders (Table Name)
---------
order_id
order_date
customer_id
state
product_name
quantity
unit_price

Business Request:
For each state, 
identify the top 3 products by total revenue 
and show what percentage of that state's total revenue each product represents.

I want to see, state, product_name, sum(unit_price)*/


/*Prodcuts & unit price scattered on dataset by order_id.
CTE for getting product_revenue; unit_price * quantity */
With product_sales as (
	Select
		  o.state
		, o.product_name
		,sum(o.unit_price * o.quantity) as product_revenue
		
	From
		orders o 

	Group By
		  o.state
		, o.product_name
), 

/*Window Function: sum() Over() and Row_Number() Over() 
organizes product_revenue and revenue ranking by state
Row number lets me filter for top 3 products by total revenue*/ 
ranked_sales as (
	Select 
		  *
		, sum(product_revenue) Over (
			partition by state 
		) as state_revenue
		, Row_Number() Over (
			partition by state
			Order By product_revenue desc
		) as revenue_rank
	From
		product_sales	
)


/* Using both CTEs with Window*/
Select  
	  product_name
	, product_revenue
	, state
	, state_revenue
	, revenue_rank
	, Round(
		(product_revenue/state_revenue) * 100  
	, 2
	) as revenue_pct
From 
	ranked_sales
Where
	revenue_rank <= 3
;



/*Window Functions Bootcamp - Lvl 1

sales
--------------------------------
sale_id
salesperson
region
sale_amount

| sale_id | salesperson | region | sale_amount |
| ------: | ----------- | ------ | ----------: |
|       1 | Ana         | West   |         500 |
|       2 | Ben         | West   |         300 |
|       3 | Ana         | West   |         700 |
|       4 | Chris       | East   |         400 |
|       5 | Dana        | East   |         600 |
|       6 | Chris       | East   |         200 |

Show every individual sale, 
along with the total sales for that sale's region.

Desired Fields:
salesperson
region
sale_amount
region_total
*/

--Partition By
Select
      salesperson
    , region
    , sale_amount
    , sum(sale_amount) Over (
      partition by region
    ) as region_total

From
    sales
;

/*Order By 
Show every sale 
and a running total of sales within each region, 
from smallest sale to largest sale.*/

Select
      salesperson
    , region
    , sale_amount
    , SUM(sale_amount) OVER (
        PARTITION BY region
        ORDER BY sale_amount
      ) AS running_region_total

From sales
;


/* Row_Number()
Rank every salesperson within each region 
from highest sale to lowest sale.*/

Select
      salesperson
    , region
    , sale_amount
    , Row_Number() Over(
        Partition By region
        Order By sale_amount desc
    ) as sale_rank

From
    sales
;

/*Rank each salesperson within their region
 by sale_amount, highest to lowest. 
 Tied values should receive the same rank, 
 and the next rank should not skip.
*/
 Select
      salesperson
    , region
    , sale_amount
    , Dense_Rank() Over(
        Partition By 
            region
        Order By 
            sale_amount desc
    ) as sale_rank

From
    sales


/*lag()
For each region, 
show every sale and the previous sale amount 
based on sale_date*/
Select
      salesperson
    , region
    , sale_date
    , sale_amount
    , Lag(sale_amount) Over(
        Partition By region
        Order By sale_date
    ) as previous_sale_amount 

From
    sales
;

/*For each region, 
show every sale, 
the previous sale amount, 
and how much the sale changed compared with the previous one.*/
With previous_sales as (
    Select
        salesperson
        , region
        , sale_date
        , sale_amount
        , Lag(sale_amount) Over(
            Partition By region
            Order By sale_date
        ) as previous_sale_amount

    From
        sales
)

Select
      salesperson
    , region
    , sale_date
    , sale_amount   
    , previous_sale_amount
    , sale_amount - previous_sale_amount as sale_change

From
    previous_sales
;  

/*For each region, 
show every sale, 
the previous sale amount, 
and the percent change from the previous sale.*/
With previous_sales as (
    Select
        salesperson
        , region
        , sale_date
        , sale_amount
        , Lag(sale_amount) Over(
            Partition By region
            Order By sale_date
        ) as previous_sale_amount

    From
        sales
)

Select 
      salesperson
    , region 
    , sale_date
    , sale_amount
    , previous_sale_amount
    , Round(
        (sale_amount - previous_sale_amount)
        /previous_sale_amount*100.0, 2
    ) as sale_change_pct

From
    previous_sales
;

/*Lead() | For each region, 
show every sale and the next sale amount based on sale_date.
This Window Function allows me to 
create a field that shows the next row's value(sale_amount)
and compare to current sale_amount. Thereby having a
value comparison between two different dates*/
Select
      salesperson
    , region
    , sale_date
    , sale_amount
    , Lead(sale_amount) Over(
        Partition By region
        Order By sale_date
        ) as next_sale_amount

From
    sales
;

/*Using Lead() w CTE with calculation for percent change*/
With next_sales as (
    Select
        salesperson
        , region
        , sale_date
        , sale_amount
        , Lead(sale_amount) Over(
            Partition By region
            Order By sale_date
            ) as next_sale_amount

    From
        sales
)
Select
      salesperson
    , region
    , sale_date
    , sale_amount
    , next_sale_amount
    , Round(
        (sale_amount - next_sale_amount)/
      next_sale_amount *100.0,2
    ) as sale_change_pct

From
    next_sales
;

/*First_Value() and Last_Value
For each region, 
show every sale and 
the first sale amount in that region based on sale_date.*/
Select
      salesperson
    , region
    , sale_date
    , sale_amount
    , First_Value(sale_amount) Over(
        Partition By region
        Order By sale_date
    ) as first_sale_amount

From
    sales
;

--Drill for Last_Value()
Select
      salesperson
    , region
    , sale_date
    , sale_amount
    , Last_Value(sale_amount) Over(
        Partition By region
        Order By sale_date
        Rows Between Unbounded Preceding
        and Unbounded Following
    ) as last_sale_amount

From
    sales
;


/*For each region, 
show every sale and the average sale_amount from 
the current row and the two previous rows, 
based on sale_date.*/
Select
      salesperson
    , region
    , sale_date
    , sale_amount
    , Avg(sale_amount) Over(
        Partition By region
        Order By sale_date
        Rows Between 2 Preceding
        and Current Row
    ) as moving_avg_3_sales

From
    sales
;