# DB_Assignment_03

1️⃣ Non-optimized (AI-generated)
```
SELECT
    u.user_id,
    u.name AS user_name,
    u.email,
    p.product_id,
    p.product_name,
    p.category,
    o.order_id,
    o.order_date,
    o.quantity,
    (o.quantity * p.price) AS total_price,
    ua.avg_user_quantity,
    cc.category_orders_count,
    um.max_user_order,
    ulo.large_orders_count,
    (SELECT AVG(o3.quantity)
     FROM Orders o3
     WHERE o3.user_id = u.user_id) AS d_avg_user_quantity2,
     
    (SELECT COUNT(*)
     FROM Orders o4
     JOIN Products p4 ON o4.product_id = p4.product_id
     WHERE p4.category = p.category) AS d_category_orders_count2
FROM Orders o
JOIN Users u ON o.user_id = u.user_id
JOIN Products p ON o.product_id = p.product_id

LEFT JOIN (
    SELECT user_id, AVG(quantity) AS avg_user_quantity
    FROM Orders
    GROUP BY user_id
) ua ON ua.user_id = u.user_id

LEFT JOIN (
    SELECT p2.category, COUNT(*) AS category_orders_count
    FROM Orders o2
    JOIN Products p2 ON o2.product_id = p2.product_id
    GROUP BY p2.category
) cc ON cc.category = p.category

LEFT JOIN (
    SELECT user_id, MAX(quantity) AS max_user_order
    FROM Orders
    GROUP BY user_id
) um ON um.user_id = u.user_id

LEFT JOIN (
    SELECT user_id, COUNT(*) AS large_orders_count
    FROM Orders
    WHERE quantity > 5
    GROUP BY user_id
) ulo ON ulo.user_id = u.user_id

WHERE o.quantity > 2
  and p.category IN ('Category_1','Category_2','Category_3','Category_4','Category_5')
  AND YEAR(o.order_date) BETWEEN 2020 AND 2025

ORDER BY u.name, p.category, o.order_date DESC;
```

2️⃣ Optimized (your version)

First, indexes were created for the following lines: Orders(user_id), Orders(product_id), Orders(order_date), Products(category).They were created to facilitate searching by lines without scanning the entire table.

cte_aggregation was created and all internal joins were rewritten there so that there would not be many identical subqueries. All complex calculations (averages, maximums, number of large orders) are combined into a single common CTE. Previously, these calculations were performed using several separate subqueries or LEFT JOINs for each metric. This reduced duplicate queries, and the Orders table is now scanned once instead of four times.

A cte_filter_orders was also created, where all orders were filtered, and then the following actions are taken from these orders.Filters all unnecessary entries from Orders to the main query—that is, less data enters the main SELECT. JOINs and aggregations are performed only on relevant data, and this will take less time because the volume of unnecessary rows to scan has been reduced.
```
CREATE INDEX idx_orders_user_id ON Orders(user_id);
CREATE INDEX idx_orders_product_id ON Orders(product_id);
CREATE INDEX idx_orders_order_date ON Orders(order_date);
CREATE INDEX idx_products_category ON Products(category);

with cte_aggregation as(
select o.user_id,
avg(o.quantity) as avg_user_quantity,
MAX(o.quantity) as max_user_order,
p.category,
count(*) as category_orders_count,
sum(case when o.quantity > 5 then 1 else 0 end) as large_orders_count
from Orders o 
join Products p on o.product_id = p.product_id
group by o.user_id, p.category
),
cte_filter_orders as(
select o.*
from Orders o
join Products p on o.product_id = p.product_id
where o.quantity > 2
and year(o.order_date) between 2020 and 2025
and p.category in ('Category_1','Category_2','Category_3','Category_4','Category_5')
)
SELECT
    u.user_id,
    u.name AS user_name,
    u.email,
    p.product_id,
    p.product_name,
    p.category,
    o.order_id,
    o.order_date,
    o.quantity,
    (o.quantity * p.price) AS total_price,
    cte_au.avg_user_quantity,
    cte_au.category_orders_count,
    cte_au.max_user_order,
    cte_au.large_orders_count
FROM cte_filter_orders o
JOIN Users u ON o.user_id = u.user_id
JOIN Products p ON o.product_id = p.product_id
LEFT join cte_aggregation cte_au on cte_au.user_id = u.user_id AND cte_au.category = p.category
ORDER BY u.name, p.category, o.order_date DESC;
```

