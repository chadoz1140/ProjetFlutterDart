drop function if exists is_reservation_in_future(res_time timestamp);
create or replace function is_reservation_in_future(res_time timestamp)
    returns boolean as
$$
begin
    return res_time >= (
        select case
                   when simulated_time is not null then simulated_time
                   else now()
                   end
        from system_time
    );
end;
$$ language plpgsql;

drop function if exists check_reservation_time_rules();
create or replace function check_reservation_time_rules()
returns trigger as
$$
    begin
        if tg_op = 'INSERT' then
            if not is_reservation_in_future(new.datetime)
            then
                raise exception 'Reservation cannot be in the past';
            end if;
        elsif tg_op = 'UPDATE' then
            if old.status = 'confirmed' and new.status = 'pending' then
                if not is_reservation_in_future(new.datetime)
                then
                    raise exception 'Cannot revert to pending if reservation is in the past';
                end if;
            end if;
        end if;
    return new;
    end;
$$language plpgsql;

create or replace trigger  check_reservation_time_rules_trigger
before INSERT or UPDATE
on reservations
for each row
execute function check_reservation_time_rules();
