/************************************************
Trigger de transition de statut de réservation
************************************************/

DROP TRIGGER IF EXISTS reservation_status_transition_trigger ON reservations;
DROP FUNCTION IF EXISTS reservation_status_transition();

CREATE OR REPLACE FUNCTION reservation_status_transition()
    RETURNS TRIGGER AS $$
    DECLARE
        simulate_time TIMESTAMP;
    BEGIN
        -- INSERT NEW RESERVATION
        IF TG_OP = 'INSERT'
        THEN
            IF NEW.status <> 'pending' THEN
                RAISE EXCEPTION 'Une nouvelle réservation doit avoir le status pending.';
            END IF;
            RETURN NEW;
        END IF;

        --  STATUS NOT CHANGED
        IF OLD.status = NEW.status
        THEN
            RETURN NEW;
        END IF;

        --  UPDATE STATUS
        IF OLD.status = 'completed' OR OLD.status = 'cancelled'
        THEN
            RAISE EXCEPTION 'Aucune transition depuis % n''est autorisée.', OLD.status;
        END IF;

        IF OLD.status = 'pending' AND NEW.status NOT IN ('confirmed', 'cancelled')
        THEN
            RAISE EXCEPTION 'Transition % -> % non autorisée.', OLD.status, NEW.status;
        END IF;

        IF OLD.status = 'confirmed' AND NEW.status = 'pending'
        THEN
            SELECT COALESCE(simulated_time, NOW()) INTO simulate_time FROM system_time LIMIT 1;

            IF simulate_time IS NULL
            THEN
                simulate_time := NOW();
            END IF;

            IF NEW.datetime <= simulate_time
            THEN
                RAISE EXCEPTION
                    'Transition confirmed -> pending non autorisée : la réservation n''est pas dans le futur.';
            END IF;

        END IF;

        IF OLD.status = 'confirmed' AND NEW.status NOT IN ('completed', 'cancelled','pending')
        THEN
            RAISE EXCEPTION 'Transition % -> % non autorisée.', OLD.status, NEW.status;
        END IF;


        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER reservation_status_transition_trigger
BEFORE INSERT OR UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION reservation_status_transition();



/**
SELECT id,status,datetime FROM reservations;
INSERT INTO system_time (simulated_time) VALUES ('2026-05-07 10:00:00');
SELECT * FROM system_time;
-- FAILED
INSERT INTO reservations (client, restaurant, datetime, number_of_guests, status, special_requests)
VALUES (1, 1, '2026-05-08 21:00:00', 4, 'cancelled', 'Window table');

UPDATE reservations SET status = 'completed' WHERE id = 2;

UPDATE reservations SET status = 'pending' WHERE id = 1;

-- SUCCESS
UPDATE reservations SET status = 'confirmed' WHERE id = 5;**/