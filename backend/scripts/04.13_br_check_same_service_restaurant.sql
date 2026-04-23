drop function if exists check_same_service_restaurant_reservation_fct();
create or replace function check_same_service_restaurant_reservation_fct()

                  returns trigger as
$$
    begin
        if new.status not in ('pending', 'confirmed', 'completed') then
            return new;
        end if;

        if exists(
            select 1
            from reservations r, services s
            where r.status in('pending', 'confirmed', 'completed')
            and r.client = new.client

            and extract(isodow from new.datetime) = s.day_of_week
            and new.datetime::time between s.start_time and s.end_time

            and extract(isodow from r.datetime) = s.day_of_week --même jour que celui de new
            and r.datetime::time between s.start_time and s.end_time --meme service que celui de new

            and r.datetime::date = new.datetime::date --même date

            and r.restaurant = new.restaurant
            and s.restaurant = new.restaurant --pour que le sql prend pas un autre service d'un autre restaut

            and r.id != new.id --deux réservation différent

        ) then raise exception 'Client already has a reservation in this service';
        end if;
        return new;
    end;

$$language plpgsql;

drop trigger if exists check_same_service_restaurant_reservation_trigger on reservations;
create or replace trigger check_same_service_restaurant_reservation_trigger
before INSERT OR UPDATE
on reservations
for each row
execute function check_same_service_restaurant_reservation_fct();

/**************************************************************
***********    Tests ******
**************************************************************/

/**************** test valide deux horaires différents *****************/
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (1, 1, '2024-11-18 12:30:00', 2, 'confirmed');

insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (1, 1, '2024-11-18 20:00:00', 2, 'confirmed');

-- UPDATE doit être bloquer
update reservations
set datetime = '2024-11-18 20:00:00'
where client = 1 and datetime = '2024-11-18 12:30:00';

/**************** test invalide deux reservation ont même horaires *****************/
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (2, 1, '2024-11-18 19:30:00', 2, 'confirmed');

insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (2, 1, '2024-11-18 20:30:00', 2, 'confirmed');


/**************** test valide deux reservation ont même horaires mais deux restau différent *****************/
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 1, '2024-11-18 20:00:00', 2, 'confirmed');

insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 2, '2024-11-18 20:00:00', 2, 'confirmed');