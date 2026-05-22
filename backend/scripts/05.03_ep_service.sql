/** Récupère les informations de base d'un service **/
drop function if exists get_service_info_by_restaurant_id(restaurant_id int);

create or replace function get_service_info_by_restaurant_id(restaurant_id int)
    returns service_info[] as
$$
    select array(
                   select row(s.id, s.restaurant, s.day_of_week, s.start_time, s.end_time)::service_info
                   from services as s
                   where s.restaurant = restaurant_id
                   order by s.day_of_week);

$$language sql security definer;

grant execute on function get_service_info_by_restaurant_id(int) to authenticated;