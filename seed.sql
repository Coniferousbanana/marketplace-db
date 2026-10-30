-- 1. ПОЛЬЗОВАТЕЛИ
-- Добавим больше пользователей, чтобы было кому быть продавцами
INSERT INTO users (full_name, email, phone, role) VALUES
('Иван Петров', 'ivan.petrov@mail.ru', '+79001112233', 'buyer'),
('ООО Универсам Маркет', 'universam_market@gmail.com', '+79007778899', 'seller'), -- user_id = 2
('АО Ашан Гипермаркет', 'Ashan_giant@yandex.ru', '+79001110000', 'seller'),       -- user_id = 3
('Алексей Иванов', 'alex.ivanov@yandex.ru', '+79001234567', 'buyer'),
('Елена Смирнова', 'elena.smirnova@mail.ru', '+79009876543', 'buyer'),
('Дмитрий Кузнецов', 'dmitry.kuznetsov@gmail.com', '+79005554433', 'buyer'),
('Ольга Попова', 'olga.popova@yandex.ru', '+79007778899', 'buyer'),
('Сергей Васильев', 'sergey.vasiliev@mail.ru', '+79003332211', 'buyer');

-- 2. ПРОДАВЦЫ
-- Важно: seller.id будет зависеть от порядка вставки. 
-- Если users вставились с id 1..8, то первые два sellers получат id 1 и 2? 
-- НЕТ! Sellers - отдельная таблица со своим счетчиком.
-- Первый INSERT в sellers даст id=1, второй id=2.

INSERT INTO sellers (user_id, store_name, description) VALUES
(2, 'Универсам Маркет', 'Универсальный маркетплейс. Электроника, одежда, книги.'),
(3, 'АшанГипермаркет', 'Огромное разнообразие товаров каждой категории');

-- Запомним ID продавцов для удобства (в реальном скрипте можно использовать CTE или переменные, 
-- но здесь мы полагаемся на то, что это первые две записи)
-- Seller 1 -> Universam (user 2)
-- Seller 2 -> (user 3)

-- 3. КАТЕГОРИИ И ПОДКАТЕГОРИИ
-- Сначала создаем корневые категории
INSERT INTO categories (name) VALUES 
('Электроника'), -- id = 1
('Книги'),       -- id = 2
('Одежда');      -- id = 3

-- Теперь добавляем подкатегории для каждой родительской
-- Указываем parent_id явно, чтобы гарантировать связь
INSERT INTO categories (parent_id, name) VALUES
-- Подкатегории Электроники (parent_id = 1)
(1, 'Смартфоны'),
(1, 'Ноутбуки'),
-- Подкатегории Книг (parent_id = 2)
(2, 'Художественная литература'),
(2, 'Техническая литература'),
-- Подкатегории Одежды (parent_id = 3)
(3, 'Мужская одежда'),
(3, 'Женская одежда');

-- Проверяем, что у нас получилось 9 категорий (3 родителя + 6 детей)
-- В реальном скрипте можно не проверять, но для отладки полезно знать ID:
-- Родители: 1, 2, 3
-- Дети: 4, 5, 6, 7, 8, 9

-- 4. ТОВАРЫ (только в дочерних категориях)
-- Распределяем товары между 6 подкатегориями циклично
-- seller_id распределяем так же: первые 500 - продавец 1, остальные - продавец 2
INSERT INTO products (seller_id, category_id, title, description, price) 
SELECT 
    CASE WHEN g <= 500 THEN 1 ELSE 2 END AS seller_id,
    -- Формула ((g-1) % 6) + 4 дает числа от 4 до 9 (ID подкатегорий)
    ((g - 1) % 6) + 4 AS category_id,
    'Товар №' || g AS title,
    'Описание для товара номер ' || g AS description,
    (random() * 9000 + 100)::numeric(12,2) AS price
FROM generate_series(1, 1000) AS g;

-- 5. СКЛАДСКИЕ ОСТАТКИ
INSERT INTO stock (product_id, quantity, updated_at)
SELECT 
    p.id,
    (random() * 500 + 10)::int,
    now() - (random() * interval '30 days')
FROM products p;

