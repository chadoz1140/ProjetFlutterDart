/***********************************************************************************
Trigger qui empêche la modification d'un client ou d'un restaurant d'une réservation
************************************************************************************/

create or replace function reservation_no_change_restaurant_client()
       returns trigger as
$$
begin
    if new.restaurant is distinct from old.restaurant
        or new.client is distinct from old.client then
        raise exception 'Cannot changed the client or restaurant reservation.';
    end if;
    return new;
end;
$$ language plpgsql;

drop trigger if exists reservation_no_change_trigger on reservations;

create trigger reservation_no_change_trigger
before update of restaurant, client
on reservations
for each row
execute function reservation_no_change_restaurant_client();



