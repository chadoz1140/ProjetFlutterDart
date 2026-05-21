
drop function if exists get_reservations(status_type);

create or replace function get_reservations(p_status status_type default null)
    returns setof reservation_details as

$$
select row(
           r.id,
           r.datetime,
           r.number_of_guests,
           r.status,
           r.special_requests,
           get_client_info(r.client),
           get_restaurant_info(r.restaurant)
           )::reservation_details
from reservations r
where (auth.role() = 'admin' or r.client =(select id from  users us where us.email = auth.email())) and
    (p_status is null or r.status = p_status)
order by r.datetime desc;

$$ language sql security definer;

grant execute on function get_reservations(status_type) to authenticated;