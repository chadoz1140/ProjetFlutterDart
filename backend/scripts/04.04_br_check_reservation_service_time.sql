/************************************************************
Trigger pour vérifier les horaires du service de réservation
*************************************************************/
create or replace function check_reservation_service_time()
       returns trigger as
$$
begin
    if new.status in ('pending', 'confirmed', 'completed') then
        if not exists (
            select 1
            from services s
            where s.restaurant = new.restaurant
              and s.day_of_week = extract(dow from new.datetime)
              and s.start_time <= new.datetime::time
              and s.end_time > new.datetime::time
        ) then
            raise exception 'Reservation time must be within a service period for that restaurant.';
        end if;
    end if;
    return new;
end;
$$ language plpgsql;

drop trigger if exists check_reservation_service_time_trigger on reservations;

create trigger check_reservation_service_time_trigger
before insert or update  on reservations
for each row
execute function check_reservation_service_time();







