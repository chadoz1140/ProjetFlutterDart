DROP TRIGGER IF EXISTS verify_user_reservation_trigger ON reservations;
DROP FUNCTION IF EXISTS verify_user_reservation_not_past();

CREATE OR REPLACE FUNCTION verify_user_reservation_not_past()
    RETURNS TRIGGER AS $$
    DECLARE
        simulate_time TIMESTAMP;
    BEGIN
        SELECT COALESCE(simulated_time, NOW()) INTO simulate_time FROM system_time LIMIT 1;

        IF simulate_time IS NULL
        THEN
            simulate_time := NOW();
        END IF;

        IF NEW.datetime <= simulate_time
        THEN
            RAISE EXCEPTION 'Une réservation ne peut pas être créée dans le passé.';
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER verify_user_reservation_trigger
BEFORE INSERT ON reservations
FOR EACH ROW
EXECUTE FUNCTION verify_user_reservation_not_past();


/**

SELECT id , datetime FROM reservations;
SELECT * FROM system_time;
UPDATE system_time set simulated_time = '2026-05-09 23:00:00';
INSERT INTO system_time VALUES('2026-05-10 00:01:00');
DELETE FROM system_time;
-- FAILED
INSERT INTO reservations (client, restaurant, datetime, number_of_guests)
VALUES (7, 1, '2023-05-10 19:00:00', 4);
-- SUCCESS
INSERT INTO reservations (client, restaurant, datetime, number_of_guests)
VALUES (7, 1, '2026-05-10 12:00:00', 4);**/