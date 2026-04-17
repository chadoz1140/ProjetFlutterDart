/*********************************************************
Trigger pour vérifier les conflits de réservation de table
*********************************************************/

create or replace function check_table_reservation_conflict()
    returns trigger as
$$
begin
    if exists (
        select 1
        from reservation_tables rt
                 join reservations r1 on r1.id = rt.reservation
                 join reservations r2 on r2.id = new.reservation
        where rt.table = new.table
          and r1.id <> r2.id
          and r1.status in ('confirmed','completed')
          and r2.status in ('confirmed','completed')
          and r1.datetime = r2.datetime
    ) then
        raise exception
            'This table already has a confirmed/completed reservation for that date.';
    end if;
    return new;
end;
$$ language plpgsql;

drop trigger if exists check_table_reservation_conflict_trigger on reservation_tables;

create trigger check_table_reservation_conflict_trigger
    before insert or update on reservation_tables
    for each row
    execute function check_table_reservation_conflict();


