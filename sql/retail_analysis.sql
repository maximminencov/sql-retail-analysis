-- SQL-анализ заказов, клиентов, товаров, доставок и пользовательских сессий
-- Автор: Максим Миненков


-- =========================================================
-- Задача 1.
-- Найти товар с максимальным количеством заказов
-- =========================================================

SELECT
    p.product_id,
    p.product_name,
    COUNT(DISTINCT op.order_id) AS orders_count
FROM orders_product AS op
JOIN products AS p
    ON op.product_id = p.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY
    orders_count DESC
LIMIT 1;


-- =========================================================
-- Задача 2.
-- Найти дату с максимальным количеством завершённых доставок
-- =========================================================

SELECT
    delivery_dt,
    COUNT(*) AS completed_deliveries
FROM info
WHERE is_completed_flg = 'True'
GROUP BY delivery_dt
ORDER BY completed_deliveries DESC
LIMIT 1;


-- =========================================================
-- Задача 3.
-- Найти дату с минимальным количеством завершённых доставок
-- =========================================================

SELECT
    delivery_dt,
    COUNT(*) AS completed_deliveries
FROM info
WHERE is_completed_flg = 'True'
GROUP BY delivery_dt
ORDER BY completed_deliveries ASC
LIMIT 1;


-- =========================================================
-- Задача 4.
-- Рассчитать среднюю длительность пользовательской сессии
-- по каждому типу устройства
-- =========================================================

SELECT
    device_name,
    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                STR_TO_DATE(start_dttm, '%d.%m.%y %H:%i'),
                STR_TO_DATE(finish_dttm, '%d.%m.%y %H:%i')
            )
        ),
        2
    ) AS avg_session_minutes
FROM app_sess
GROUP BY device_name
ORDER BY avg_session_minutes DESC;


-- =========================================================
-- Задача 5.
-- Найти заказ с максимальным количеством уникальных товаров
-- =========================================================

SELECT
    order_id,
    COUNT(DISTINCT product_id) AS unique_products_count
FROM orders_product
GROUP BY order_id
ORDER BY unique_products_count DESC
LIMIT 1;


-- =========================================================
-- Задача 6.
-- Рассчитать количество незавершённых доставок по месяцам
-- начиная с 2022 года
-- =========================================================

SELECT
    DATE_FORMAT(
        STR_TO_DATE(delivery_dt, '%d-%m-%Y'),
        '%Y-%m'
    ) AS delivery_month,
    COUNT(*) AS incomplete_deliveries
FROM info
WHERE
    is_completed_flg = 'False'
    AND STR_TO_DATE(delivery_dt, '%d-%m-%Y') >= '2022-01-01'
GROUP BY delivery_month
ORDER BY delivery_month;


-- =========================================================
-- Задача 7.
-- Проанализировать количество заказов по годам
-- и способам оплаты
-- =========================================================

SELECT
    YEAR(
        STR_TO_DATE(order_dt, '%d.%m.%Y')
    ) AS order_year,
    payment_method,
    COUNT(*) AS orders_count
FROM orders
GROUP BY
    order_year,
    payment_method
ORDER BY
    order_year,
    payment_method;


-- =========================================================
-- Задача 8.
-- Найти TOP-10 клиентов по количеству заказов
-- =========================================================

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS orders_count
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY orders_count DESC
LIMIT 10;


-- =========================================================
-- Задача 9.
-- Для каждой возрастной группы определить
-- наиболее популярную товарную категорию
-- =========================================================

WITH category_stats AS (
    SELECT
        CASE
            WHEN TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) >= 18
            AND TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) < 30
                THEN '18-30'

            WHEN TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) >= 30
            AND TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) < 45
                THEN '30-45'

            WHEN TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) >= 45
            AND TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) < 60
                THEN '45-60'

            WHEN TIMESTAMPDIFF(
                YEAR,
                STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
                CURDATE()
            ) >= 60
                THEN '60+'
        END AS age_group,

        p.product_group_name,
        COUNT(*) AS products_count

    FROM customers AS c
    JOIN orders AS o
        ON c.customer_id = o.customer_id
    JOIN orders_product AS op
        ON o.order_id = op.order_id
    JOIN products AS p
        ON op.product_id = p.product_id

    WHERE TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(c.birth_dt, '%d.%m.%Y'),
        CURDATE()
    ) >= 18

    GROUP BY
        age_group,
        p.product_group_name
),

ranked_categories AS (
    SELECT
        age_group,
        product_group_name,
        products_count,
        ROW_NUMBER() OVER (
            PARTITION BY age_group
            ORDER BY products_count DESC
        ) AS rn
    FROM category_stats
)

SELECT
    age_group,
    product_group_name,
    products_count
FROM ranked_categories
WHERE rn = 1
ORDER BY
    CASE age_group
        WHEN '18-30' THEN 1
        WHEN '30-45' THEN 2
        WHEN '45-60' THEN 3
        WHEN '60+' THEN 4
    END;


-- =========================================================
-- Задача 10.
-- Найти товар, который чаще всего покупают вместе с водой
-- =========================================================

SELECT
    p2.product_id,
    p2.product_name,
    COUNT(DISTINCT op2.order_id) AS joint_orders_count
FROM orders_product AS op1
JOIN products AS p1
    ON op1.product_id = p1.product_id
JOIN orders_product AS op2
    ON op1.order_id = op2.order_id
    AND op1.product_id <> op2.product_id
JOIN products AS p2
    ON op2.product_id = p2.product_id
WHERE p1.product_name = 'Вода'
GROUP BY
    p2.product_id,
    p2.product_name
ORDER BY joint_orders_count DESC
LIMIT 1;
