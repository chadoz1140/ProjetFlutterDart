
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

/** Récupère les informations de base des tables d'une reservation  **/
drop function if exists get_table_details_by_reservation_id(reservation int);

create or replace function get_table_details_by_reservation_id(reservation_id int)
    returns table_details[] as
$$
select array(
               select row(t.id, get_restaurant_info(t.restaurant), t.table_number, t.capacity)::table_details
               from tables as t
                        join reservation_tables as rt on rt.table = t.id
               where rt.reservation = reservation_id
               order by t.table_number
       );

$$language sql security definer;

drop function if exists get_reservations_details_manager(int);

create or replace function get_reservations_details_manager(reservation_id int)
    returns reservation_details_manager as
    $$
        select row(r.id, r.datetime, r.number_of_guests, r.status, r.special_requests,
                   get_client_info(r.client), get_restaurant_info(r.restaurant),
                   get_table_details_by_reservation_id(r.id))::reservation_details_manager
        from reservations r
        where r.id = reservation_id and exists(select *
                                               from restaurant_managers as rm
                                               /* on vérifie que user est bien le manager du restaurant (rm.manager = auth.id())
                                                et que le restaurant de l'user est le meme que celui de la réservation (rm.restaurant = r.restaurant) */
                                               where rm.manager = auth.id() and rm.restaurant = r.restaurant);

    $$language sql security definer ;

grant execute on function get_reservations_details_manager(int) to authenticated;

/*Annule une réservation*/

drop function if exists cancel_reservation(reservation_id int);

create or replace function cancel_reservation(reservation_id int)
    returns reservation_details as
$$
    declare
        updated_reservation reservations;
    begin
        if not exists (
            select 1
            from reservations r
            where r.id = cancel_reservation.reservation_id
              and r.client = auth.id()
              and r.status in ('pending', 'confirmed')
        ) then
            raise exception 'Reservation not found or not cancellable';
        end if;

        delete from reservation_tables rt
        where rt.reservation = cancel_reservation.reservation_id;

        update reservations r
        set status = 'cancelled'
        where r.id = cancel_reservation.reservation_id
          and r.client = auth.id()
        returning * into updated_reservation;

        return get_reservation_details(updated_reservation.id);
    end;
$$ language plpgsql security definer;

revoke execute on function public.cancel_reservation(int) from anon;
grant execute on function public.cancel_reservation(int) to authenticated;

---------- Annule une réservation ----------
drop function if exists cancel_reservation_manager(reservation_id int);

create or replace function cancel_reservation_manager(reservation_id int)
    returns reservation_details_manager as
$$
    declare
        updated_reservation reservations;
    begin
        if not exists (
            select *
            from reservations r
                join restaurant_managers rm on rm.restaurant = r.restaurant
            where r.id = cancel_reservation_manager.reservation_id
              and rm.manager = auth.id()
              and r.status in ('pending', 'confirmed')
        ) then
            raise exception 'Reservation not found or not cancellable';
        end if;

        delete from reservation_tables rt
        where rt.reservation = cancel_reservation_manager.reservation_id;

        update reservations r
        set status = 'cancelled'
        where r.id = cancel_reservation_manager.reservation_id
        returning * into updated_reservation;

        return get_reservations_details_manager(updated_reservation.id);

    end;
$$ language plpgsql security definer;

revoke execute on function cancel_reservation_manager(int) from anon;
grant execute on function cancel_reservation_manager(int) to authenticated;

---------- Termine une réservation ----------

drop function if exists completed_reservation_manager(reservation_id int);

create or replace function completed_reservation_manager(reservation_id int)
    returns reservation_details_manager as
$$
    declare
        updated_reservation reservations;
    begin
        if not exists (
            select *
            from reservations r
                join restaurant_managers rm on rm.restaurant = r.restaurant
            where r.id = completed_reservation_manager.reservation_id
              and rm.manager = auth.id()
              and r.status = 'confirmed'
        ) then
            raise exception 'Reservation not found or not completable';
        end if;

        update reservations r
        set status = 'completed'
        where r.id = completed_reservation_manager.reservation_id
        returning * into updated_reservation;

        return get_reservations_details_manager(updated_reservation.id);

    end;
$$ language plpgsql security definer;

revoke execute on function completed_reservation_manager(int) from anon;
grant execute on function completed_reservation_manager(int) to authenticated;

---------- Confirmé une réservation ----------

drop function if exists confirmed_reservation_manager(reservation_id int);

create or replace function confirmed_reservation_manager(reservation_id int)
    returns reservation_details_manager as
