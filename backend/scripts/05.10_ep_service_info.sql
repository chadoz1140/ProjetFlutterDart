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