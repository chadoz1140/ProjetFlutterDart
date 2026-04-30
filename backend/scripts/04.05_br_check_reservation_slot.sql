/************************************************************
Trigger pour vérifier le slot duration d'une réservation
*************************************************************/

create or replace function check_reservation_slot()
       returns trigger as
$$
declare
       slot integer;
       reservation_minutes integer;
begin
    -- Récupérer la durée de slot du restaurant
    select slot_duration
    into slot
    from restaurants
    where id = new.restaurant;

    -- Calculer les minutes de la réservation
    reservation_minutes := extract(minute from new.datetime)
                            + extract(hour from new.datetime) * 60;
    -- Vérifier que c'est un multiple de la durée du slot
     if reservation_minutes % slot <> 0 then
        raise exception 'Reservation time must match a reservation slot.';
     end if;
     return new;
end;

$$ language plpgsql;

drop trigger if exists check_reservation_slot_trigger on reservations;

create trigger check_reservation_slot_trigger
    before insert or update on reservations
    for each row
    execute function check_reservation_slot();
