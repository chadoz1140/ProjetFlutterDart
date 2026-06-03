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
    r_status     status_type;
BEGIN

    SELECT datetime, restaurant, status
    INTO r_datetime, r_restaurant, r_status
    FROM reservations
    WHERE id = NEW.reservation;

    IF r_status NOT IN ('confirmed', 'completed') THEN
        RETURN NEW;
    END IF;

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
            AND (r_datetime::TIME >= s.start_time  AND r_datetime::TIME <= s.end_time)
            AND (r.datetime::TIME >= s.start_time AND r.datetime::TIME <= s.end_time)
            )

            OR

        ( s.start_time > s.end_time
            AND ( r_datetime::TIME >= s.start_time OR r_datetime::TIME <= s.end_time)
            AND ( r.datetime::TIME >= s.start_time OR r.datetime::TIME <= s.end_time )
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

/***************************************************************************
 Vérifie les conflits de tables quand une réservation devient confirmed
 ou quand la date/heure d'une réservation active est modifiée.
****************************************************************************/

DROP TRIGGER IF EXISTS check_reservation_conflict_after_update_trigger
    ON reservations;

DROP FUNCTION IF EXISTS check_reservation_conflict_after_update();

CREATE OR REPLACE FUNCTION check_reservation_conflict_after_update()
    RETURNS trigger AS
$$
BEGIN
    -- Une réservation pending ou cancelled n'occupe pas les tables.
    IF NEW.status NOT IN ('confirmed', 'completed') THEN
        RETURN NEW;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM reservation_tables current_rt
                 JOIN reservation_tables other_rt
                      ON other_rt."table" = current_rt."table"
                          AND other_rt.reservation <> current_rt.reservation
                 JOIN reservations other_r
                      ON other_r.id = other_rt.reservation
                 JOIN services s
                      ON s.restaurant = NEW.restaurant
        WHERE current_rt.reservation = NEW.id
          AND other_r.restaurant = NEW.restaurant
          AND other_r.status IN ('confirmed', 'completed')
          AND other_r.datetime::date = NEW.datetime::date
          AND s.day_of_week = EXTRACT(isodow FROM NEW.datetime)::int
          AND (
            (
                s.start_time < s.end_time
                    AND NEW.datetime::time >= s.start_time
                    AND NEW.datetime::time <= s.end_time
                    AND other_r.datetime::time >= s.start_time
                    AND other_r.datetime::time <= s.end_time
                )
                OR
            (
                s.start_time > s.end_time
                    AND (
                    NEW.datetime::time >= s.start_time
                        OR NEW.datetime::time <= s.end_time
                    )
                    AND (
                    other_r.datetime::time >= s.start_time
                        OR other_r.datetime::time <= s.end_time
                    )
                )
            )
    )
    THEN
        RAISE EXCEPTION
            'Une table est déjà réservée pour cette date et ce service.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE TRIGGER check_table_reservation_conflict_trigger
    BEFORE INSERT OR UPDATE ON reservation_tables
    FOR EACH ROW
EXECUTE FUNCTION check_table_reservation_conflict();


CREATE TRIGGER check_reservation_conflict_after_update_trigger
    BEFORE UPDATE OF status, datetime
    ON reservations
    FOR EACH ROW
EXECUTE FUNCTION check_reservation_conflict_after_update();