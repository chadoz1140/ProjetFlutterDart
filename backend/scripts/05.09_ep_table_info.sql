create or replace function get_table_info_by_restaurant_id(restaurant_id int)
    returns table_info[] as
$$
    select array(
                   select row(t.id, t.restaurant, t.table_number, t.capacity)::table_info
                   from tables as t
                   where t.restaurant = restaurant_id
                   order by t.table_number);

$$language sql security definer;
