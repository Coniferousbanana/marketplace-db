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
WHERE o.status IN ('paid', 'shipped', 'delivered')  
GROUP BY s.id
HAVING SUM(oi.quantity * oi.unit_price) > 100000  
ORDER BY total_revenue DESC;

-- Запросы для задания 5


SELECT 
    p.title,
    p.price,
    (SELECT ROUND(AVG(price), 2) FROM products) AS avg_market_price,
    ROUND(p.price - (SELECT AVG(price) FROM products), 2) AS diff_from_avg
FROM products p
LIMIT 10;

SELECT s.store_name, s.id
from sellers s
where EXISTS (
    SELECT 1
    from products p JOIN order_items oi on oi.product_id = p.id
    where p.price > 9000 and p.seller_id = s.id
);

SELECT p.id, p.title, p.price, s.store_name
FROM products p
JOIN sellers s ON s.id = p.seller_id
WHERE p.id IN (
    SELECT oi.product_id
    FROM order_items oi
    JOIN orders o ON o.id = oi.order_id
    JOIN addresses a ON a.user_id = o.user_id
    WHERE a.city = 'Москва'
);

-- Запросы для задания 6

WITH SellerRevenue AS (
    SELECT 
        s.id AS seller_id,
        s.store_name,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue
    FROM sellers s
    LEFT JOIN products p ON p.seller_id = s.id
    LEFT JOIN order_items oi ON oi.product_id = p.id
    LEFT JOIN orders o ON o.id = oi.order_id AND o.status IN ('paid', 'shipped', 'delivered')
    GROUP BY s.id, s.store_name
),
AvgRevenue AS (
    SELECT AVG(total_revenue) AS avg_rev
    FROM SellerRevenue
)
SELECT 
    sr.seller_id,
    sr.store_name,
    sr.total_revenue,
    ar.avg_rev,
    ROUND(sr.total_revenue - ar.avg_rev, 2) AS above_avg_by
FROM SellerRevenue sr, AvgRevenue ar
WHERE sr.total_revenue > ar.avg_rev
ORDER BY sr.total_revenue DESC;

WITH RECURSIVE CategoryTree AS (
    SELECT 
        id,
        name,
        parent_id,
        name AS full_path,    
        1 AS level           
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT 
        c.id,
        c.name,
        c.parent_id,
        ct.full_path || ' / ' || c.name AS full_path, 
        ct.level + 1 AS level                           
    FROM categories c
    INNER JOIN CategoryTree ct ON c.parent_id = ct.id  
)
SELECT id, name, full_path, level
FROM CategoryTree
ORDER BY level, full_path;

-- Задание 7
-- Представление - основные данные о продавцах
CREATE OR REPLACE VIEW v_seller_dashboard AS
SELECT 
    s.id AS seller_id,
    s.store_name,
    COUNT(DISTINCT p.id) AS total_products,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_revenue,
    CASE 
        WHEN COUNT(DISTINCT o.id) > 0 
        THEN ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.id), 2)
        ELSE 0 
    END AS avg_order_value
FROM sellers s
LEFT JOIN products p ON p.seller_id = s.id
LEFT JOIN order_items oi ON oi.product_id = p.id
LEFT JOIN orders o ON o.id = oi.order_id AND o.status IN ('paid', 'shipped', 'delivered')
GROUP BY s.id, s.store_name;

-- обращение к представлению
SELECT store_name, total_products
FROM v_seller_dashboard
WHERE total_products > 100;

-- Представление - популярные товары

CREATE OR REPLACE VIEW v_top_products AS
SELECT 
    p.id AS product_id,
    p.title,
    p.price,
    s.store_name AS seller_name,
    c.name AS category_name,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue_generated,
    COUNT(DISTINCT oi.order_id) AS times_ordered
FROM products p
JOIN sellers s ON s.id = p.seller_id
JOIN categories c ON c.id = p.category_id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id AND o.status IN ('paid', 'shipped', 'delivered')
GROUP BY p.id, p.title, p.price, s.store_name, c.name
HAVING SUM(oi.quantity) > 0;

-- обращение к представлению
SELECT product_id, title, units_sold, revenue_generated
FROM v_top_products
ORDER BY units_sold DESC
LIMIT 10;