create schema dwhfinal

create table dwhfinal.dim_calendar as 
with dates as (
	select dd as date_time
	from generate_series('2016-08-01'::timestamptz, '2016-12-30'::timestamptz, '1 minute'::interval) dd
			  )
(
select
	to_char(date_time, 'YYYYMMDDHH24MI')::bigint as id,
	date_time,
	date_time::date as date,
	date_part('isodow', date_time)::int as week_day,
	date_part('week', date_time)::int as week_number,
	date_part('month', date_time)::int as month,
	date_part('isoyear', date_time)::int as year,
	(date_part('isodow', date_time)::smallint between 1 and 5)::int as work_day
from dates
order by date_time
);
alter table dwhfinal.dim_calendar add primary key(id);

create table dwhfinal.dim_airports (
id serial primary key,
airport_code bpchar(3) not null,
airport_name varchar(50) not null,
city varchar(100) not null,
longitude float8,
latitude float8,
timezone varchar(50)
);
create table dwhfinal.dim_airports_bad (
id serial primary key,
airport_code varchar(50),
airport_name varchar(50),
city varchar(100),
longitude float8,
latitude float8,
timezone varchar(50)
);
create table dwhfinal.dim_tariff (
id serial primary key,
flight_id integer,
fare_conditions varchar(10)
);
create table dwhfinal.dim_tariff_bad (
id serial primary key,
flight_id integer,
fare_conditions varchar(10)
);
create table dwhfinal.dim_passengers (
id serial primary key,
passenger_id varchar(20) not null,
passenger_name varchar(100),
phone varchar(12),
email varchar(50)
)
CREATE INDEX idx_passenger_id
ON dwhfinal.dim_passengers(passenger_id)
;
create table dwhfinal.dim_passengers_bad (
id serial primary key,
passenger_id varchar(50),
passenger_name varchar(100),
contact_data varchar(500)
);
create table dwhfinal.dim_passengers_bad_unpacked_data (
id serial primary key,
passenger_id varchar(50),
passenger_name varchar(500),
phone varchar(500),
email varchar(500)
);
create table dwhfinal.dim_aircrafts (
id serial primary key,
aircraft_code bpchar(3) not null,
model varchar(50) not null,
"range" int4
);
create table dwhfinal.dim_aircrafts_bad (
id serial primary key,
aircraft_code varchar(100),
model varchar(100),
"range" varchar(100)
);

create table dwhfinal.pre_fact_flights as
select 
	f.flight_id,
	t.passenger_id,
	f.actual_departure,
	f.actual_arrival,
	abs(extract(epoch from f.actual_departure) - extract(epoch from f.scheduled_departure)) as delay_departure,
	abs(extract(epoch from f.actual_arrival) - extract(epoch from f.scheduled_arrival)) as delay_arrival,
	f.aircraft_code,
	f.departure_airport,
	f.arrival_airport,
	f.flight_no,
	tf.fare_conditions,
	tf.amount
from bookings.flights f 
inner join bookings.boarding_passes bp 
	on f.flight_id = bp.flight_id 

	inner join bookings.ticket_flights tf 
	on f.flight_id = tf.flight_id
	and tf.ticket_no = bp.ticket_no
	
	inner join bookings.tickets t 
	on tf.ticket_no = t.ticket_no 

where f.status = 'Arrived'
order by f.flight_id; 


create table dwhfinal.fact_flights (
id serial primary key,
passenger_id int4 references dwhfinal.dim_passengers(id),
actual_departure_id bigint references dwhfinal.dim_calendar(id),
actual_arrival_id bigint references dwhfinal.dim_calendar(id),
delay_departure numeric,
delay_arrival numeric,
aircraft_id int4 references dwhfinal.dim_aircrafts(id),
departure_airport_id int4 references dwhfinal.dim_airports(id),
arrival_airport_id int4 references dwhfinal.dim_airports(id),
tariff_id int4 references dwhfinal.dim_tariff(id),
amount numeric(10,2)
);

create table dwhfinal.fact_flights_bad (
id serial primary key,
passenger_id int4,
actual_departure_id bigint,
actual_arrival_id bigint,
delay_departure numeric,
delay_arrival numeric,
aircraft_id int4,
departure_airport_id int4,
arrival_airport_id int4,
tariff_id int4,
amount numeric(10,2)
);
