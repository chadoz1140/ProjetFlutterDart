
DROP TRIGGER IF EXISTS check_tables_same_restaurant_trigger on reservation_tables;

DROP FUNCTION IF EXISTS check_tables_same_restaurant();

CREATE OR REPLACE FUNCTION check_tables_same_restaurant()
    RETURNS trigger AS
    $$
    DECLARE
        reservation_restaurant_id int;
        table_restaurant_id int;
    BEGIN
        IF tg_op NOT IN ('INSERT', 'UPDATE')
        THEN
            RAISE EXCEPTION 'should not be triggered for %', tg_op;
        END IF;

        SELECT restaurant INTO reservation_restaurant_id FROM reservations WHERE id = NEW.reservation ;
        SELECT restaurant  INTO table_restaurant_id FROM tables WHERE id = NEW."table";
        IF(reservation_restaurant_id <> table_restaurant_id)
        THEN
            RAISE EXCEPTION 'The table associated does not belong to the restaurant of the reservation!';
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER check_tables_same_restaurant_trigger
BEFORE INSERT OR UPDATE
ON reservation_tables
FOR EACH ROW
EXECUTE FUNCTION check_tables_same_restaurant();

--insert into reservation_tables (reservation, "table") values (12, 1);
--insert into reservation_tables (reservation, "table") values (1, 2);
--update reservation_tables set "table" = 6 where reservation = 1 and "table" = 1;
--update reservation_tables set "table" = 7 where reservation = 9 and "table" = 6;