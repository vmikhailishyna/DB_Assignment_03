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
