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