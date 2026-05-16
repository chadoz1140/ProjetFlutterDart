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


grant execute on function get_reservation_details(int) to anon;

