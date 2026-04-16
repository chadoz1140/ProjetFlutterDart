CREATE OR REPLACE FUNCTION check_restaurant_is_update()
    returns trigger as
    $$
        begin
            if (old.restaurant != new.restaurant)then
                raise exception 'Le restaurant ne peut etre modifier !';
            end if;
            return new;
        end
    $$language plpgsql;

create or replace trigger trigger_restaurant_unmodifiable_tables
    before update of restaurant
    on tables
    for each row
    execute function check_restaurant_is_update();