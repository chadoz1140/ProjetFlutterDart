CREATE OR REPLACE FUNCTION update_statut_reservation()
    RETURNS TRIGGER AS
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
    $$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_statut
    BEFORE UPDATE OF status
    ON reservations
    FOR EACH ROW
EXECUTE FUNCTION update_statut_reservation();

CREATE OR REPLACE FUNCTION new_reservation_tables_statut()
    RETURNS TRIGGER AS
    $$
        begin
            if exists(select *
                      from reservations as r
                      where (r.id = new.reservation and r.status in ('pending', 'cancelled')))
            then
                raise exception 'new reservation can''t be pending or cancelled';
            end if;
            return new;
        end;
    $$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_new_reservation_tables_statut
    BEFORE INSERT
    ON reservation_tables
    FOR EACH ROW
EXECUTE FUNCTION new_reservation_tables_statut();

CREATE OR REPLACE FUNCTION change_statut_delete_reservation_tables()
    RETURNS TRIGGER AS
    $$
        begin
            if not exists(select *
                          from reservation_tables as rt
                          where rt.reservation = old.reservation)
            then
                UPDATE reservations
                SET status = 'cancelled'
                WHERE id = old.reservation;
            end if;
            return old;
        end;
    $$language plpgsql;

CREATE OR REPLACE TRIGGER trigger_delete_reservation_tables
    AFTER DELETE
    on reservation_tables
    FOR EACH ROW
EXECUTE FUNCTION change_statut_delete_reservation_tables();