
/* if insert or update verify if new time overlap with other time in DB */
DROP TRIGGER IF EXISTS service_conflict_on_same_day_trigger ON services;

DROP FUNCTION IF EXISTS check_service_conflict_on_same_day;

CREATE OR REPLACE FUNCTION check_service_conflict_on_same_day()
    RETURNS TRIGGER AS $$
    DECLARE
        conflict INT;
    BEGIN
        SELECT COUNT(*) INTO conflict
        FROM services
        WHERE restaurant   = NEW.restaurant
          AND day_of_week  = NEW.day_of_week
          AND  id <> NEW.id
          AND start_time   < NEW.end_time
          AND end_time     > NEW.start_time;

        IF conflict > 0 THEN
            RAISE EXCEPTION
                'Les services du restaurant % se chevauchent pour le jour %.',
                NEW.restaurant, NEW.day_of_week;
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER service_conflict_on_same_day_trigger
BEFORE INSERT OR UPDATE ON services
FOR EACH ROW
EXECUTE FUNCTION check_service_conflict_on_same_day();

/**

SELECT * FROM services WHERE restaurant = 1;
-- FAILED
INSERT INTO services(restaurant,day_of_week,start_time,end_time) VALUES(1,1,'18:00','21:00');
UPDATE services SET  end_time = '22:30' WHERE id = 1;
-- SUCCESS
INSERT INTO services(restaurant,day_of_week,start_time,end_time) VALUES(1,1,'22:00','23:00'); **/

