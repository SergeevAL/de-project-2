
-----------------------------
-- Проверка исходных данных
-----------------------------

select * from production.orderitems o ;
select * from production.orders o2;
select * from production.orderstatuses o3 ;
select * from production.orderstatuslog o4 ;
select * from production.products p ;
select * from production.users u ;

--

select count(*) from production.users u ;

--

select * from production.users u 
where u.id = 276;

--

select * from information_schema."columns" c 
where c.table_schema = 'production'
order by 3,5;

select * from information_schema.constraint_column_usage ccu 
where ccu.table_schema = 'production'
order by 3;

select distinct ccu.constraint_name from information_schema.constraint_column_usage ccu 
where ccu.table_schema = 'production';


-------------------
--Задание 1
-------------------

-------------------
create view analysis.v_orderitems as select * from production.orderitems;
create view analysis.v_orders as select * from production.orders;
create view analysis.v_orderstatuses as select * from production.orderstatuses;
create view analysis.v_orderstatuslog as select * from production.orderstatuslog;
create view analysis.v_products as select * from production.products;
create view analysis.v_users as select * from production.users;

-------------------

select * from analysis.v_orderitems;
select * from analysis.v_orders;
select * from analysis.v_orderstatuses;
select * from analysis.v_orderstatuslog;
select * from analysis.v_products;
select * from analysis.v_users;

-------------------

-- drop table analysis.dm_rfm_segments;

CREATE TABLE analysis.dm_rfm_segments (
	user_id int4 NOT NULL,
	recency int4,
	frequency int4,
	monetary_value int4,
	CONSTRAINT dm_rfm_segments_recency_user_id_pkey PRIMARY KEY (user_id),
	CONSTRAINT dm_rfm_segments_recency_check CHECK ((recency > 0) AND (recency < 6)),
	CONSTRAINT dm_rfm_segments_frequency_check CHECK ((frequency > 0) AND (frequency < 6)),
	CONSTRAINT dm_rfm_segments_monetary_value_check CHECK ((monetary_value > 0) AND (monetary_value < 6))
);

-----------------

select * from analysis.dm_rfm_segments;

-----------------

select * from analysis.v_orders
order by 3,2;

select vu.* ,vo.* from analysis.v_orders vo 
join analysis.v_users vu on
vo.user_id = vu.id;

-----------------
--monetary_value
-----------------

select vo.user_id, sum(cost) as monetary_value  from analysis.v_orders vo 
where vo.status = 4
group by vo.user_id
order by 1;

select vo.user_id ,NTILE(5) OVER(ORDER BY sum(cost)) as monetary_value  from analysis.v_orders vo 
where vo.status = 4
group by vo.user_id
order by 1;

-- Проверка разбиения
select v.monetary_value, count(*) from
(select vo.user_id, sum(cost) ,NTILE(5) OVER(ORDER BY sum(cost)) as monetary_value  from analysis.v_orders vo 
where vo.status = 4
group by vo.user_id
order by 1) v
group by v.monetary_value;

-----------------
--frequency
-----------------
select vo.user_id, count(*) as frequency  from analysis.v_orders vo 
group by vo.user_id
order by 1;

select vo.user_id, NTILE(5) OVER(ORDER BY count(*)) as frequency  from analysis.v_orders vo 
group by vo.user_id
order by 1;

-- Проверка разбиения

select v.frequency, count(*) from
(select vo.user_id, NTILE(5) OVER(ORDER BY count(*)) as frequency  from analysis.v_orders vo 
group by vo.user_id
order by 1) v
group by v.frequency;

-----------------
--recency
-----------------

select distinct s.user_id, 
	LAST_VALUE(s.diff) OVER (partition by s.user_id ORDER BY s.order_ts 
	RANGE BETWEEN 
   	UNBOUNDED PRECEDING AND 
    UNBOUNDED FOLLOWING) as recency
from (
	select vo.user_id, vo.order_ts ,vo.order_ts - lag(vo.order_ts) over (partition by vo.user_id order by vo.order_ts) diff
	from analysis.v_orders vo
	order by vo.user_id, vo.order_ts) s
order by 1;

select ss.user_id, NTILE(5) OVER(ORDER BY ss.recency desc) as recency 
from (
	select distinct s.user_id, 
		LAST_VALUE(s.diff) OVER (partition by s.user_id ORDER BY s.order_ts 
		RANGE BETWEEN 
	   	UNBOUNDED PRECEDING AND 
	    UNBOUNDED FOLLOWING) as recency
	from (
		select vo.user_id, vo.order_ts ,vo.order_ts - lag(vo.order_ts) over (partition by vo.user_id order by vo.order_ts) diff
		from analysis.v_orders vo
		order by vo.user_id, vo.order_ts) s
order by 1) ss;

