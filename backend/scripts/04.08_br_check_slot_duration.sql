DROP TRIGGER IF EXISTS valid_service_slot_alignment_trigger ON services;

DROP FUNCTION IF EXISTS valid_service_slot_alignment();

CREATE OR REPLACE FUNCTION valid_service_slot_alignment()
    RETURNS TRIGGER AS $$
    DECLARE
        r_slot_duration INT;
    BEGIN
        SELECT slot_duration INTO r_slot_duration
        FROM restaurants
        WHERE id = NEW.restaurant;
        --  CONVERT TIME TO SECOND
        IF EXTRACT(EPOCH FROM NEW.start_time)::INT % (r_slot_duration * 60) <> 0
        THEN
            RAISE EXCEPTION
                'Start time % n''est pas aligné sur le créneau de % minutes.',
                NEW.start_time, r_slot_duration;
        END IF;

        IF EXTRACT(EPOCH FROM NEW.end_time)::INT % (r_slot_duration * 60) <> 0
        THEN
            RAISE EXCEPTION
                'End time % n''est pas aligné sur le créneau de % minutes.',
                NEW.end_time, r_slot_duration;
        END IF;

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER valid_service_slot_alignment_trigger
BEFORE INSERT OR UPDATE ON services
FOR EACH ROW
EXECUTE FUNCTION valid_service_slot_alignment();

/**
SELECT S.* , R.slot_duration FROM services as S
                                      JOIN restaurants AS R
                                           ON R.id = S.restaurant
WHERE restaurant = 1 ORDER BY S.day_of_week ;

-- FAILED
INSERT INTO services(restaurant,day_of_week,start_time,end_time) VALUES(1,2,'22:00','23:40');
UPDATE services SET  start_time = '17:10' WHERE id = 1;
-- SUCCESS
INSERT INTO services(restaurant,day_of_week,start_time,end_time) VALUES(1,2,'22:00','23:30');
UPDATE services SET  end_time = '14:30' WHERE id = 1; **/