/***************************************************************************
Trigger qui empêche la modification d'une réservation terminée ou annulée
****************************************************************************/

DROP TRIGGER IF EXISTS reservation_editable_trigger_validation ON reservations;
DROP FUNCTION IF EXISTS reservation_editable_validation();

CREATE OR REPLACE FUNCTION reservation_editable_validation()
    RETURNS TRIGGER AS $$
    BEGIN
        IF OLD.status IN ('completed', 'cancelled')
        THEN
            RAISE EXCEPTION 'Une réservation % ne peut pas être modifiée.', OLD.status;
        END IF;

        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE TRIGGER reservation_editable_trigger_validation
BEFORE UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION reservation_editable_validation();


/**

SELECT id , status,special_requests FROM reservations;
-- FAILED
UPDATE reservations SET special_requests = 'special table' WHERE  id = 8; -- CANCELED
UPDATE reservations SET special_requests = 'special table' WHERE  id = 12; -- COMPLETED
-- SUCCESS
UPDATE reservations SET special_requests = 'special table' WHERE  id = 7; -- CONFIRMED**/