Explain on optimazed query
<img width="1675" height="208" alt="image" src="https://github.com/user-attachments/assets/e257a9a7-08cb-480f-9a52-5fdb98cf0b4b" />

Explain on non-optimazed query
<img width="1457" height="456" alt="image" src="https://github.com/user-attachments/assets/284740a8-d1cd-4d77-9c57-c2909be4cc69" />

Explain analyze on non-optimazed query 
<img width="1463" height="797" alt="image" src="https://github.com/user-attachments/assets/3f74a560-d139-4126-b4ed-7abd68a844a1" />


Explain analyze on optimazed query

-> Sort: u.`name`, p.category, o.order_date DESC  (actual time=460318..460336 rows=77932 loops=1)
    -> Stream results  (cost=796861 rows=0) (actual time=329765..460019 rows=77932 loops=1)
        -> Nested loop left join  (cost=796861 rows=0) (actual time=329765..459492 rows=77932 loops=1)
            -> Nested loop inner join  (cost=634439 rows=64968) (actual time=3.88..117031 rows=77932 loops=1)
                -> Nested loop inner join  (cost=562979 rows=64968) (actual time=3.14..102898 rows=77932 loops=1)
                    -> Nested loop inner join  (cost=491520 rows=64968) (actual time=3.11..102157 rows=77932 loops=1)
                        -> Filter: ((o.quantity > 2) and (year(o.order_date) between 2020 and 2025) and (o.product_id is not null) and (o.user_id is not null))  (cost=116201 rows=341228) (actual time=1.44..4020 rows=778381 loops=1)
                            -> Table scan on o  (cost=116201 rows=1.02e+6) (actual time=1.43..3134 rows=1e+6 loops=1)
                        -> Filter: (p.category in ('Category_1','Category_2','Category_3','Category_4','Category_5'))  (cost=1 rows=0.19) (actual time=0.126..0.126 rows=0.1 loops=778381)
                            -> Single-row index lookup on p using PRIMARY (product_id = o.product_id)  (cost=1 rows=1) (actual time=0.124..0.124 rows=1 loops=778381)
                    -> Single-row index lookup on p using PRIMARY (product_id = o.product_id)  (cost=1 rows=1) (actual time=0.00912..0.00915 rows=1 loops=77932)
                -> Single-row index lookup on u using PRIMARY (user_id = o.user_id)  (cost=1 rows=1) (actual time=0.181..0.181 rows=1 loops=77932)
            -> Index lookup on cte_au using <auto_key0> (user_id = o.user_id, category = p.category)  (cost=0.25..2.5 rows=10) (actual time=4.39..4.39 rows=1 loops=77932)
                -> Materialize CTE cte_aggregation  (cost=0..0 rows=0) (actual time=329761..329761 rows=990087 loops=1)
                    -> Table scan on <temporary>  (actual time=318328..323648 rows=990087 loops=1)
                        -> Aggregate using temporary table  (actual time=318328..318328 rows=990086 loops=1)
                            -> Nested loop inner join  (cost=1.24e+6 rows=1.02e+6) (actual time=0.222..135545 rows=1e+6 loops=1)
                                -> Filter: (o.product_id is not null)  (cost=116201 rows=1.02e+6) (actual time=0.19..5135 rows=1e+6 loops=1)
                                    -> Table scan on o  (cost=116201 rows=1.02e+6) (actual time=0.188..4674 rows=1e+6 loops=1)
                                -> Single-row index lookup on p using PRIMARY (product_id = o.product_id)  (cost=1 rows=1) (actual time=0.13..0.13 rows=1 loops=1e+6)

