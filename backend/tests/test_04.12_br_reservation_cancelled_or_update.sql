begin;
do
$test$
    begin
        raise notice 'test insert reservation';
        INSERT INTO reservation_tables (reservation, "table") VALUES (2, 4);
    end
$test$;
rollback;