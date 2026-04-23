drop function if exists check_tables_same_restaurant();
create or replace function check_tables_same_restaurant()
    returns trigger as
$$
    declare reservation_restaurant_id int;
    declare table_restaurant_id int;
begin
    if tg_op not in ('INSERT', 'UPDATE') then
        raise exception 'should not be triggered for %', tg_op;
    end if;

    select restaurant
    from reservations
    where id = new.reservation
    into reservation_restaurant_id;

    select restaurant
    from tables
    where id = new.table
    into table_restaurant_id;

    if(reservation_restaurant_id <> table_restaurant_id) then
        raise exception 'The table associated does not belong to the restaurant of the reservation!';
    end if;
    return new;
end;
$$language plpgsql;

drop trigger if exists check_tables_same_restaurant_trigger on reservation_tables;

create or replace trigger check_tables_same_restaurant_trigger
before insert or update
on reservation_tables
for each row
execute function check_tables_same_restaurant();

/**************************************************************
***********    Tests ******
**************************************************************/
--test non valide
insert into reservation_tables(reservation, "table")  values (2, 1);
--test valide
insert into reservation_tables(reservation, "table")
values (2, 4);

SELECT *
FROM reservation_tables
WHERE reservation = 2 AND "table" = 4;

