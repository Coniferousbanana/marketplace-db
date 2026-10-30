-- Запрос для задания 1
SELECT sellers.id as seller_id, categories.name, products.id as product_id, products.title, products.price
from products 
JOIN sellers ON sellers.id = products.seller_id
join categories ON categories.id = products.category_id
WHERE sellers.id = 2 and products.price > 8000 and categories.id = 1;

-- Запрос для задания 2
SELECT products.category_id, products.id,products.title, products.price, reviews.comment, reviews.score
FROM products
left JOIN reviews ON reviews.product_id = products.id
WHERE reviews.comment is null and reviews.score is null
limit 20;

-- Запрос для задания 3
SELECT category_id AS category_id, COUNT(products.id) as products_count, avg(products.price) as avg_price
from products
GROUP BY products.category_id;

-- Запрос для задания 4
SELECT 
    s.id AS seller_id,
    s.store_name,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM sellers s
JOIN products p ON p.seller_id = s.id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE o.status IN ('paid', 'shipped', 'delivered')  -- только оплаченные заказы
GROUP BY s.id
HAVING SUM(oi.quantity * oi.unit_price) > 100000    -- порог выручки
ORDER BY total_revenue DESC;

-- Запросы для задания 5


SELECT 
    p.title,
    p.price,
    -- Скалярный подзапрос: возвращает ОДНО значение (среднюю цену)
    (SELECT ROUND(AVG(price), 2) FROM products) AS avg_market_price,
    ROUND(p.price - (SELECT AVG(price) FROM products), 2) AS diff_from_avg
FROM products p
LIMIT 10;

SELECT 
    p.title,
    p.price,
    ROUND(p.price - (
        SELECT AVG(price) 
        FROM products p2 
        WHERE p2.category_id = p.category_id
    ), 2) AS diff_from_category_avg
FROM products p
LIMIT 10;