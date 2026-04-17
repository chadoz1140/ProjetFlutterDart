/* if new insert in reservation table check user role */

CREATE OR REPLACE FUNCTION verify_user_role_new_reservation()
    returns trigger as
    $$
        begin
            if exists(select *
                      from users as u
                      where u.id = new.client and u.role = 'manager')
            then
                raise exception 'new user(s) need to be client';
            end if;
            return new;
        end;
    $$ language plpgsql;

CREATE OR REPLACE TRIGGER trigger_verify_user_reservation
    BEFORE INSERT
    ON reservations
    FOR EACH ROW
EXECUTE FUNCTION verify_user_role_new_reservation();


/* if update and user has a reservation, their role only be client */

CREATE OR REPLACE FUNCTION verify_update_user_role()
    returns trigger as
    $$
        begin
            if exists(select *
                      from reservations as r
                      where r.client = new.id)
            then
                if (new.role = 'manager') then
                    raise exception 'client with reservation(s) can''t be manager';
                end if;
            end if;
        end;
    $$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_verify_update_user_role
    BEFORE UPDATE
    ON users
    FOR EACH ROW
EXECUTE FUNCTION verify_update_user_role();