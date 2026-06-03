
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
              and r.status = 'pend'
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

