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