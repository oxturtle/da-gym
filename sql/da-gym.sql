
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

/*Show every order 
with the customer’s name and state.*/

Select
      o.order_id
    , o.order_date
    , o.order_total
    , s.customer_name
    , s.state

From
    orders o
        left join customers s
            on o.customer_id=s.customer_id
;


/*For each state, 
show the total number of orders and total revenue.
For this ques. I'd want to preserve customers-
dataset becuase it's about state metrics.
total number of orders and total revenue are
based off of each state.*/

Select
      c.state
    , count(o.order_id) as order_count
    , sum(o.order_total) as total_revenue

From
    customers c
        left join orders o
            on c.customer_id=o.customer_id

Group By    
    c.state
;


/*For each state, 
show total revenue, 
then identify only the states 
whose total revenue 
is above the average state revenue.*/

With state_revenue as (
    Select
        c.state
        , sum(o.order_total) as total_revenue

    From
        customers c
            left join orders o
                on c.customer_id=o.customer_id
    Group By 
        c.state
    )

Select
      state
    , total_revenue
From
    state_revenue

Where
    total_revenue > (
        Select
            avg(total_revenue)
        From
            state_revenue
        )
;

/*For each feature,
show how many unique users used it.
users
----------------
user_id
user_name
state

features
----------------
feature_id
feature_name

feature_events
----------------
event_id
user_id
feature_id
event_date
---I'd preserve features due to business ques.
*/

With unique_count as (
    Select
        f.feature_name 
        , count(distinct fe.user_id) unique_users

    From
        features f
            left join feature_events fe
                on f.feature_id=fe.feature_id

    Group By
        f.feature_name
    )

Select
      feature_name
    , unique_users

From
    unique_count

Where   
    unique_users > (
        Select
            avg(unique_users)
        From
            unique_count
    )
;


With total_revenue as (
    Select
          c.state
        , sum(o.order_total) sum_revenue
        
    From
        customers c
            left join orders o
                on c.customer_id=o.customer_id

    Group By
        c.state
)

Select
      state
    , sum_revenue 

From
    total_revenue

Where
    sum_revenue > (
        Select
            avg(sum_revenue)
        From
            total_revenue
    )
;

/*Calculate total spend per customer, 
then return only customers whose total spend is 
above the average customer spend.*/
With customer_spend as (
    Select
          c.customer_id  as customer 
        , sum(o.order_total) as  customer_total_spend         
    From
        customers c 
            left join orders o 
                on c.customer_id=o.customer_id
    Group By
        c.customer_id
)

Select
      customer
    , customer_total_spend
From    
    customer_spend 

Where
    customer_total_spend > (
        Select
            avg(customer_total_spend)
        From
            customer_spend 
    )
;

/*For each product, 
calculate total revenue, 
then return only products whose total revenue is 
below the average product revenue.*/
With product_total_rev as (
    Select
        p.product_id as product 
        , sum(oi.quantity*oi.unit_price) total_revenue    
    From
        products p
            left join order_items oi
                on p.product_id=oi.product_id
    Group By
        p.product_id
)

Select
      product
    , total_revenue

From
    product_total_rev

Where
    total_revenue < (
        Select
            avg(total_revenue)
        From
            product_total_rev
    )
;


/* One-to-many relationship + join reasoning 
customers
----------------
customer_id
customer_name

orders
----------------
order_id
customer_id
order_date

order_items
----------------
order_item_id
order_id
product_id
quantity
unit_price
----------------
----------------
Show each customer's total revenue across all of their orders.
*/

Select
      c.customer_id as customer 
    , sum(oi.quantity * oi.unit_price) as total_revenue 

From
    customers c 
        left join orders o
            on c.customer_id=o.customer_id
        left join order_items oi
            on o.order_id=oi.order_id 

Group By
    c.customer_id 
;


/*For each state and product, show total revenue*/
Select
      c.state
    , p.product_id as product 
    , sum(oi.quantity*oi.unit_price) as total_revenue

