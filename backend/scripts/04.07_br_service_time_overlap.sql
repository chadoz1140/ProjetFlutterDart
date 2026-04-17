
/* if insert or update verify if new time overlap with other time in DB */
CREATE OR REPLACE FUNCTION verify_if_time_overlap()
    returns trigger as
    $$
        begin
            if exists(select *
                      from services as s
                      where s.day_of_week = new.day_of_week and s.restaurant = new.restaurant
                          and s.start_time < new.end_time and new.start_time < s.end_time)
            then
                raise exception 'time overlap with other service';
            end if;
            return new;
        end;
    $$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_service_time_overlap
    BEFORE INSERT OR UPDATE
    ON services
    FOR EACH ROW
EXECUTE FUNCTION verify_if_time_overlap();