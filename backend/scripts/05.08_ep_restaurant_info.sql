create or replace function get_restaurant_info(restaurant_id int)
    returns restaurant_info as
$$
    select row (id, name, address, city, phone, description, rating, price_range, slot_duration)::restaurant_info
    from restaurants as r
    where r.id = restaurant_id

$$language sql security definer;