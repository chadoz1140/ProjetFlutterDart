/***************************************************************************
Trigger pour vérifier la capacité des tables par rapport nombres de convives
****************************************************************************/

-- CHECK TABLES CAPACITY WHEN TABLE REMOVE

DROP TRIGGER IF EXISTS check_reservation_tables_capacity_trigger ON reservation_tables;

DROP FUNCTION IF EXISTS check_reservation_tables_capacity();

CREATE OR REPLACE FUNCTION check_reservation_tables_capacity()
    RETURNS trigger AS
    $$
    DECLARE
        nb_guest_old_reservation INT;
        status_old_reservation TEXT;
    BEGIN
        SELECT number_of_guests, "status"
        INTO nb_guest_old_reservation, status_old_reservation
        FROM reservations
        WHERE id = OLD.reservation;

        IF status_old_reservation IN ('confirmed', 'completed')
        THEN
            IF EXISTS (SELECT 1 FROM reservation_tables rt
                                         JOIN tables t ON rt."table" = t.id
                       WHERE rt.reservation = OLD.reservation
                       HAVING SUM(t.capacity) < nb_guest_old_reservation  OR SUM(t.capacity) is null
            )
            THEN
                RAISE EXCEPTION 'The capacity of the assigned tables for this reservation is insufficient, or no tables have been assigned yet.';
            END IF;

        END IF;
        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER check_reservation_tables_capacity_trigger
AFTER DELETE OR UPDATE ON reservation_tables
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_reservation_tables_capacity();

--trigger pour la table des reservations
--si on crée une réservation ou on modifie le status avec un status valide ça peut casser la régle

DROP TRIGGER IF EXISTS check_reservation_guest_and_status_trigger ON reservations;

DROP FUNCTION IF EXISTS check_reservation_guest_and_status();

CREATE OR REPLACE FUNCTION check_reservation_guest_and_status()
    RETURNS trigger AS
    $$
    BEGIN
        IF NEW.status IN ('confirmed', 'completed') AND EXISTS(
            SELECT 1
            FROM reservation_tables rt
                     JOIN tables t ON t.id = rt."table"
            WHERE rt.reservation = NEW.id
            HAVING SUM(t.capacity) <  NEW.number_of_guests OR SUM(t.capacity) IS NULL
        )
        THEN
            RAISE EXCEPTION  'The capacity of the assigned tables for this reservation is insufficient, or no tables have been assigned yet.';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_reservation_guest_and_status_trigger
BEFORE INSERT OR UPDATE
ON reservations
FOR EACH ROW
EXECUTE FUNCTION check_reservation_guest_and_status();

--trigger pour la table des tables
--si on change la capacité d'une table ou on suprrime une table ça casse une reservation

-- CHECK TABLES CAPACITY WHEN TABLE UPDATE
DROP TRIGGER IF EXISTS check_capacity_tables_trigger ON tables;
DROP FUNCTION IF EXISTS check_capacity_tables();

CREATE OR REPLACE FUNCTION check_capacity_tables()
    RETURNS trigger AS
    $$
    BEGIN
        IF EXISTS(
            SELECT 1 FROM reservations r
            JOIN reservation_tables rt ON r.id = rt.reservation
            JOIN tables t ON t.id = rt."table"
            WHERE r.status IN ('confirmed', 'completed')
              AND r.id IN ( SELECT rt2.reservation FROM reservation_tables rt2 WHERE OLD.id = rt2."table")
            GROUP BY r.id, r.number_of_guests
            HAVING SUM(t.capacity) < r.number_of_guests
        )
        THEN
            RAISE EXCEPTION 'Insufficient table capacity for this reservation.';
        END IF;
        RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER check_capacity_tables_trigger
AFTER UPDATE
ON tables
FOR EACH ROW
EXECUTE FUNCTION check_capacity_tables();

/**
update reservations set status = 'confirmed' where id = 2;
update reservations set number_of_guests = 5 where id = 20;
delete from reservation_tables where reservation = 7 and "table" = 3;
update tables set capacity = 1 where id = 1;
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values ( 6 , 1, '2024-12-06 19:00:00', 4, 'pending');
update reservations set number_of_guests = 4 where id = 11;
*/