From
    customers c
        left join orders o
            on c.customer_id=o.customer_id
        left join order_items oi
            on o.order_id=oi.order_id
        left join products p 
            on oi.product_id=p.product_id

Group By
      c.state
    , p.product_id
;

/*Show every customer, 
including customers who have never placed an order, 
and show their total spend if they have any

Trace metric to entity:
policies
----------------
policy_id
customer_id
policy_type

claims
----------------
claim_id
policy_id
claim_amount
claim_date

Result = show total claim amount by policy type 


above-average cust spend:
customers
----------------
customer_id
customer_name

orders
----------------
order_id
customer_id
order_total

Show customers whose total spend is 
above the average total spend across all customers
*/

With cust_total_spend as (
        Select
              c.customer_id as customer
            , coalesce(sum(o.order_total), 0) as total_spend
        From
            customers c
                left join orders o
                    on c.customer_id=o.customer_id
        Group By
            c.customer_id
    )

Select
      customer 
    , total_spend
 

From 
    cust_total_spend

Where
    total_spend > (
        Select 
            avg(total_spend)
        From
            cust_total_spend
    )
;

/* Compare each policy to its type average: 
policies
----------------
policy_id
policy_type
premium_amount

Show every policy, 
its premium amount, 
and the average premium for that policy type
*/

Select 
      policy_id as policy 
    , policy_type
    , premium_amount
    , avg(premium_amount) Over(
        Partition By policy_type
    ) as avg_premium

From
    policies 
;

/*Show each customer’s total spend 
and rank customers from highest to lowest spend 
within their state.*/

With cust_total_spend as (
    Select
          c.state
        ,  c.customer_id as customer 
        , sum(o.order_total) cust_total_spend
    From
        customers c
            left join orders o
                on c.customer_id=o.customer_id
    Group By
          c.state
        , c.customer_id
)

Select
      customer
    , cust_total_spend
    , Rank() Over(
        Partition By state
        Order By cust_total_spend desc
    )

From   
    cust_total_spend
;

/*For each state and feature, 
show the number of unique users who used that feature, 
then rank features from most-used to least-used within each state.*/

With unique_used_count as (
    Select
          u.state
        , f.feature_name
        , count(distinct fe.user_id) as used_count
    From
        users u
            left join feature_events fe 
                on u.user_id=fe.user_id
            left join features f 
                on fe.feature_id=f.feature_id
    Group By 
          u.state 
        , f.feature_name
)

Select
      state
    , feature_name feature 
    , used_count
    , Rank() Over(
        Partition By state
        Order By used_count desc
    )
From    
    unique_used_count
;

/*Show policy types 
whose average claim amount is
 above the average claim amount across all policy types.*/
With avg_claim_amount as (
    Select
        p.policy_type
        , avg(c.claim_amount) avg_claim
    From
        policies p
            left join claims c
                on p.policy_id=c.policy_id
    Group By
        p.policy_type
)

Select
      policy_type
    , avg_claim

From
    avg_claim_amount

Where
    avg_claim > (
        Select
             avg(avg_claim)
        From 
            avg_claim_amount
    )
;

/*Show the total number of orders for each state.*/
Select
      c.state
    , count(o.order_id)
From
    customers c
        left join orders o 
            on c.customer_id=o.customer_id
Group By 
    c.state 
; 

/*
Grain = one row per Nevada customer
Entity location = customers
Metric = total spend
Join path = customers left join orders
calculation: sum(order_total)
Filters = yes
I'll need Having order_total > $1,000  
*/
Select
      c.customer_id customer 
    , sum(o.order_total) total_spend
From
    customers c
        left join orders o
            on c.customer_id=o.customer_id

Where
    c.state = 'NV'

Group By
    c.customer_id

Having
    sum(o.order_total) > 1000
;

/*Average salary for each department
employees
----------------
employee_id
department
salary

Grain = one row per department 
entity = employees 
metric = average salary 
calculation = avg(salary)
No join needed due to only worlking with one dataset
No CTE needed
No Window Function needed
Group By Department
*/
Select
      e.department
    , avg(e.salary) avg_salary

From
    employees e
;
