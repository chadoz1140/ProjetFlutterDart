/** Récupère les informations de base des tables d'un restaurant  **/
drop function if exists get_table_info_by_restaurant_id(restaurant_id int);

create or replace function get_table_info_by_restaurant_id(restaurant_id int)
    returns table_info[] as
$$
    select array(
                   select row(t.id, t.restaurant, t.table_number, t.capacity)::table_info
                   from tables as t
                   where t.restaurant = restaurant_id
                   order by t.table_number);

$$language sql security definer;

/** Récupère la liste des tables  d'un restaurant **/

drop function if exists get_tables_by_restaurant(int);

create or replace function get_tables_by_restaurant(restaurant_id int)
    returns setof table_info as
$$
begin
    perform auth.check_logged();

    if auth.role() != 'manager' then
        raise exception 'Access denied';
    end if;

    return query
        select t.id, t.restaurant, t.table_number, t.capacity
        from tables t
        where t.restaurant = restaurant_id
        order by t.capacity asc, t.table_number asc;

end;
$$ language plpgsql security definer;

grant execute on function get_tables_by_restaurant(int) to manager;

-- Capacité minimum d'une table
drop function if exists get_min_capacity_for_table(int);

create or replace function get_min_capacity_for_table(table_id int)
    returns int as $$
declare min int;
begin
    if auth.role() != 'manager' then raise exception 'Access denied'; end if;
    select coalesce(max(r.number_of_guests), 1) into min
    from reservations r
             join reservation_tables rt on rt.reservation = r.id
    where rt.table = table_id and r.status != 'cancelled';
    return min;
end;
$$ language plpgsql security definer ;

grant execute on function get_min_capacity_for_table(int) to manager;


-- Ajouter une table
drop function if exists add_table(int, int, int);

create or replace function add_table(p_restaurant_id int, p_table_number int, p_capacity int)
    returns table_info as
$$
    declare
        v_id int;
    begin
        if auth.role() != 'manager' then
            raise exception 'Access denied';
        end if;

        insert into tables(restaurant, table_number, capacity)
        values (p_restaurant_id, p_table_number, p_capacity)
        returning id into v_id;
        return (
            select row(t.id, t.restaurant, t.table_number, t.capacity)::table_info
            from tables t
            where t.id = v_id
        );
    end;
$$ language plpgsql security definer;

grant execute on function add_table(int, int, int) to manager;

-- Editer une table
drop function if exists update_table(int, int, int);

create or replace function update_table(p_table_id int, p_table_number int, p_capacity int)
    returns table_info as
$$
begin
    if auth.role() != 'manager' then
        raise exception 'Access denied';
    end if;

    update tables
    set table_number = p_table_number,
        capacity = p_capacity
    where id = p_table_id;

    return (
        select row (t.id, t.restaurant, t.table_number, t.capacity)::table_info
        from tables t
        where t.id = p_table_id
    );

end;
$$ language plpgsql security definer;

grant execute on function update_table(int, int, int) to manager;

revoke execute on function get_table_info_by_restaurant_id(int) from anon;
grant execute on function get_table_info_by_restaurant_id(int) to authenticated;

---Récupère les informations de base des tables réservé et non réservé d'un restaurant à partir de l'id de la reservation courante----
drop function if exists get_table_info_status_by_reservation_id(reservation_id int);

create or replace function get_table_info_status_by_reservation_id(reservation_id int)
    returns table_info_by_status as
$$
    select row(
        array(select row (t.id, t.restaurant, t.table_number, t.capacity)::table_info
              from reservations as r
                join services as s on s.restaurant = r.restaurant
                join tables as t on t.restaurant = r.restaurant
                join restaurant_managers as rm on rm.restaurant = r.restaurant
              where r.id = reservation_id
                and rm.manager = auth.id()
                and extract(isodow from r.datetime) = s.day_of_week
                and r.datetime::time >= s.start_time
                and r.datetime::time <= s.end_time and t.id in (select rt."table"
                                                                    from reservation_tables as rt
                                                                      join reservations as r2 on r2.id = rt.reservation
                                                                    where r2.status in ('confirmed', 'completed')
                                                                      and r2.restaurant = r.restaurant
                                                                      and r2.datetime::time >= s.start_time
                                                                      and r2.datetime::time <= s.end_time
                                                                      and r2.datetime::date = r.datetime::date)
              order by t.table_number)::table_info[],

        array(select row (t.id, t.restaurant, t.table_number, t.capacity)::table_info
              from reservations as r
                join services as s on s.restaurant = r.restaurant
                join tables as t on t.restaurant = r.restaurant
                join restaurant_managers as rm on rm.restaurant = r.restaurant
              where r.id = reservation_id
                and rm.manager = auth.id()
                and extract(isodow from r.datetime) = s.day_of_week
                and r.datetime::time >= s.start_time
                and r.datetime::time <= s.end_time and t.id not in (select rt."table"
                                                                    from reservation_tables as rt
                                                                      join reservations as r2 on r2.id = rt.reservation
                                                                    where r2.status in ('confirmed', 'completed')
                                                                      and r2.restaurant = r.restaurant
                                                                      and r2.datetime::time >= s.start_time
                                                                      and r2.datetime::time <= s.end_time
                                                                      and r2.datetime::date = r.datetime::date)
              order by t.table_number)::table_info[]
    );

$$language sql security definer;

revoke execute on function get_table_info_status_by_reservation_id(int) from anon;
grant execute on function get_table_info_status_by_reservation_id(int) to authenticated;