-- 6. АДРЕСА
-- Обновим адреса, добавив адрес для нового продавца (user_id=3), если нужно, 
-- но в таблице deliveries адреса берутся от buyer (user_id заказа).
-- Оставим как есть, но убедимся, что у покупателей есть адреса.
INSERT INTO addresses (user_id, city, street, house, apartment) VALUES
(1, 'Москва', 'ул. Ленина', '10', '5'),
(1, 'Санкт-Петербург', 'Невский проспект', '25', NULL),
(4, 'Новосибирск', 'Красный проспект', '50', '12'), -- Алексей
(5, 'Казань', 'ул. Баумана', '15', '42'),           -- Елена
(6, 'Екатеринбург', 'ул. Малышева', '101', '7'),    -- Дмитрий
(7, 'Самара', 'ул. Куйбышева', '80', '3'),          -- Ольга
(8, 'Ростов-на-Дону', 'ул. Пушкинская', '100', '15'); -- Сергей

-- 7. КОРЗИНЫ
-- Создадим корзины для разных покупателей
INSERT INTO carts (user_id) VALUES (1), (4), (5), (6);

-- 7.1. ПОЗИЦИИ КОРЗИН
INSERT INTO cart_items (cart_id, product_id, quantity)
WITH cart_sizes AS (
    SELECT 
        c.id AS cart_id,
        (floor(random() * 5) + 1)::int AS items_count
    FROM carts c
),
final_items AS (
    SELECT 
        cs.cart_id,
        p.id AS product_id,
        (floor(random() * 3) + 1)::int AS quantity
    FROM cart_sizes cs
    CROSS JOIN LATERAL (
        SELECT id FROM products 
        ORDER BY random() 
        LIMIT cs.items_count
    ) p
)
SELECT cart_id, product_id, quantity
FROM final_items;

-- 8. ЗАКАЗЫ
-- Генерируем заказы от разных пользователей (id 1, 4, 5, 6, 7, 8 - покупатели)
-- Исключаем пользователей-продавцов (2, 3) из списка покупателей для реализма, 
-- хотя технически они могут покупать.
INSERT INTO orders (user_id, status, total_amount, created_at)
SELECT 
    -- Выбираем случайного покупателя из списка: 1, 4, 5, 6, 7, 8
    (ARRAY[1, 4, 5, 6, 7, 8])[1 + floor(random() * 6)]::int AS user_id,
    CASE 
        WHEN random() > 0.7 THEN 'paid'
        WHEN random() > 0.5 THEN 'shipped'
        WHEN random() > 0.3 THEN 'delivered'
        ELSE 'new'
    END AS status,
    0 AS total_amount,
    now() - (random() * interval '90 days') AS created_at
FROM generate_series(1, 1200) AS g;

-- 9. ПОЗИЦИИ ЗАКАЗОВ
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
WITH order_sizes AS (
    SELECT 
        o.id AS order_id,
        (floor(random() * 4) + 1)::int AS items_count
    FROM orders o
),
final_items AS (
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
        LIMIT os.items_count
    ) p
)
SELECT order_id, product_id, quantity, unit_price
FROM final_items;

-- 9.1. Обновление суммы заказа
UPDATE orders o
SET total_amount = sub.total
FROM (
    SELECT order_id, SUM(quantity * unit_price) as total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.id = sub.order_id;

-- 10. ПЛАТЕЖИ
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

-- 11. ДОСТАВКИ
-- Внимание: адрес берется от пользователя заказа. 
-- Если у пользователя нет адреса, этот запрос может вернуть NULL или ошибку, если NOT NULL.
-- В нашей схеме addresses.user_id NOT NULL, но в deliveries address_id NOT NULL.
-- Убедимся, что у всех пользователей, делающих заказы, есть адреса.
-- В шаге 6 мы добавили адреса для 1, 4, 5, 6, 7, 8. Все ок.

INSERT INTO deliveries (order_id, address_id, delivery_status, delivery_date)
SELECT 
    o.id,
    a.id AS address_id,
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
JOIN addresses a ON a.user_id = o.user_id
-- Берем первый адрес пользователя, если их несколько
WHERE a.id = (SELECT MIN(id) FROM addresses WHERE user_id = o.user_id)
AND o.status != 'new';

-- 12. ОТЗЫВЫ
-- Отзывы могут оставлять только те, кто купил товар и статус заказа delivered
INSERT INTO reviews (user_id, product_id, score, comment, created_at)
SELECT DISTINCT ON (o.user_id, oi.product_id)
    o.user_id,
    oi.product_id,
    (floor(random() * 5) + 1)::int AS score, -- 1 to 5
    CASE 
        WHEN random() > 0.9 THEN 'Отличный товар, рекомендую!'
        WHEN random() > 0.7 THEN 'Хорошее качество за свои деньги'
        WHEN random() > 0.5 THEN 'Нормальный товар, но есть нюансы'
        ELSE 'Все понравилось'
    END,
    o.created_at + interval '7 days'
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.status = 'delivered'
ORDER BY o.user_id, oi.product_id, random();