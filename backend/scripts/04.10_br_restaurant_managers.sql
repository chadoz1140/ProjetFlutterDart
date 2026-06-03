DROP TRIGGER IF EXISTS restaurant_has_manager_trigger ON restaurant_managers;
DROP FUNCTION IF EXISTS restaurant_has_manager();

CREATE OR REPLACE FUNCTION restaurant_has_manager()
    RETURNS TRIGGER AS $$
    DECLARE
        rm_count INT;
    BEGIN
        SELECT COUNT(*) INTO rm_count
        FROM restaurant_managers
        WHERE restaurant = OLD.restaurant;

        IF rm_count = 0
        THEN
            RAISE EXCEPTION 'Le restaurant % doit avoir au moins un manager.', OLD.restaurant;
        END IF;

        RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER restaurant_has_manager_trigger
AFTER DELETE ON restaurant_managers
FOR EACH ROW
EXECUTE FUNCTION restaurant_has_manager();

/**
-- TEST TRIGGER
SELECT U.id as managerId , U.full_name,role, RM.restaurant FROM restaurant_managers AS RM
                                                                    JOIN users AS U
                                                                         ON U.id = RM.manager;

-- FAILED
DELETE FROM restaurant_managers WHERE manager = 1;
-- SUCCESS

INSERT INTO restaurant_managers(restaurant,manager) VALUES(1,8);
DELETE FROM restaurant_managers WHERE manager = 8; **/
