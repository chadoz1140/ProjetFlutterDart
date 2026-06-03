
/** Récupère les informations complètes d'une reservation **/

drop function if exists get_reservation_details(reservation_id int);

create or replace function get_reservation_details(reservation_id int)
    returns reservation_details as
$$
    select row(r.id, r.datetime, r.number_of_guests, r.status, r.special_requests,
               get_client_info(r.client), get_restaurant_info(r.restaurant))::reservation_details
    from reservations r
    where r.id = reservation_id
       and (
                -- client voit ses réservations
                r.client = (select id from users where email = auth.email())
           );
$$ language sql security definer;

grant execute on function get_reservation_details(int) to authenticated;


/** Récupère la liste des réservations du client connecté, filtrées par statut **/

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
        where (
                -- client voit ses réservations
                r.client = (select id from users us where us.email = auth.email())
            )
        and (p_status is null or r.status = p_status)
        order by r.datetime desc;
$$ language sql security definer;

grant execute on function get_reservations(status_type) to authenticated;


/** Récupère les réservations d'un restaurant pour le manager **/

drop function if exists get_reservations_by_restaurant(int, status_type);
create or replace function get_reservations_by_restaurant(restaurant_id int, p_status status_type)
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
            where r.restaurant = restaurant_id
            and (p_status is null or r.status = p_status)
            and exists(
                select 1 from restaurant_managers rm
                join users u on u.id = rm.manager
                where u.email = auth.email()
           )

    $$language sql security definer;

grant execute on function get_reservations_by_restaurant(int, status_type) to authenticated;


drop function if exists get_first_available_reservation_slot(int, int);

-- create or replace function get_first_available_reservation_slot(restaurant_id int,  number_of_guests int default 2)
-- returns initial_reservation_data as
-- $$
--     declare v_reference_time timestamp;
--     declare v_start_date date;
--     declare v_service record;
--     begin
--         perform auth.check_logged();
--         if (auth.role() != 'client') then
--             raise exception 'Access denied';
--         end if;
--
--         select simulated_time
--         into v_reference_time
--         from get_system_time();
--
--         if v_reference_time is null then
--             v_reference_time := now_local();
--         end if;
--
--         v_start_date := v_reference_time::date;
--
--         for v_service in
--             select start_time, end_time, slot_duration
--             from restaurants rt join services s on rt.id = s.restaurant
--             where s.restaurant = restaurant_id and s.day_of_week = extract(isodow from v_start_date)::int
--             order by start_time
--         loop
--
--         end loop;
--
--
--     end;
-- $$language plpgsql security definer;