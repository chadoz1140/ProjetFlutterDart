
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


/***************************************************************************
 Retourne le temps de reference de l'application :
 le temps simule s'il existe, sinon l'heure reelle.
****************************************************************************/

drop function if exists get_reference_time();
create or replace function get_reference_time() returns timestamp as
$$
declare
    v_reference_time timestamp;
begin
    select simulated_time
    into v_reference_time
    from get_system_time();

    if v_reference_time is null then
        v_reference_time := now_local();
    end if;
    return v_reference_time;
end;
$$ language plpgsql security definer;


/***************************************************************************
 Indique si le restaurant est ferme pour une date donnee
****************************************************************************/

drop function if exists is_restaurant_closed(integer, date);
create or replace function is_restaurant_closed(p_restaurant_id integer, p_date date)
    returns bool as
$$
begin

    return not exists(
        select 1
        from services s
        where s.restaurant = p_restaurant_id and s.day_of_week = extract(isodow from p_date)::int
    );
end;
$$language plpgsql security definer;

/***************************************************************************
 si le client a deja une reservation active dans un service donne.
****************************************************************************/

drop function if exists is_client_has_reservation_in_service(integer, integer, date, time, time);
create or replace function is_client_has_reservation_in_service(p_restaurant_id integer, p_id_client integer, p_date date, p_start_time time, p_end_time time)
    returns bool as
$$
begin
    return exists(
        select 1
        from reservations rs
        where rs.client = p_id_client and rs.restaurant = p_restaurant_id and rs.datetime::date = p_date
          and rs.status in ('pending', 'confirmed', 'completed') and rs.datetime::time >= p_start_time and rs.datetime::time < p_end_time
    );
end;
$$language plpgsql security definer;

/***************************************************************************
 si le client a deja une reservation active dans chacun des
    services du restaurant pour la date donnee.
****************************************************************************/

drop function if exists is_client_has_reservation_for_all_services(integer,integer, date);
create or replace function is_client_has_reservation_for_all_services(p_restaurant_id integer, p_id_client integer, p_date date) returns bool as
$$
declare
    v_total_services integer;
    v_client_services integer;

begin
    if is_restaurant_closed(p_restaurant_id, p_date) then
        return false;
    end if;

    select count(*)
    into v_total_services
    from services s
    where p_restaurant_id = s.restaurant and s.day_of_week = extract(isodow from p_date)::int;


    select count(distinct s.id)
    into v_client_services
    from services s join reservations rs on rs.restaurant = s.restaurant
    where rs.client = p_id_client
      and rs.restaurant = p_restaurant_id
      and s.day_of_week = extract(isodow from p_date)::int
      and rs.datetime::date = p_date
      and rs.status in ('pending', 'confirmed', 'completed')
      and rs.datetime::time >= s.start_time
      and rs.datetime::time < s.end_time;

    return v_total_services > 0 and v_client_services = v_total_services;
end;
$$language plpgsql security definer ;

/***************************************************************************
 si les tables encore disponibles pendant un service peuvent
 accueillir le nombre de convives demande.
****************************************************************************/

drop function if exists is_restaurant_has_capacity_for_service(integer, date, time, time, integer);
create or replace function is_restaurant_has_capacity_for_service(p_restaurant_id integer, p_date date , p_start_time time, p_end_time time ,p_number_of_guests int default 2)
    returns bool as
$$
declare available_capacity integer;
begin

    select coalesce(sum(t.capacity), 0)
    into available_capacity
    from tables t
    where t.restaurant = p_restaurant_id
      and not exists(
        select 1
        from reservations rs join reservation_tables rt on rs.id = rt.reservation
        where rt."table" = t.id
          and rs.restaurant = p_restaurant_id
          and rs.datetime::date = p_date
          and rs.datetime::time >= p_start_time
          and rs.datetime::time < p_end_time
          and rs.status in ('confirmed', 'completed')
    );
    return available_capacity >= p_number_of_guests;
end;
$$language plpgsql security definer;

/***************************************************************************
 Retourne les donnees necessaires au premier affichage de l'ecran
****************************************************************************/

drop function if exists get_first_available_reservation_slot(int, int);
create or replace function get_first_available_reservation_slot(p_restaurant_id integer, number_of_guests integer default 2)
    returns initial_reservation_data as
$$
declare
    v_reference_time       timestamp;
    v_start_date   date;
    v_service      record;
    v_current_slot time;
    v_slots time[] := '{}';
    v_over_capacity bool := false;

begin
    perform auth.check_logged();
    if (auth.role() != 'client') then
        raise exception 'Access denied';
    end if;

    v_reference_time := get_reference_time();

    v_start_date := v_reference_time::date;

    for v_service in
        select start_time, end_time, slot_duration
        from restaurants rt
                 join services s on rt.id = s.restaurant
        where s.restaurant = p_restaurant_id
          and s.day_of_week = extract(isodow from v_start_date)::int
        order by start_time
        loop
            if not is_client_has_reservation_in_service(
                    p_restaurant_id,
                    auth.id(),
                    v_start_date,
                    v_service.start_time,
                    v_service.end_time)
            then
                v_current_slot := v_service.start_time;

                while v_current_slot < v_service.end_time loop
                        if (v_start_date + v_current_slot) >= v_reference_time then
                            if(array_length(v_slots, 1) is null) then
                                v_over_capacity := not is_restaurant_has_capacity_for_service(
                                        p_restaurant_id,
                                        v_start_date,
                                        v_service.start_time,
                                        v_service.end_time ,
                                        number_of_guests);
                            end if;
                            v_slots := array_append(v_slots, v_current_slot);
                        end if;

                        v_current_slot := v_current_slot + (v_service.slot_duration || ' minutes')::interval;
                    end loop;
            end if;

        end loop;

    return row (
        get_restaurant_info(p_restaurant_id),
        v_start_date,
        v_slots[1],
        v_slots,
        is_restaurant_closed(p_restaurant_id, v_start_date),
        is_client_has_reservation_for_all_services(p_restaurant_id,auth.id(),v_start_date),
        v_over_capacity
        )::initial_reservation_data;
end;
$$ language plpgsql security definer;
grant execute on function get_first_available_reservation_slot(int, int) to authenticated;