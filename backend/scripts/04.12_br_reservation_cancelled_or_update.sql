DROP TRIGGER IF EXISTS valid_reservation_table_status_trigger ON reservation_tables;
DROP FUNCTION IF EXISTS valid_reservation_table_status();

CREATE OR REPLACE FUNCTION valid_reservation_table_status()
    RETURNS TRIGGER AS $$
    DECLARE
        r_status TEXT;
    BEGIN
        SELECT status INTO r_status
        FROM reservations
        WHERE id = NEW.reservation;

        IF r_status IN ('pending', 'cancelled') THEN
            RAISE EXCEPTION 'Une réservation % ne peut pas être associée à une table.', r_status;
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER valid_reservation_table_status_trigger
BEFORE INSERT ON reservation_tables
FOR EACH ROW
EXECUTE FUNCTION valid_reservation_table_status();


/**
SELECT R.id AS reservationId , R.status ,restaurant,RT.table
FROM reservation_tables AS RT
         JOIN reservations AS R
              ON R.id = RT.reservation;
-- FAILED
INSERT INTO reservation_tables VALUES(14,8);
-- SUCCESS
INSERT INTO reservation_tables VALUES(13,2);**/