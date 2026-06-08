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
            ( s.start_time < s.end_time AND NEW.datetime::time >= s.start_time AND NEW.datetime::time <= s.end_time )
                OR

            ( s.start_time > s.end_time  AND ( NEW.datetime::time >= s.start_time   OR NEW.datetime::time <= s.end_time ) )
            )
    )
    THEN
        RAISE EXCEPTION 'Reservation time must be within a service period for that restaurant.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/***************************************************************************
 Refuse la modification ou la suppression d'un service si cette opération
 laisse une réservation active sans aucun service valide.
****************************************************************************/

DROP TRIGGER IF EXISTS check_reservations_after_service_change_trigger ON services;
DROP FUNCTION IF EXISTS check_reservations_after_service_change();

CREATE OR REPLACE FUNCTION check_reservations_after_service_change()
    RETURNS trigger AS
$$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM reservations r
        WHERE r.restaurant = OLD.restaurant
          AND r.status IN ('pending', 'confirmed', 'completed')
          AND NOT EXISTS (
            SELECT 1
            FROM services s
            WHERE s.restaurant = r.restaurant
              AND s.day_of_week = EXTRACT(isodow FROM r.datetime)::int
              AND (
                (
                    s.start_time < s.end_time
                        AND r.datetime::time >= s.start_time
                        AND r.datetime::time <= s.end_time
                    )
                    OR
                (
                    s.start_time > s.end_time
                        AND (
                        r.datetime::time >= s.start_time
                            OR r.datetime::time <= s.end_time
                        )
                    )
                )
        )
    )
    THEN
        RAISE EXCEPTION
            'Service change would invalidate an existing reservation.';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER ;


CREATE TRIGGER check_reservation_service_time_trigger
    BEFORE INSERT OR UPDATE
    ON reservations
    FOR EACH ROW
EXECUTE FUNCTION check_reservation_service_time();




CREATE CONSTRAINT TRIGGER check_reservations_after_service_change_trigger
    AFTER UPDATE OR DELETE
    ON services
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE FUNCTION check_reservations_after_service_change();