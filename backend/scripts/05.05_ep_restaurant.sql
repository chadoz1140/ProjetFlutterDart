
/** Récupère les informations de base d'un restaurant **/

drop function if exists get_restaurant_info(restaurant_id int);

create or replace function get_restaurant_info(restaurant_id int)
    returns restaurant_info as
$$
select row (id, name, address, city, phone, description, rating, price_range, slot_duration)::restaurant_info
from restaurants as r
where r.id = restaurant_id

$$language sql security definer;

/** Récupère les informations complètes d'un restaurant avec ses tables et services **/

drop function if exists get_restaurant_details(restaurant_id int);

create or replace function get_restaurant_details(restaurant_id int)
    returns restaurant_details as
$$
select row (r.id, r.name, r.address, r.city, r.phone,
           r.description, r.rating, r.price_range, r.slot_duration,
           get_table_info_by_restaurant_id(restaurant_id),
           get_service_info_by_restaurant_id(restaurant_id))::restaurant_details
from restaurants as r
where r.id = restaurant_id

$$language sql security definer;

/**************************************************************
 Fonction qui permet de récupérer la liste de tous les restaurants
 **************************************************************/

drop function if exists get_restaurants(text, int);
create or replace function get_restaurants(search_restaurant text, result_number int)

    returns table (
                      id int,
                      name varchar(256),
                      city varchar(256),
                      phone varchar(256),
                      rating double precision,
                      last_reservation_datetime timestamp,
                      pending_requests_count int
    ) as
$$
declare search_like text;
    begin
    search_like := '%' || trim(search_restaurant) || '%';
        perform auth.check_logged();

        if (auth.role() != 'client') then
            raise exception 'Access denied';
        end if;

        if(search_restaurant is null or trim(search_restaurant) = '') then
            return query select rt.id, rt.name, rt.city, rt.phone, rt.rating, t.last_reservation_datetime, coalesce(t.pending_count, 0)::int as pending_count
                         from restaurants rt
                         left join (
                             select rs.restaurant,
                             max(rs.datetime) as last_reservation_datetime,
                             sum(
                                    case
                                        when rs.status = 'pending' then 1
                                        else 0
                                    end
                             ) as pending_count
                             from reservations rs
                             where rs.client = auth.id()
                             group by rs.restaurant
                         ) t on rt.id = t.restaurant
                         order by rt.name asc
                         limit result_number;
        else
            return query select rt.id, rt.name, rt.city, rt.phone, rt.rating, t.last_reservation_datetime, coalesce(t.pending_count, 0)::int as pending_count
                         from restaurants rt
                         left join (
                            select rs.restaurant,
                            max(rs.datetime) as last_reservation_datetime,
                            sum(
                                    case
                                        when rs.status = 'pending' then 1
                                        else 0
                                    end
                            ) as pending_count
                            from reservations rs
                            where rs.client = auth.id()
                            group by rs.restaurant
                        ) t on rt.id = t.restaurant
                         where rt.name ilike search_like or rt.city ilike search_like or rt.description ilike search_like
                         order by rt.name asc
                         limit result_number;
        end if;
    end;
$$language plpgsql security definer;

grant execute on function get_restaurants(text, int) to authenticated;

