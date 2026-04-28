create or replace function check_slot_duration_service() returns
trigger as
$$
    begin
       if exists(
         select *
         from restaurants r
         where r.id = new.restaurant and
                  ((extract(minutes from new.start_time) % r.slot_duration != 0) or
               (extract(minutes from new.end_time) % r.slot_duration != 0))
       ) then
           raise exception 'impossible';
       end if;
       return new;
    end;

$$language plpgsql;

create or replace function check_slot_duration_restaurant() returns
    trigger as
$$
    begin
        if exists(
            select *
            from services s
            where s.restaurant = new.id and ((extract(minutes from s.start_time) % new.slot_duration != 0) or
                (extract(minutes from s.end_time) % new.slot_duration != 0))
            )
         then
            raise exception 'impossible';
        end if;
        return new;
    end;
$$language plpgsql;



create or replace trigger check_slot_duration_service_trigger
before insert or update
on services
for each row
execute function check_slot_duration_service();

create or replace trigger check_slot_duration_restaurant_trigger
before update
on restaurants
for each row
execute function check_slot_duration_restaurant();

