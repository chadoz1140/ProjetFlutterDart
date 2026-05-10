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
        SELECT "datetime", restaurant INTO r_datetime, r_restaurant FROM reservations WHERE id = NEW.reservation;

        SELECT COUNT(*) INTO r_conflict
        FROM reservation_tables rt
                 JOIN reservations r ON r.id = rt.reservation
                 JOIN services s1 ON s1.restaurant = r_restaurant
                 JOIN services s2 ON s2.restaurant = r.restaurant
        WHERE rt.table = NEW.table
          AND rt.reservation <> NEW.reservation
          AND r.status IN ('confirmed', 'completed')
          AND DATE(r.datetime) = DATE(r_datetime)
          AND s1.id = (
            SELECT id FROM services
            WHERE restaurant = r_restaurant
              AND start_time <= r_datetime::time
              AND end_time   >= r_datetime::time
            LIMIT 1
        )
          AND s2.id = s1.id;

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