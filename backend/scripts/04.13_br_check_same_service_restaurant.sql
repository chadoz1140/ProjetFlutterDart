DROP TRIGGER IF EXISTS valid_client_reservation_conflict_trigger ON reservations;
DROP FUNCTION IF EXISTS valid_client_reservation_conflict();

CREATE OR REPLACE FUNCTION valid_client_reservation_conflict()
    RETURNS TRIGGER AS $$
    DECLARE
    r_conflict INT;
    BEGIN
        SELECT COUNT(*) INTO r_conflict
        FROM reservations r
            JOIN services s1 ON s1.restaurant = NEW.restaurant
            AND s1.start_time <= NEW.datetime::time
            AND s1.end_time   >  NEW.datetime::time
                 JOIN services s2 ON s2.restaurant = r.restaurant
            AND s2.start_time <= r.datetime::time
            AND s2.end_time   >  r.datetime::time
        WHERE r.client     = NEW.client
          AND r.id        <> NEW.id
          AND r.status    IN ('pending', 'confirmed', 'completed')
          AND NEW.status  IN ('pending', 'confirmed', 'completed')
          AND DATE(r.datetime) = DATE(NEW.datetime)
          AND s1.id        = s2.id;

        IF r_conflict > 0 THEN
            RAISE EXCEPTION
                'Le client % a déjà une réservation pour cette date et ce service.', NEW.client;
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE  TRIGGER valid_client_reservation_conflict_trigger
BEFORE INSERT OR UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION valid_client_reservation_conflict();

/**
insert into services (restaurant, day_of_week, start_time, end_time) values (2,6, '10:00:00', '14:00:00')
select * from services where restaurant=2;
-- TEST TRIGGER
SELECT client,restaurant,datetime,status
FROM reservations;
-- FAILED
INSERT INTO reservations (client, restaurant, datetime, number_of_guests)
VALUES (4, 2, '2024-11-16 21:00:00', 4);
-- SUCCESS
INSERT INTO reservations (client, restaurant, datetime, number_of_guests)
VALUES (4, 2, '2024-11-16 12:30:00', 4); **/