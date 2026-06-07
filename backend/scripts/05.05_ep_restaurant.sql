
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

grant execute on function get_restaurant_details(int) to authenticated;


/**************************************************************
 Fonction qui permet de récupérer la liste de tous les restaurants
 **************************************************************/

/**
* Retourne les statistiques du client connecté pour chaque restaurant :
**/
drop function if exists get_clients_stats_by_restaurants();
create or replace function get_clients_stats_by_restaurants()
    returns setof restaurant_client_stats as
$$
begin
    return query
        select(row(
                   rs.restaurant,
                   max(rs.datetime),
                   coalesce(sum(case when rs.status = 'pending' then 1 else 0 end), 0)::int
                   )::restaurant_client_stats).*
        from reservations rs
        where rs.client = auth.id()
        group by rs.restaurant;
end;
$$ language plpgsql security definer;

/**
*  Retourne la liste des restaurants avec leurs statistiques pour le client connecté.
**/

drop function if exists get_restaurants(text, int);
create or replace function get_restaurants(search_restaurant text, result_number int)
    returns setof restaurant_with_client_info
as $$
declare
    search_like text;
begin
    perform auth.check_logged();

    if (auth.role() != 'client') then
        raise exception 'Access denied';
    end if;

    search_like := '%' || trim(search_restaurant) || '%';

    if search_restaurant is null or trim(search_restaurant) = '' then
        return query
            select(row(rt.id, rt.name, rt.city, rt.phone, rt.rating,
                       t.last_reservation_datetime,
                       coalesce(t.pending_count, 0)::int
                       )::restaurant_with_client_info).*
            from restaurants rt
                     left join get_clients_stats_by_restaurants() t
                               on rt.id = t.restaurant_id
            order by rt.name asc
            limit result_number;
    else
        return query
            select (row(rt.id, rt.name, rt.city, rt.phone, rt.rating,
                       t.last_reservation_datetime,
                       coalesce(t.pending_count, 0)::int
                       )::restaurant_with_client_info).*
            from restaurants rt
                     left join get_clients_stats_by_restaurants() t
                               on rt.id = t.restaurant_id
            where rt.name ilike search_like
               or rt.city ilike search_like
               or rt.description ilike search_like
            order by rt.name asc
            limit result_number;
    end if;
end;
$$ language plpgsql security definer;

grant execute on function get_restaurants(text, int) to authenticated;

/** Récuperer les restaurants du manager **/

drop function if exists get_my_restaurants();

create or replace function get_my_restaurants()
    returns setof restaurant_manager_info as
$$
select (row(
    r.id, r.name, r.address, r.city, r.phone, r.description,
    r.rating, r.price_range,
    max(res.datetime),
    coalesce(sum(case when res.status = 'pending' then 1 else 0 end), 0)::int
    )::restaurant_manager_info).*
from restaurants r
         join restaurant_managers rm on rm.restaurant = r.id
         left join reservations res on res.restaurant = r.id
where rm.manager = auth.id()
group by r.id, r.name, r.address, r.city, r.phone, r.description, r.rating, r.price_range
order by max(res.datetime) desc nulls last, r.name asc;
$$ language sql security definer;

grant execute on function get_my_restaurants() to authenticated;

