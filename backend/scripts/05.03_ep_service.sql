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
grant execute on function can_delete_service(integer) to authenticated;


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
grant execute on function delete_service(integer) to authenticated;

