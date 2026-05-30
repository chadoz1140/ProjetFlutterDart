CREATE OR REPLACE FUNCTION new_reservation_tables_statut()
    RETURNS TRIGGER AS
    $$
        begin
            if exists(select *
                      from reservation_tables as rt
                        join reservations as r on r.id = rt.reservation
                      where (r.status in ('pending', 'cancelled')))
            then
                raise exception 'new reservation can''t be pending or cancelled';
            end if;
            return new;
        end;
    $$language plpgsql security definer;

CREATE CONSTRAINT TRIGGER trigger_new_reservation_tables_statut
    AFTER INSERT
    ON reservation_tables
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE FUNCTION new_reservation_tables_statut();

CREATE OR REPLACE FUNCTION update_statut_reservation() RETURNS TRIGGER AS

    $$
        begin
            if (new.status = 'pending' or new.status = 'cancelled') then
                if exists(select *
                          from reservation_tables as rt
                          where rt.reservation = new.id)
                then
                    raise exception 'the reservation is still linked to a table';
                end if;
            end if;
            return new;
        end;
    $$language plpgsql security definer;

CREATE CONSTRAINT TRIGGER trigger_update_reservation_statut
    AFTER UPDATE OF status
    ON reservations
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE FUNCTION update_statut_reservation();
