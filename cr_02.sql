-- Продажи по категориям
WITH sales AS (
  SELECT
    p.category,
    oi.order_id,
    oi.amount
  FROM order_items oi
  JOIN products p ON oi.product_id = p.id
)
SELECT
  category,
  -- Общая сумма продаж по категории
  SUM(amount) AS total_sales,
  -- Средняя сумма продаж на заказ в категории
  SUM(amount) / COUNT(DISTINCT order_id) AS avg_per_order,
  -- Доля категории в общих продажах (%)
  SUM(amount) * 100.0 / SUM(SUM(amount)) OVER () AS category_share
FROM sales
GROUP BY category
ORDER BY total_sales DESC;


-- Анализ покупателей
WITH order_totals AS (
  SELECT
    o.id          AS order_id,
    o.customer_id,
    o.order_date,
    SUM(oi.amount) AS order_total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  GROUP BY o.id, o.customer_id, o.order_date
)
SELECT
  customer_id,
  order_id,
  order_date,
  order_total,
  -- Общая сумма покупок клиента
  SUM(order_total) OVER (PARTITION BY customer_id)        AS total_spent,
  -- Средний чек клиента
  AVG(order_total) OVER (PARTITION BY customer_id)        AS avg_order_amount,
  -- Разница суммы данного заказа от среднего чека
  order_total - AVG(order_total) OVER (PARTITION BY customer_id) AS difference_from_avg
FROM order_totals
ORDER BY customer_id, order_date;


-- Сравнение продаж по месяцам
WITH monthly_sales AS (
  SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS year_month,
    DATE_TRUNC('month', order_date)::DATE AS month_start,
    SUM(oi.amount) AS total_sales
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.id
  GROUP BY TO_CHAR(order_date, 'YYYY-MM'), DATE_TRUNC('month', order_date)
)
SELECT
  year_month,
  total_sales,
  -- % изменения от предыдущего месяца
  (total_sales
     - LAG(total_sales) OVER (ORDER BY month_start)
  ) * 100.0
    / NULLIF(LAG(total_sales) OVER (ORDER BY month_start), 0)
    AS prev_month_diff,
  -- % изменения от того же месяца год назад
  (total_sales
     - LAG(total_sales) OVER (
         PARTITION BY EXTRACT(MONTH FROM month_start)
         ORDER BY EXTRACT(YEAR FROM month_start)
       )
  ) * 100.0
    / NULLIF(
       LAG(total_sales) OVER (
         PARTITION BY EXTRACT(MONTH FROM month_start)
         ORDER BY EXTRACT(YEAR FROM month_start)
       ),
       0
     )
    AS prev_year_diff
FROM monthly_sales
ORDER BY month_start;
