use assignment_02;

CREATE INDEX idx_orders_user_id ON Orders(user_id);
CREATE INDEX idx_orders_product_id ON Orders(product_id);
CREATE INDEX idx_orders_order_date ON Orders(order_date);
CREATE INDEX idx_products_category ON Products(category);


explain with cte_aggregation as(
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