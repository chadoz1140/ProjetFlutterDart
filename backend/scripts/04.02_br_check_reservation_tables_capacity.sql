create or replace function check_reservation_tables_capacity()
       returns trigger as
$$
    declare nb_guest_new_reservation int;
    declare nb_guest_old_reservation int;

    declare status_new_reservation text;
    declare status_old_reservation text;

    declare tables_capacity_for_new_reservation int;
    declare tables_capacity_for_old_reservation int;

    begin
        if tg_op in ('INSERT') then
            select number_of_guests
            from reservations
            where id = new.reservation
            into nb_guest_new_reservation;

            select status
            from reservations
            where id = new.reservation
            into status_new_reservation;

            if status_new_reservation in (('confirmed', 'completed'))
            then
                select sum(capacity)
                from reservation_tables rt
                         join tables t on rt."table" = t.id
                where reservation = new.reservation
                into tables_capacity_for_new_reservation;

                if (tables_capacity_for_new_reservation is null) then
                    raise exception 'la réservation n''a pas de table';
                else
                    if (tables_capacity_for_new_reservation < nb_guest_new_reservation) then
                        raise exception 'Le nombre de convives a dépassé  la capacité totale des tables associées à cette réservation ';
                    end if;
                end if;
            end if;
        elseif tg_op in ('DELETE') then
            select number_of_guests
            from reservations
            where id = old.reservation
            into nb_guest_old_reservation;

            select status
            from reservations
            where id = old.reservation
            into status_old_reservation;

            if status_old_reservation in ('confirmed', 'completed')
            then
                select sum(capacity)
                from reservation_tables rt
                         join tables t on rt."table" = t.id
                where reservation = old.reservation
                into tables_capacity_for_old_reservation;

                if (tables_capacity_for_old_reservation is null) then
                    raise exception 'la réservation n''a pas de table';
                else
                    if (tables_capacity_for_old_reservation < nb_guest_old_reservation) then
                        raise exception 'Le nombre de convives a dépassé  la capacité totale des tables associées à cette réservation ';
                    end if;
                end if;
            end if;

        elseif tg_op in ('UPDATE') then
            select number_of_guests
            from reservations
            where id = old.reservation
            into nb_guest_old_reservation;

            select status
            from reservations
            where id = old.reservation
            into status_old_reservation;

            if status_old_reservation in ('confirmed', 'completed')
            then
                select sum(capacity)
                from reservation_tables rt
                         join tables t on rt."table" = t.id
                where reservation = old.reservation
                into tables_capacity_for_old_reservation;

                if (tables_capacity_for_old_reservation is null) then
                    raise exception 'la réservation n''a pas de table';
                else
                    if (tables_capacity_for_old_reservation < nb_guest_old_reservation) then
                        raise exception 'Le nombre de convives a dépassé  la capacité totale des tables associées à cette réservation ';
                    end if;
                end if;
            end if;

            if (old.reservation != new.reservation) then
                select number_of_guests
                from reservations
                where id = new.reservation
                into nb_guest_new_reservation;

                select status
                from reservations
                where id = new.reservation
                into status_new_reservation;

                if status_new_reservation in ('confirmed', 'completed')
                then
                    select sum(capacity)
                    from reservation_tables rt
                             join tables t on rt."table" = t.id
                    where reservation = new.reservation
                    into tables_capacity_for_new_reservation;

                    if (tables_capacity_for_new_reservation is null) then
                        raise exception 'la réservation n''a pas de table';
                    else
                        if (tables_capacity_for_new_reservation < nb_guest_new_reservation) then
                            raise exception 'Le nombre de convives a dépassé  la capacité totale des tables associées à cette réservation ';
                        end if;
                    end if;
                end if;
            end if;

        end if;
        return null;
    end;
$$ language plpgsql;

create or replace trigger check_reservation_tables_capacity_trigger
AFTER INSERT OR UPDATE OR DELETE
on reservation_tables
for each row
execute function check_reservation_tables_capacity();

-- cr   eate or replace trigger check_reservation_guests_trigger
-- before INSERT OR UPDATE
-- on reservations
-- for each row
-- execute function

-- update reservations set number_of_guests = 20 where id = 1;