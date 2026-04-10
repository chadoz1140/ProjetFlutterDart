/***************************************************************************
Trigger qui empêche la modification d'une réservation terminée ou annulée
****************************************************************************/

create or replace function reservation_not_editable()
    returns trigger as
$$
begin
     if old.status in ('completed', 'cancelled') then
        raise exception 'Reservation completed or cancelled: no changes possible.';
     end if;
     return new;
end;
$$ language plpgsql;

drop trigger if exists reservation_not_editable_trigger on reservations;

create trigger reservation_not_editable_trigger
    before update on reservations
    for each row
execute function reservation_not_editable();



