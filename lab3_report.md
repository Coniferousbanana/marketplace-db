# Отчёт по лабораторной работе №3

## Многотабличные запросы и аналитические представления

## Ход работы

### Задание 1: Соединение таблиц

**Условие:** *Напишите запрос с внутренним соединением не менее трёх таблиц (товар — категория — продавец).*

**Запрос:** *Выводит товары, которые продает определенный продавец из категории электроника с ценой больше 8000*

```sql
SELECT sellers.id as seller_id, categories.name, products.id as product_id, products.title, products.price
from products 
JOIN sellers ON sellers.id = products.seller_id
join categories ON categories.id = products.category_id
WHERE sellers.id = 2 and products.price > 8000 and categories.id = 1;
```

### Задание 2: LEFT JOIN

**Условие:** *Напишите запрос с LEFT JOIN, показывающий строки без соответствий в связанной таблице (например, товары без отзывов).*

**Запрос:** *Товары без отзывов*

```sql
SELECT products.category_id, products.id, products.title, products.price, reviews.comment, reviews.score
FROM products
left JOIN reviews ON reviews.product_id = products.id
WHERE reviews.comment is null and reviews.score is null
limit 20;
```

### Задание 3: Агрегатные функции и группировка

**Условие:** *Постройте запрос с группировкой и агрегацией: по каждой категории — количество товаров и средняя цена.*

**Запрос:** *Выводит среднюю цену товара в каждой категории*

```sql
SELECT category_id AS category_id, COUNT(products.id) as products_count, avg(products.price) as avg_price
from products
GROUP BY products.category_id;
```

### Задание 4: HAVING

**Условие:** *Примените HAVING для фильтрации групп (например, продавцы с выручкой выше заданной).*

**Запрос:** *Продавцы с выручкой больше 100 000*

```sql
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
```

---

### Задание 5: Подзапросы

#### 5.1 Скалярный подзапрос

**Задача:** *Для каждого товара вывести его название, цену, среднюю цену по рынку и отклонение цены конкретного товара от средней. Скалярный подзапрос используется для вычисления глобального значения (средней цены), которое затем сопоставляется с каждой строкой.*

**Запрос:** *Вывести товары, среднюю цену по всем товарам и разницу в цене между каждым товаром и средним*

```sql
SELECT 
    p.title,
    p.price,
    (SELECT ROUND(AVG(price), 2) FROM products) AS avg_market_price,
    ROUND(p.price - (SELECT AVG(price) FROM products), 2) AS diff_from_avg
FROM products p
LIMIT 10;
```

#### 5.2 Подзапрос с IN

**Задача:** *Найти все товары, которые когда-либо заказывали пользователи из Москвы.*

**Запрос:**

```sql
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
```

#### 5.3 Коррелированный подзапрос (EXISTS)

**Задача:** *Вывести продавцов, у которых хоть раз заказывали товары, стоимостью больше 9000.*

**Запрос:**

```sql
SELECT s.store_name, s.id
from sellers s
where EXISTS (
    SELECT 1
    from products p JOIN order_items oi on oi.product_id = p.id
    where p.price > 9000 and p.seller_id = s.id
);
```

---

### Задание 6: CTE (Common Table Expression)

#### 6.1 CTE для разбиения сложного запроса

**Задача:** *Посчитать выручку каждого продавца, но вывести только тех, чья выручка выше средней по всем продавцам. Без CTE пришлось бы дублировать логику подсчета выручки.*

**Запрос:**

```sql
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
```

#### 6.2 Рекурсивный CTE для обхода дерева категорий

**Задача:** *Построить иерархическое дерево категорий с отображением полного пути (от корня до листа) и уровня вложенности. Рекурсивный CTE позволяет обойти структуру «родитель → потомок» произвольной глубины, что невозможно сделать обычным JOIN без знания максимального числа уровней.*

**Запрос:**

```sql
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
```

---

### Задание 7: Представления (VIEW)

#### 7.1 Представление 1: Дашборд продавца

**Назначение:** *Агрегирует ключевые бизнес-метрики по каждому продавцу: количество товаров, число заказов, общую выручку и средний чек. Представление избавляет аналитиков от необходимости каждый раз писать сложный JOIN по четырём таблицам (sellers → products → order_items → orders) и применяется для построения отчётов, дашбордов и быстрого мониторинга эффективности продавцов.*

**Код создания:**

```sql
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
```

**Пример обращения:**

```sql
SELECT store_name, total_products
FROM v_seller_dashboard
WHERE total_products > 100;
```

#### 7.2 Представление 2: Топ товаров по продажам

**Назначение:** *Формирует рейтинг самых популярных товаров с детализацией по продавцу и категории. Учитывает количество проданных единиц, выручку и число заказов. Используется для аналитики ассортимента, выявления бестселлеров и формирования рекомендаций. В представление включены только товары, которые реально были проданы (статусы 'paid', 'shipped', 'delivered'), что исключает искажение статистики отменёнными заказами.*

**Код создания:**

```sql
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
```

**Пример обращения:**

```sql
SELECT product_id, title, units_sold, revenue_generated
FROM v_top_products
ORDER BY units_sold DESC
LIMIT 10;
```

---