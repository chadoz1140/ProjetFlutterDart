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