$$
    declare
        updated_reservation reservations;
    begin
        if not exists (
            select *
            from reservations r
                join restaurant_managers rm on rm.restaurant = r.restaurant
            where r.id = confirmed_reservation_manager.reservation_id
              and rm.manager = auth.id()
              and r.status = 'pending'
        ) then
            raise exception 'Reservation not found or not completable';
        end if;

        update reservations r
        set status = 'confirmed'
        where r.id = confirmed_reservation_manager.reservation_id
        returning * into updated_reservation;

        return get_reservations_details_manager(updated_reservation.id);

    end;
$$ language plpgsql security definer;

revoke execute on function confirmed_reservation_manager(int) from anon;
grant execute on function confirmed_reservation_manager(int) to authenticated;


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
 Construit les donnees de reservation pour un restaurant et une date donnee
****************************************************************************/

drop function if exists build_reservation_slots_data(integer, date, integer);

create or replace function build_reservation_slots_data(
    p_restaurant_id integer,
    p_date date,
    p_number_of_guests integer default 2
)
    returns initial_reservation_data as
$$
declare
    v_reference_time timestamp;
    v_service record;
    v_current_slot time;
    v_slots time[] := '{}';
    v_over_capacity boolean := false;
begin
    v_reference_time := get_reference_time();

    for v_service in
        select s.start_time, s.end_time, rt.slot_duration
        from services s
                 join restaurants rt on rt.id = s.restaurant
        where s.restaurant = p_restaurant_id
          and s.day_of_week = extract(isodow from p_date)::int
        order by s.start_time
        loop
            if not is_client_has_reservation_in_service(
                    p_restaurant_id,
                    auth.id(),
                    p_date,
                    v_service.start_time,
                    v_service.end_time
                   ) then

                v_current_slot := v_service.start_time;
                while v_current_slot < v_service.end_time loop
                        if (p_date + v_current_slot) >= v_reference_time then

                            if array_length(v_slots, 1) is null then
                                v_over_capacity := not is_restaurant_has_capacity_for_service(
                                        p_restaurant_id,
                                        p_date,
                                        v_service.start_time,
                                        v_service.end_time,
                                        p_number_of_guests
                                                       );
                            end if;
                            v_slots := array_append(v_slots, v_current_slot);
                        end if;
                        v_current_slot := v_current_slot + (v_service.slot_duration || ' minutes')::interval;
                    end loop;
            end if;
        end loop;
    return row(
        get_restaurant_info(p_restaurant_id),
        p_date,
        v_slots[1],
        v_slots,
        is_restaurant_closed(p_restaurant_id, p_date),
        is_client_has_reservation_for_all_services(p_restaurant_id, auth.id(), p_date),
        v_over_capacity
        )::initial_reservation_data;
end;
$$ language plpgsql security definer;


/***************************************************************************
 Retourne les donnees necessaires au premier affichage de l'ecran
****************************************************************************/

drop function if exists get_first_available_reservation_slot(int, int);
create or replace function get_first_available_reservation_slot(
    p_restaurant_id integer,
    number_of_guests integer default 2
)
    returns initial_reservation_data as
$$
declare
    v_reference_time timestamp;
begin
    perform auth.check_logged();

    if auth.role() != 'client' then
        raise exception 'Access denied';
    end if;

    v_reference_time := get_reference_time();

    return build_reservation_slots_data(
            p_restaurant_id,
            v_reference_time::date,
            number_of_guests
           );
end;
$$ language plpgsql security definer;
grant execute on function get_first_available_reservation_slot(int, int) to authenticated;

/***************************************************************************
 Retourne les creneaux disponibles pour une date choisie
****************************************************************************/

drop function if exists get_reservation_slots(integer, date, integer);
create or replace function get_reservation_slots(
    p_restaurant_id integer,
    p_date date,
    p_number_of_guests integer default 2
)
    returns initial_reservation_data as
$$
begin
    perform auth.check_logged();

    if auth.role() != 'client' then
        raise exception 'Access denied';
    end if;

    return build_reservation_slots_data(
            p_restaurant_id,
            p_date,
            p_number_of_guests
           );
end;
$$ language plpgsql security definer;
grant execute on function get_reservation_slots(integer, date, integer) to authenticated;

/***************************************************************************
 Verifie si le nombre de convives depasse la capacite disponible
 pour le creneau choisi
****************************************************************************/

drop function if exists check_reservation_over_capacity(integer, date, time, integer);
create or replace function check_reservation_over_capacity(
    p_restaurant_id integer,
    p_date date,
    p_slot time,
    p_number_of_guests integer
)
    returns boolean as
$$
declare
    v_service record;
