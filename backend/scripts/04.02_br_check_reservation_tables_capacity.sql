drop function if exists check_reservation_tables_capacity();

create or replace function check_reservation_tables_capacity()
       returns trigger as
$$
    declare nb_guest_old_reservation int;
    declare status_old_reservation text;

    begin
        select number_of_guests, status
        from reservations
        where id = old.reservation
        into nb_guest_old_reservation, status_old_reservation;

        if status_old_reservation in ('confirmed', 'completed') then
            if exists(
                select 1
                from reservation_tables rt join tables t on rt."table" = t.id
                where rt.reservation = old.reservation
                having sum(capacity) < nb_guest_old_reservation or sum(capacity) IS NULL
            ) then raise exception 'Le nombre de convives a dépassé  la capacité totale des tables associées à cette réservation ';
            end if;
        end if;

        return null;
    end;
$$ language plpgsql;

drop trigger if exists check_reservation_tables_capacity_trigger on reservation_tables;

create constraint trigger check_reservation_tables_capacity_trigger
after delete on reservation_tables
deferrable initially deferred
for each row
execute function check_reservation_tables_capacity();

-- cr   eate or replace trigger check_reservation_guests_trigger
-- before INSERT OR UPDATE
-- on reservations
-- for each row
-- execute function

-- update reservations set number_of_guests = 20 where id = 1;