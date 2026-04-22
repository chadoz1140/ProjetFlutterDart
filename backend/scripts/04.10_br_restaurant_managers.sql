CREATE OR REPLACE FUNCTION verify_last_manager_restaurant()
    RETURNS TRIGGER AS
    $$
        begin
            if ((select count(*)
                from restaurant_managers as rm
                where rm.restaurant = old.restaurant) = 1)
            then
                raise exception 'He was the last manager of the restaurant';
            end if;

            return old;
        end;
    $$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_delete_manager
    BEFORE DELETE
    ON restaurant_managers
    FOR EACH ROW
EXECUTE FUNCTION verify_last_manager_restaurant();



CREATE OR REPLACE FUNCTION verify_last_manager_user()
    RETURNS TRIGGER AS
$$
begin
    if exists(select *
              from restaurant_managers as rm
              where rm.manager = old.id)
    then
        raise exception 'this user is manager of some restaurant';
    end if;

    return old;
end;
$$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_role_user
    BEFORE DELETE OR UPDATE OF role
    ON users
    FOR EACH ROW
EXECUTE FUNCTION verify_last_manager_user();