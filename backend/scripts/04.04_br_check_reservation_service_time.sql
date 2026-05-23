/************************************************************
Trigger pour vérifier les horaires du service de réservation
*************************************************************/

DROP TRIGGER IF EXISTS check_reservation_service_time_trigger ON reservations;
DROP FUNCTION IF EXISTS check_reservation_service_time();

CREATE OR REPLACE FUNCTION check_reservation_service_time()
    RETURNS trigger AS
$$
BEGIN
    IF NEW.status IN ('confirmed', 'completed','pending') AND NOT EXISTS (
        SELECT 1
        FROM services s
        WHERE s.restaurant = NEW.restaurant
          AND s.day_of_week = EXTRACT(isodow FROM NEW.datetime::timestamp)::int
          AND (
            ( s.start_time < s.end_time AND NEW.datetime::time >= s.start_time AND NEW.datetime::time < s.end_time )
                OR

            ( s.start_time > s.end_time  AND ( NEW.datetime::time >= s.start_time   OR NEW.datetime::time < s.end_time ) )
            )
    )
    THEN
        RAISE EXCEPTION 'Reservation time must be within a service period for that restaurant.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER check_reservation_service_time_trigger
    BEFORE INSERT OR UPDATE
    ON reservations
    FOR EACH ROW
EXECUTE FUNCTION check_reservation_service_time();

/**
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 1, '2024-12-07 12:00:00', 2, 'pending');
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (4, 1, '2024-12-06 19:00:00', 2, 'pending');
update reservations set datetime = '2024-12-09 19:00:00' where id = 14;
update reservations set datetime = '2024-12-07 10:00:00' where id = 14;
update reservations set status = 'cancelled', datetime = '2024-12-07 10:00:00' where id = 20;

select * from reservations; **/