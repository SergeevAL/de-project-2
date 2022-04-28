# Проект 1
Опишите здесь поэтапно ход решения задачи. Вы можете ориентироваться на тот план выполнения проекта, который мы предлагаем в инструкции на платформе.
1. Собрать требования к витрине


2. Проверка и анализ исходных данных 


3. Подготовка и создание витрины данных

Название витрины:
dm_rfm_segments

Расположение витрины:
Схема analysis

Метрики:
- Recency — сколько времени прошло с момента последнего заказа.
- Frequency — количество заказов.
- Monetary Value — сумма затрат клиента.

Витрина:
- user_id int4
- recency int4
- frequency int4
- monetary_value int4

Глубина витррины:
C начала 2021 года

<b>Изучите структуру исходных данных.</b>

После изучения таблиц схемы production, были выбранны таблицы и поля для расчета метрик витрины. Полей и данных для составления нужных метрик достаточно.

<b>Поля для расчета витрины.</b>
Для расчета витрины в первой части задания будут использоваться таблицы orders, orderstatuses, users.

Таблица orders
- order_ts
- user_id
- cost
- status

Таблица orderstatuses
- id
- key

Таблица users
- id

<b>Проанализируйте качество данных.</b>

Качество данных хорошее, что позволяет работать с ними и выполнить поставленную задачу.
В таблицах схемы отсутствуют пропуски или пустые значения(за исключением поля name в справочнике users, там они возможны, имена имеют различный формат)

Во всех таблицах схемы применены такие ограничения:
orderitems_check,
orderitems_order_id_fkey,
orderitems_order_id_product_id_key,
orderitems_pkey,
orderitems_price_check,
orderitems_product_id_fkey,
orderitems_quantity_check,
orders_check,
orders_pkey,
orderstatuses_pkey,
orderstatuslog_order_id_fkey,
orderstatuslog_order_id_status_id_key,
orderstatuslog_pkey,
orderstatuslog_status_id_fkey,
products_pkey,
products_price_check,
users_pkey

Для полей связанных со стоимостью испольюзуются ограничения (CHECK) на условие больше или равно 0, или другие, название ограничения заканчивается check. Пример:
(((discount >= (0)::numeric) AND (discount <= price)))
((cost = (payment + bonus_payment)))

- Существуют первичные ключи ссылающиеся на другие таблицы схемы, название ограничения заканчивается на pkey
- Существуют внешние ключи ссылающиеся на другие таблицы схемы, название ограничения заканчивается на id_fkey
- Также есть составной ключ orderitems_order_id_product_id_key.

<b>Витрина данных.</b>
Запросы создания витрины в приложении.
