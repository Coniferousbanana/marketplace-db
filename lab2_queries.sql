-- Задание 2 из лабораторной
SELECT DISTINCT 
    seller_id as seller,
    category_id as category
FROM products;


--Задание 3 из лабораторной
SELECT  categories.NAME as category_name, products.title as product_name, products.price
from products
inner JOIN categories ON products.category_id = categories.id
where (categories.name = 'Одежда' or categories.name = 'Книги') and (products.price < 1500)
LIMIT 10;


-- Запросы для задания 4
SELECT orders.id as order_id, orders.user_id, orders.status as order_status, deliveries.delivery_status, orders.total_amount, orders.created_at
from orders
inner JOIN deliveries ON deliveries.order_id = orders.id
WHERE (total_amount BETWEEN 1200 and 10000) AND deliveries.delivery_status in ('processing', 'in_transit');

SELECT products.category_id, products.id,products.title, products.price, reviews.comment, reviews.score
FROM products
INNER JOIN reviews ON reviews.product_id = products.id
WHERE reviews.comment is null;

SELECT products.category_id, products.id,products.title, products.price, reviews.comment
FROM products
LEFT JOIN reviews ON reviews.product_id = products.id
WHERE reviews.score is null;

select products.title, products.id, reviews.comment
from products
inner JOIN reviews on reviews.product_id = products.id
where reviews.comment ilike '%отлич%';

-- Запрос для задания 5
SELECT DISTINCT on (user_id)
    id,
    user_id,
    status,
    total_amount,
    created_at
FROM orders
ORDER BY orders.user_id asc, orders.total_amount DESC;

-- Запрос для задания 6
SELECT products.category_id, products.id,products.title, products.price
FROM products
WHERE products.category_id = 1
ORDER BY products.price desc
LIMIT 10
offset 30;
