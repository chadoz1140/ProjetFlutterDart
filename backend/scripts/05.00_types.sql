drop type if exists reservation_details cascade;

create type reservation_details as
(
    id integer,
    datetime timestamp,
    number_of_guests int,
    status status_type,
    special_requests text,
    client client_info,
    restaurant restaurant_info
);

create or replace function get_reservation_details(reservation_id int)
    returns reservation_details as
$$
select row(r.id, r.datetime, r.number_of_guests, r.status, r.special_requests,
           get_client_info(r.client), get_restaurant_info(r.restaurant))::reservation_details
from reservations r
where r.id = reservation_id;
$$ language sql security definer;


grant execute on function get_reservation_details(int) to anon

drop type if exists client_info cascade;

create type client_info as
(
    id int,
    email text,
    password text,
    full_name text,
    role role_type,
    phone text
);

create or replace function get_client_info(client_id int)
    returns client_info as
$$
select row (id, email, password, full_name, role, phone)::client_info
from users as u
where u.id = client_id

$$language sql security definer;

drop type if exists restaurant_details cascade;

create type restaurant_details as
(
    id int,
    name text,
    address text,
    city text,
    phone text,
    description text,
    rating double precision,
    price_range int,
    slot_duration int,
    tables table_info[],
    services service_info[]
);

create or replace function get_restaurant_details(restaurant_id int)
    returns restaurant_details as
$$
select row (r.id, r.name, r.address, r.city, r.phone,
           r.description, r.rating, r.price_range, r.slot_duration,
           get_table_info_by_restaurant_id(restaurant_id),
           get_service_info_by_restaurant_id(restaurant_id))::restaurant_details
from restaurants as r
where r.id = restaurant_id

$$language sql security definer;

drop type if exists restaurant_info cascade;

create type restaurant_info as
(
    id int,
    name text,
    address text,
    city text,
    phone text,
    description text,
    rating double precision,
    price_range int,
    slot_duration int
);

create or replace function get_restaurant_info(restaurant_id int)
    returns restaurant_info as
$$
select row (id, name, address, city, phone, description, rating, price_range, slot_duration)::restaurant_info
from restaurants as r
where r.id = restaurant_id

$$language sql security definer;

drop type if exists table_info cascade;
create type table_info as
(
    id int,
    restaurant int,
    table_number int,
    capacity int
);

create or replace function get_table_info_by_restaurant_id(restaurant_id int)
    returns table_info[] as
$$
select array(
               select row(t.id, t.restaurant, t.table_number, t.capacity)::table_info
               from tables as t
               where t.restaurant = restaurant_id
               order by t.table_number);

$$language sql security definer;


drop type if exists service_info cascade;

create type service_info as
(
    id int,
    restaurant int,
    day_of_week int,
    start_time time,
    end_time time
);

create or replace function get_service_info_by_restaurant_id(restaurant_id int)
    returns service_info[] as
$$
select array(
               select row(s.id, s.restaurant, s.day_of_week, s.start_time, s.end_time)::service_info
               from services as s
               where s.restaurant = restaurant_id
               order by s.day_of_week);

$$language sql security definer;