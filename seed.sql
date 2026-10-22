 
-- 1. ПОЛЬЗОВАТЕЛИ
 
INSERT INTO users (full_name, email, phone, role) VALUES
('Иван Петров', 'ivan.petrov@mail.ru', '+79001112233', 'buyer'),
('ООО Универсам Маркет', 'universam_market@gmail.com', '+79007778899', 'seller'),
('Алексей Иванов', 'alex.ivanov@yandex.ru', '+79001234567', 'buyer'),
('Елена Смирнова', 'elena.smirnova@mail.ru', '+79009876543', 'buyer'),
('Дмитрий Кузнецов', 'dmitry.kuznetsov@gmail.com', '+79005554433', 'buyer'),
('Ольга Попова', 'olga.popova@yandex.ru', '+79007778899', 'buyer'),
('Сергей Васильев', 'sergey.vasiliev@mail.ru', '+79003332211', 'buyer');

-- 2. ПРОДАВЦЫ 

INSERT INTO sellers (user_id, store_name, description) VALUES
(2, 'Универсам Маркет', 'Универсальный маркетплейс. Электроника, одежда, книги - всё в одном месте.');

-- 3. Категории и товары
INSERT INTO categories (name) VALUES ('Электроника'), ('Книги'), ('Одежда'); 
INSERT INTO products (seller_id, category_id, title, price) 
SELECT 1, 
(random() * 2 + 1)::int, 
'Товар №' || g, 
(random() * 9000 + 1000)::numeric(12,2) 
FROM generate_series(1, 1000) AS g; 
 
-- 6. СКЛАДСКИЕ ОСТАТКИ
 
INSERT INTO stock (product_id, quantity, updated_at)
SELECT 
    p.id,
    (random() * 500 + 10)::int,
    now() - (random() * interval '30 days')
FROM products p;

 
-- 7. АДРЕСА
INSERT INTO addresses (user_id, city, street, house, apartment) VALUES
(1, 'Москва', 'ул. Ленина', '10', '5'),
(1, 'Санкт-Петербург', 'Невский проспект', '25', NULL),
(2, 'Москва', 'ул. Тверская', '1', NULL),
(3, 'Новосибирск', 'Красный проспект', '50', '12'),
(4, 'Казань', 'ул. Баумана', '15', '42'),
(5, 'Екатеринбург', 'ул. Малышева', '101', '7'),
(6, 'Самара', 'ул. Куйбышева', '80', '3'),
(7, 'Ростов-на-Дону', 'ул. Пушкинская', '100', '15');


-- 8. КОРЗИНЫ

INSERT INTO carts (user_id) VALUES (1), (4), (5);

 
-- 8.1. ПОЗИЦИИ КОРЗИН
 
INSERT INTO cart_items (cart_id, product_id, quantity)
WITH cart_sizes AS (
    -- Для каждой корзины генерируем случайное количество позиций (1-5)
    SELECT 
        c.id AS cart_id,
        (floor(random() * 5) + 1)::int AS items_count
    FROM carts c
),
final_items AS (
    -- Для каждой корзины выбираем СРАЗУ несколько уникальных товаров
    SELECT 
        cs.cart_id,
        p.id AS product_id,
        (floor(random() * 3) + 1)::int AS quantity
    FROM cart_sizes cs
    CROSS JOIN LATERAL (
        SELECT id FROM products 
        ORDER BY random() 
        LIMIT cs.items_count  -- Берём сразу N уникальных товаров
    ) p
)
SELECT cart_id, product_id, quantity
FROM final_items;


-- 9. ЗАКАЗЫ (1000+ позиций)
 
INSERT INTO orders (user_id, status, total_amount, created_at)
SELECT 
    1 + ((g - 1) % 7),
    CASE 
        WHEN random() > 0.7 THEN 'paid'
        WHEN random() > 0.5 THEN 'shipped'
        WHEN random() > 0.3 THEN 'delivered'
        ELSE 'new'
    END,
    0,
    now() - (random() * interval '90 days')
FROM generate_series(1, 1200) AS g;

 
-- 10. ПОЗИЦИИ ЗАКАЗОВ
 
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
WITH order_sizes AS (
    -- Для каждого заказа генерируем случайное количество позиций (1-4)
    SELECT 
        o.id AS order_id,
        (floor(random() * 4) + 1)::int AS items_count
    FROM orders o
),
final_items AS (
    -- Для каждого заказа выбираем СРАЗУ несколько уникальных товаров
    SELECT 
        os.order_id,
        p.id AS product_id,
        (floor(random() * 4) + 1)::int AS quantity,
        p.price AS unit_price
    FROM order_sizes os
    CROSS JOIN LATERAL (
        SELECT id, price 
        FROM products 
        ORDER BY random() 
        LIMIT os.items_count  -- Берём сразу N уникальных товаров
    ) p
)
SELECT order_id, product_id, quantity, unit_price
FROM final_items;

-- 10.1 Установка итоговой суммы в заказ

UPDATE orders o
SET total_amount = (
    SELECT SUM(oi.quantity * oi.unit_price)
    FROM order_items oi
    WHERE oi.order_id = o.id
)
WHERE o.id IN (SELECT order_id FROM order_items);

 
-- 11. ПЛАТЕЖИ
 
INSERT INTO payments (order_id, amount, status, paid_at)
SELECT 
    o.id,
    o.total_amount,
    CASE 
        WHEN o.status IN ('paid', 'shipped', 'delivered') THEN 'success'
        ELSE 'pending'
    END,
    CASE 
        WHEN o.status IN ('paid', 'shipped', 'delivered') THEN o.created_at + interval '1 hour'
        ELSE NULL
    END
FROM orders o
WHERE o.status != 'new';

 
-- 12. ДОСТАВКИ (Исправленная версия: строго 1 адрес на заказ)
INSERT INTO deliveries (order_id, address_id, delivery_status, delivery_date)
SELECT 
    o.id,
    (SELECT id FROM addresses WHERE user_id = o.user_id ORDER BY id LIMIT 1), -- Берем только ПЕРВЫЙ адрес пользователя
    CASE 
        WHEN o.status = 'delivered' THEN 'delivered'
        WHEN o.status = 'shipped' THEN 'in_transit'
        WHEN o.status = 'paid' THEN 'processing'
        ELSE 'pending'
    END,
    CASE 
        WHEN o.status IN ('shipped', 'delivered') THEN o.created_at + interval '3 days'
        WHEN o.status = 'paid' THEN o.created_at + interval '1 day'
        ELSE NULL
    END
FROM orders o
WHERE o.status != 'new';

-- 13. ОТЗЫВЫ
 
INSERT INTO reviews (user_id, product_id, score, comment, created_at)
SELECT DISTINCT ON (o.user_id, oi.product_id)
    o.user_id,
    oi.product_id,
    (random() * 4 + 1)::int,
    CASE 
        WHEN random() > 0.9 THEN 'Отличный товар, рекомендую!'
        WHEN random() > 0.7 THEN 'Хорошее качество за свои деньги'
        WHEN random() > 0.5 THEN 'Нормальный товар, но есть нюансы'
    END,
    o.created_at + interval '7 days'
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status = 'delivered'
ORDER BY o.user_id, oi.product_id, random();