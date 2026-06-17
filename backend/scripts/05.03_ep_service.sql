/** Récupère les informations de base d'un service **/
drop function if exists get_service_info_by_restaurant_id(restaurant_id int);

create or replace function get_service_info_by_restaurant_id(restaurant_id int)
    returns service_info[] as
$$
    select array(
                   select row(s.id, s.restaurant, s.day_of_week, s.start_time, s.end_time)::service_info
                   from services as s
                   where s.restaurant = restaurant_id
                   order by s.day_of_week, s.start_time, s.end_time);

$$language sql security definer;

grant execute on function get_service_info_by_restaurant_id(int) to authenticated;



drop function if exists can_delete_service(integer);
create or replace function can_delete_service(service_id integer )
    returns bool as
$$
    declare v_restaurant_id integer;
    begin
        perform auth.check_logged();
        if(auth.role() != 'manager') then
            raise exception 'Access denied';
        end if;

        select s.restaurant
        into v_restaurant_id
        from services s
        where s.id = service_id;

        if not found then
            raise exception 'Service not found';
        end if;

        if exists(
            select 1
            from restaurant_managers rm
            where rm.manager = auth.id() and rm.restaurant = v_restaurant_id
        )then
            return not exists(select 1
                              from services s
                                       join reservations rs on rs.restaurant = s.restaurant
                              where s.id = service_id
                                and s.day_of_week = extract(isodow from rs.datetime)::int
                                and rs.datetime::time >= s.start_time
                                and rs.datetime::time <= s.end_time
                                and rs.status in ('pending', 'confirmed', 'completed'));
        else
            return false;
        end if;
    end;
$$language plpgsql security definer;
grant execute on function can_delete_service(integer) to manager;


drop function if exists delete_service(integer);
create or replace function delete_service(service_id integer)
    returns void as
$$
    begin
        perform auth.check_logged();
        if(auth.role() != 'manager') then
            raise exception 'Access denied';
        end if;
        if (can_delete_service(service_id)) then
            delete from services s where s.id = service_id;
            if not found then
                raise exception 'Service % not found', service_id;
            end if;
        else
            raise exception 'Service cannot be deleted because it has existing reservations.';
        end if;
    end;
$$language plpgsql security definer;
grant execute on function delete_service(integer) to manager;

/***************************************************************************
 Vérifie qu'un service ne chevauche aucun autre service du même restaurant
 pour le même jour, lors de sa création ou de sa modification.
****************************************************************************/

drop function if exists check_overlapping_services(
    integer, integer, time, time, integer
);

create or replace function check_overlapping_services(
    p_restaurant_id integer,
    p_day_of_week integer,
    new_start_time time,
    new_end_time time,
    p_id_service integer default null
)
    returns void as
$$
begin
    perform auth.check_logged();

    if auth.role() != 'manager' then
        raise exception 'Access denied';
    end if;

    if not exists (select 1
                   from restaurant_managers rm
                   where rm.manager = auth.id()
                     and rm.restaurant = p_restaurant_id) then
        raise exception 'Access denied';
    end if;

    if exists (select 1
               from services s
               where s.restaurant = p_restaurant_id
                 and s.day_of_week = p_day_of_week
                 and (p_id_service is null or s.id <> p_id_service)
                 and new_start_time < s.end_time
                 and new_end_time > s.start_time) then
        raise exception 'Ce service cheavauche avec un service existant %', p_day_of_week;
    end if;
end;
$$ language plpgsql security definer;

grant execute on function check_overlapping_services(integer, integer, time, time, integer) to manager;

/***************************************************************************
 Compte les réservations en attente ou confirmées qui sortiraient des
 horaires du service après la modification de son jour ou de ses heures.
****************************************************************************/

drop function if exists count_reservations_outside_service(integer, integer, time, time, integer);
create or replace function count_reservations_outside_service(p_restaurant_id integer,
    new_day_of_week integer,
    new_start_time time,
    new_end_time time,
    p_id_service integer
)
    returns integer as
$$
    declare number_reservations_outside_service integer;
    begin
        perform auth.check_logged();
        if auth.role() != 'manager' then
            raise exception 'Access denied';
        end if;

        if not exists (select 1
                       from restaurant_managers rm
                       where rm.manager = auth.id()
                         and rm.restaurant = p_restaurant_id) then
            raise exception 'Access denied';
        end if;

        select count(*)::int
        into number_reservations_outside_service
        from reservations rs
                 join services s on s.id = p_id_service
        where rs.restaurant = s.restaurant
          and rs.status in ('pending', 'confirmed')

          and extract(isodow from rs.datetime)::int = s.day_of_week
          and rs.datetime::time >= s.start_time
          and rs.datetime::time <= s.end_time
          and s.restaurant = p_restaurant_id
          and (
            extract(isodow from rs.datetime)::int <> new_day_of_week
                or rs.datetime::time < new_start_time
                or rs.datetime::time > new_end_time
            );

        return number_reservations_outside_service;
    end;
$$language plpgsql security definer;
grant execute on function count_reservations_outside_service(integer, integer, time, time, integer) to manager;

/***************************************************************************
 Vérifiecation des règles métier avant la création ou la modification d'un service
****************************************************************************/

drop function if exists check_service_business_rules(integer, integer, time, time, integer);
create or replace function check_service_business_rules(
    p_restaurant_id integer,
    p_day_of_week integer,
    p_start_time time,
    p_end_time time,
    p_id_service integer default null
)
    returns void as
$$
declare
    v_reservations_count integer;
begin
    perform check_overlapping_services(
            p_restaurant_id,
            p_day_of_week,
            p_start_time,
            p_end_time,
            p_id_service
            );

    if p_id_service is not null then
        v_reservations_count := count_reservations_outside_service(
                p_restaurant_id,
                p_day_of_week,
                p_start_time,
                p_end_time,
                p_id_service
                                );

        if v_reservations_count > 0 then
            raise exception 'Modification impossible : % réservations confirmées ou en attente seraient en dehors des horaires du service.',
                v_reservations_count;
        end if;
    end if;
end;
$$ language plpgsql security definer;
grant execute on function check_service_business_rules(integer, integer, time, time, integer) to manager;


/***************************************************************************
 Crée un nouveau service ou modifie un service existant après vérification
****************************************************************************/


drop function if exists save_service(integer, integer, integer, time, time);
create or replace function save_service(id_service integer, id_restaurant integer, day_of_week integer, start_time time, end_time time)
    returns services as
$$
    declare service services;
    begin

        perform check_service_business_rules(
                save_service.id_restaurant,
                save_service.day_of_week,
                save_service.start_time,
                save_service.end_time,
                save_service.id_service
                );
        if save_service.id_service is null then
            insert into services(restaurant, day_of_week, start_time, end_time)
            VALUES(save_service.id_restaurant, save_service.day_of_week, save_service.start_time, save_service.end_time)
            returning * into service;
        else
            update services s
            set day_of_week = save_service.day_of_week,
                start_time = save_service.start_time,
                end_time = save_service.end_time
            where s.id = save_service.id_service
              and s.restaurant = save_service.id_restaurant
            returning * into service;

            if not found then
                raise exception 'Service with id % not found',
                    save_service.id_service;
            end if;
        end if;
        return service;
    end;

$$language plpgsql security definer;
grant execute on function save_service(integer, integer, integer, time, time) to manager;