--Проверка разбиения

select sss.recency, count(*) from (
	select ss.user_id, NTILE(5) OVER(ORDER BY ss.recency desc) as recency from (
		select distinct s.user_id, 
			LAST_VALUE(s.diff) OVER (partition by s.user_id ORDER BY s.order_ts 
			RANGE BETWEEN 
		   	UNBOUNDED PRECEDING AND 
		    UNBOUNDED FOLLOWING) as recency
		from (
			select vo.user_id, vo.order_ts ,vo.order_ts - lag(vo.order_ts) over (partition by vo.user_id order by vo.order_ts) diff
			from analysis.v_orders vo
			order by vo.user_id, vo.order_ts) s
	order by 1) ss ) sss
group by sss.recency;

------------------------
-- Запрос для загрузки
------------------------

with recency_query as (
	select ss.user_id, NTILE(5) OVER(ORDER BY ss.recency desc) as recency 
	from (
		select distinct s.user_id, 
			LAST_VALUE(s.diff) OVER (partition by s.user_id ORDER BY s.order_ts 
			RANGE BETWEEN 
		   	UNBOUNDED PRECEDING AND 
		    UNBOUNDED FOLLOWING) as recency
		from (
			select vo.user_id, vo.order_ts ,vo.order_ts - lag(vo.order_ts) over (partition by vo.user_id order by vo.order_ts) diff
			from analysis.v_orders vo
			order by vo.user_id, vo.order_ts) s
	order by 1) ss
),
frequency_query as (
	select vo.user_id, NTILE(5) OVER(ORDER BY count(*)) as frequency  from analysis.v_orders vo 
	group by vo.user_id
	order by 1
),
monetary_query as (
	select vo.user_id ,NTILE(5) OVER(ORDER BY sum(cost)) as monetary_value  from analysis.v_orders vo 
	where vo.status = 4
	group by vo.user_id
	order by 1
)
select vu.id user_id, rq.recency, fq.frequency, mq.monetary_value  from analysis.v_users vu 
left join recency_query rq 
on vu.id = rq.user_id
left join frequency_query fq 
on vu.id = fq.user_id
left join monetary_query mq
on vu.id = mq.user_id
order by 1;

--------

--  insert 

insert into analysis.dm_rfm_segments 
with recency_query as (
	select ss.user_id, NTILE(5) OVER(ORDER BY ss.recency desc) as recency 
	from (
		select distinct s.user_id, 
			LAST_VALUE(s.diff) OVER (partition by s.user_id ORDER BY s.order_ts 
			RANGE BETWEEN 
		   	UNBOUNDED PRECEDING AND 
		    UNBOUNDED FOLLOWING) as recency
		from (
			select vo.user_id, vo.order_ts ,vo.order_ts - lag(vo.order_ts) over (partition by vo.user_id order by vo.order_ts) diff
			from analysis.v_orders vo
			order by vo.user_id, vo.order_ts) s
	order by 1) ss
),
frequency_query as (
	select vo.user_id, NTILE(5) OVER(ORDER BY count(*)) as frequency  from analysis.v_orders vo 
	group by vo.user_id
	order by 1
),
monetary_query as (
	select vo.user_id ,NTILE(5) OVER(ORDER BY sum(cost)) as monetary_value  from analysis.v_orders vo 
	where vo.status = 4
	group by vo.user_id
	order by 1
)
select vu.id user_id, rq.recency, fq.frequency, mq.monetary_value  from analysis.v_users vu 
left join recency_query rq 
on vu.id = rq.user_id
left join frequency_query fq 
on vu.id = fq.user_id
left join monetary_query mq
on vu.id = mq.user_id
order by 1;

-------------
select * from analysis.dm_rfm_segments;


-------------
--Задание 2
-------------

-- Примечание. Я создал в первой части задания схему analysis с предаставлениями с префиксом v_* в названии
-- и чтобы задание корректно сработало, сделаем как в python и sql скрипте в докер образе 

DROP VIEW IF EXISTS analysis.v_orders;
ALTER TABLE production.orders DROP COLUMN status;
CREATE VIEW analysis.v_orders AS SELECT * FROM production.orders;

----

create or replace view analysis.v_orders as select o2.*, o4.status from production.orders o2 
join (
	select distinct order_id,
		LAST_VALUE(status_id) OVER (partition by order_id ORDER BY dttm 
		RANGE BETWEEN 
		UNBOUNDED PRECEDING AND 
		UNBOUNDED following) status
	from analysis.v_orderstatuslog order by 1) o4
on o2.order_id = o4.order_id;

----

select * from analysis.v_orders o2;

	


