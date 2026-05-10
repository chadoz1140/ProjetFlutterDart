/* if new insert in reservation table check user role */

CREATE OR REPLACE FUNCTION verify_user_role_new_reservation()
    RETURNS trigger AS
    $$
        BEGIN
            IF EXISTS(SELECT * FROM users AS u  WHERE u.id = NEW.client AND u.role = 'manager')
            THEN
                RAISE EXCEPTION 'user(s) need to be client to make a reservation';
            END IF;
            return NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_verify_user_reservation
BEFORE INSERT ON reservations
FOR EACH ROW
EXECUTE FUNCTION verify_user_role_new_reservation();



/* if update and user has a reservation, their role only be client */
DROP TRIGGER IF EXISTS trigger_verify_update_user_role ON users;
DROP FUNCTION IF EXISTS verify_update_user_role();

CREATE OR REPLACE FUNCTION verify_update_user_role()
    RETURNS trigger AS
    $$
        BEGIN
            IF EXISTS(SELECT *  from reservations AS r WHERE r.client = NEW.id)
            THEN
                IF (NEW.role = 'manager')
                THEN
                    RAISE EXCEPTION 'client already have reservation(s) can''t be manager';
                END IF;
            END IF;
            RETURN NEW;
        END;
    $$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_verify_update_user_role
BEFORE UPDATE
ON users
FOR EACH ROW
EXECUTE FUNCTION verify_update_user_role();

/**
select * from users;
select * from reservations where client=3;
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (2, 1, '2024-12-05 19:00:00', 2, 'pending');
update users set role = 'manager' where id = 7;
update users set role = 'manager' where id = 3;
update users set phone = '+32499000000' where id = 2;
insert into reservations (client, restaurant, datetime, number_of_guests, status)
values (3, 1, '2024-12-06 19:00:00', 2, 'pending'); **/




