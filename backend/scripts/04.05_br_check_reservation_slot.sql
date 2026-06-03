/************************************************************
Trigger pour vérifier le slot duration d'une réservation
*************************************************************/

DROP TRIGGER IF EXISTS check_reservation_slot_trigger ON reservations;
DROP FUNCTION IF EXISTS check_reservation_slot();

CREATE OR REPLACE FUNCTION check_reservation_slot()
    RETURNS TRIGGER AS $$
    DECLARE
        slot integer;
        reservation_minutes integer;
    BEGIN
        SELECT slot_duration INTO slot FROM restaurants WHERE id = NEW.restaurant;
        reservation_minutes := EXTRACT(minute FROM NEW.datetime::timestamp) +  EXTRACT(hour FROM NEW.datetime::timestamp) * 60;
        IF reservation_minutes % slot <> 0 THEN
            RAISE EXCEPTION 'Reservation time must match a reservation slot.';
        END IF;

        RETURN NEW;
    END;

    $$ LANGUAGE plpgsql;


CREATE TRIGGER check_reservation_slot_trigger
BEFORE INSERT OR UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION check_reservation_slot();


/**
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 1, '2024-12-06 19:10:00', 2, 'pending');

insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (4, 2, '2024-12-06 19:30:00', 2, 'pending');

update reservations set datetime = '2024-11-25 12:45:00' where id = 10;

update reservations set datetime = '2024-11-25 12:30:00' where id = 10;

insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 4, '2024-12-06 19:15:00', 2, 'pending');

insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 4, '2024-12-06 19:10:00', 2, 'pending'); **/