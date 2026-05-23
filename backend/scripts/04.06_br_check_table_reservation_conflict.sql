/*********************************************************
Trigger pour vérifier les conflits de réservation de table
*********************************************************/

DROP TRIGGER IF EXISTS check_table_reservation_conflict_trigger ON reservation_tables;
DROP FUNCTION IF EXISTS check_table_reservation_conflict();

CREATE OR REPLACE FUNCTION check_table_reservation_conflict()
    RETURNS TRIGGER AS $$
    DECLARE
        r_datetime   TIMESTAMP;
        r_restaurant INT;
        r_conflict   INT;
    BEGIN

        SELECT datetime, restaurant INTO r_datetime, r_restaurant FROM reservations WHERE id = NEW.reservation;
        -- Récupérer les réservations du même restaurant, du même créneau et de la même table.
        SELECT COUNT(*) INTO r_conflict
        FROM reservation_tables rt
                 INNER JOIN reservations r ON rt.reservation = r.id
                 INNER JOIN services s  ON s.restaurant = r.restaurant
        WHERE rt.table = NEW.table
          AND r.id != NEW.reservation
          AND r.status IN ('confirmed', 'completed')
          AND r.restaurant = r_restaurant
          AND r.datetime::DATE = r_datetime::DATE
          AND s.day_of_week = EXTRACT(ISODOW FROM r_datetime::TIMESTAMP)::INT
          AND (
            ( s.start_time < s.end_time
                AND (r_datetime::TIME >= s.start_time  AND r_datetime::TIME < s.end_time)
                AND (r.datetime::TIME >= s.start_time AND r.datetime::TIME < s.end_time)
                )

                OR

            ( s.start_time > s.end_time
                AND ( r_datetime::TIME >= s.start_time OR r_datetime::TIME < s.end_time)
                AND ( r.datetime::TIME >= s.start_time OR r.datetime::TIME < s.end_time )
                )
            );

        IF r_conflict > 0 THEN
            RAISE EXCEPTION
                'La table % est déjà réservée (confirmed/completed) pour cette date et ce service.',
                NEW.table;
        END IF;

        RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE TRIGGER check_table_reservation_conflict_trigger
    BEFORE INSERT OR UPDATE ON reservation_tables
    FOR EACH ROW
EXECUTE FUNCTION check_table_reservation_conflict();


/**
SELECT R.id AS reservationId ,R.datetime ,  R.restaurant , R.status
FROM reservations as R;

SELECT R.id AS reservationId ,R.datetime ,  R.restaurant , R.status , RT.table, R.client
FROM reservation_tables AS RT
         JOIN reservations AS R
              ON R.id = RT.reservation;

INSERT INTO reservations (client, restaurant, datetime, number_of_guests, status, special_requests)
VALUES (3, 1, '2024-11-15 19:00:00', 4, 'pending', 'Window table');

-- FAILED
INSERT INTO reservation_tables(reservation,"table") VALUES(46,1);

-- SUCCESS
INSERT INTO reservation_tables(reservation,"table") VALUES(46,3);**/