begin

    perform auth.check_logged();

    if auth.role() != 'client' then
        raise exception 'Access denied';
    end if;

    select s.start_time, s.end_time
    into v_service
    from services s
    where s.restaurant = p_restaurant_id
      and s.day_of_week = extract(isodow from p_date)::int
      and p_slot >= s.start_time
      and p_slot < s.end_time
    limit 1;

    if v_service is null then
        raise exception 'No service found for this slot.';
    end if;

    return not is_restaurant_has_capacity_for_service(
            p_restaurant_id,
            p_date,
            v_service.start_time,
            v_service.end_time,
            p_number_of_guests
               );
end;
$$ language plpgsql security definer;
grant execute on function check_reservation_over_capacity(integer, date, time, integer) to authenticated;


/***************************************************************************
 Cree une nouvelle reservation client en statut pending
****************************************************************************/

drop function if exists save_reservation(integer, timestamp, integer, text);
create or replace function save_reservation(
    p_restaurant_id integer,
    p_datetime timestamp,
    p_number_of_guests integer,
    p_special_requests text default null
)
    returns reservation_details as
$$
declare
    v_reservation_id integer;

begin
    perform auth.check_logged();

    if auth.role() != 'client' then
        raise exception 'Access denied';
    end if;

    insert into reservations (
        client,
        restaurant,
        datetime,
        number_of_guests,
        status,
        special_requests
    )
    values (
               auth.id(),
               p_restaurant_id,
               p_datetime,
               p_number_of_guests,
               'pending',
               nullif(trim(p_special_requests), '')
           )
    returning id into v_reservation_id;
    return get_reservation_details(v_reservation_id);
end;
$$ language plpgsql security definer;

grant execute on function save_reservation(integer, timestamp, integer, text) to authenticated;

/********************************************************
  Retourne les créneaux disponibles pour une date donnée
*************************************************************/

drop function if exists get_slots_for_date(integer, date, integer);

create or replace function get_slots_for_date(p_restaurant_id integer, p_date date, p_number_of_guests integer default 2)
    returns reservation_edit_data as
$$
declare
    v_service       record;
    v_current_slot  time;
    v_slots         time[]  := '{}';
    v_over_capacity boolean := false;
begin
    for v_service in
        select s.start_time, s.end_time, rt.slot_duration
        from services s
                 join restaurants rt on rt.id = s.restaurant
        where s.restaurant = p_restaurant_id
          and s.day_of_week = extract(isodow from p_date)::int
        order by s.start_time
        loop
            v_current_slot := v_service.start_time;
            while v_current_slot < v_service.end_time loop
                    if array_length(v_slots, 1) is null then
                        v_over_capacity := not is_restaurant_has_capacity_for_service(
                                p_restaurant_id, p_date,
                                v_service.start_time, v_service.end_time,
                                p_number_of_guests);
                    end if;
                    v_slots        := array_append(v_slots, v_current_slot);
                    v_current_slot := v_current_slot + (v_service.slot_duration || ' minutes')::interval;
                end loop;
        end loop;

    return row(v_slots, is_restaurant_closed(p_restaurant_id, p_date), v_over_capacity)::reservation_edit_data;
end;
$$ language plpgsql security definer;

grant execute on function get_slots_for_date(integer, date, integer) to authenticated;


/*****************************************************************************
 Met à jour une réservation. Si elle était confirmée, elle repasse à pending
******************************************************************************/

drop function if exists update_reservation(integer, timestamp, integer, text);

create or replace function update_reservation(
    p_reservation_id   integer,
    p_datetime         timestamp,
    p_number_of_guests integer,
    p_special_requests text default null
)
    returns void as
$$
declare
    v_old_status status_type;
begin
    if not exists (
        select 1 from reservations r join users u on u.id = r.client
        where r.id = p_reservation_id and u.email = auth.email()
    ) then
        raise exception 'Réservation introuvable.';
    end if;

    select status into v_old_status from reservations where id = p_reservation_id;

    if v_old_status = 'confirmed' then
        delete from reservation_tables where reservation = p_reservation_id;
        update reservations
        set datetime         = p_datetime,
            number_of_guests = p_number_of_guests,
            special_requests = p_special_requests,
            status           = 'pending'
        where id = p_reservation_id;
    else
        update reservations
        set datetime         = p_datetime,
            number_of_guests = p_number_of_guests,
            special_requests = p_special_requests
        where id = p_reservation_id;
    end if;
end;
$$ language plpgsql security definer;

grant execute on function update_reservation(integer, timestamp, integer, text) to authenticated;

grant select on reservation_tables to authenticated;
grant select on reservations to authenticated;



