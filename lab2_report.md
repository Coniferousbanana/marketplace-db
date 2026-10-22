# Отчет по лабораторной работе №2: Базовые SQL-запросы и фильтрация данных
**Техническое задание**
Наполните спроектированную базу тестовыми данными и составьте 
набор запросов на выборку и фильтрацию. В крупные таблицы (товары, 
заказы) внесите не менее тысячи строк. 
1. Наполните все таблицы согласованными данными, используя 
generate_series или иной генератор для массового заполнения.  
2. Напишите запрос, выводящий заданные столбцы товаров без 
дубликатов (DISTINCT), с псевдонимами столбцов.
3. Напишите запрос с фильтрацией по нескольким условиям, 
объединённым AND и OR со скобками.
4. Примените в запросах предикаты BETWEEN, IN, LIKE (или ILIKE) и IS 
NULL — каждый хотя бы один раз. 
5. Напишите запрос с сортировкой по двум столбцам в разных 
направлениях. 
6. Реализуйте постраничный вывод товаров с помощью LIMIT и OFFSET. 
7. Для каждого запроса приведите его текст, назначение и фрагмент 
результата. 
## Выполнение
1) Таблицы были заполнены данными. Полный скрипт лежит в seed.sql
2) Был реализован запрос, который возвращает все категории, которыми он торгует с псевдонимами столбцов
```sql
SELECT DISTINCT 
    seller_id as seller,
    category_id as category
FROM products;
```
3) Запрос, который выводит книги и одежду, которая стоит меньше 1500
```sql
SELECT  categories.NAME as category_name, products.title as product_name, products.price
from products
left JOIN categories ON products.category_id = categories.id
where (categories.name = 'Одежда' or categories.name = 'Книги') and (products.price < 1500);
```

4) Написаны несколько запросов:
    1. Выводит заказы, стоимостью от 1200 до 10000, которые сейчас либо доставяются, либо обрабатываются
    ```sql
    SELECT orders.id as order_id, orders.user_id, orders.status as order_status, deliveries.delivery_status, orders.total_amount, orders.created_at
    from orders
    inner JOIN deliveries ON deliveries.order_id = orders.id
    WHERE (total_amount BETWEEN 1200 and 10000) AND deliveries.delivery_status in ('processing', 'in_transit');
    ```
    2. Выводит товары без комментариев к отзыву и их оценку
    ```sql
    SELECT products.category_id, products.id,products.title, products.price, reviews.comment
    FROM products
    LEFT JOIN reviews ON reviews.product_id = products.id
    WHERE reviews.score is null;
    ```
    3. Выводит товары, в комментариях к которым есть слова "Отлично"
    ```sql
        select products.title, products.id, reviews.comment
    from products
    inner JOIN reviews on reviews.product_id = products.id
    where reviews.comment ilike '%отлич%';
    ```
5) Написан запрос, который возвращает самыq дорогой заказ для каждого пользователя
```sql
SELECT DISTINCT on (user_id)
    id,
    user_id,
    status,
    total_amount,
    created_at
FROM orders
ORDER BY orders.user_id asc, orders.total_amount DESC;
```
6) Запрос, который возвращает четвертую страницу товаров, отсортированных по цене по убыванию, по 10 товаров на каждой
```sql
SELECT products.category_id, products.id,products.title, products.price
FROM products
WHERE products.category_id = 1
ORDER BY products.price desc
LIMIT 10
offset 30;
```