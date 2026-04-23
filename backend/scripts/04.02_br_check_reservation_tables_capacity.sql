/***************************************************************************
Trigger pour vérifier le capacité des tables par rapport nombres de convives
****************************************************************************/

--trigger pour la table des reservation_tables

drop function if exists check_reservation_tables_capacity();
create or replace function check_reservation_tables_capacity()
    returns trigger as
$$
declare
    nb_guest_old_reservation int;
    status_old_reservation text;
begin
    select number_of_guests, status
    into nb_guest_old_reservation, status_old_reservation
    from reservations
    where id = old.reservation;

    if status_old_reservation in ('confirmed', 'completed') then
        if exists (
            select 1
            from reservation_tables rt
                     join tables t on rt."table" = t.id
            where rt.reservation = old.reservation
            having sum(t.capacity) < nb_guest_old_reservation
                or sum(t.capacity) is null
        ) then
            raise exception 'The capacity of the tables for this reservation is insufficient.';
        end if;

    end if;

    return null;
end;
$$ language plpgsql;

drop trigger if exists check_reservation_tables_capacity_trigger on reservation_tables;
create constraint trigger check_reservation_tables_capacity_trigger
    after delete on reservation_tables
    deferrable initially deferred
    for each row
execute function check_reservation_tables_capacity();

--trigger pour la table des reservations
--si on crée une réservation ou on modifie le status avec un status valide ça peut casser la régle

drop function if exists check_reservation_guest_and_status();
create or replace function check_reservation_guest_and_status()
returns trigger as
$$
    begin
        if new.status in ('confirmed', 'completed') and exists(
            select 1
            from reservation_tables rt
            join tables t on t.id = rt."table"
            where rt.reservation = new.id
            having sum(t.capacity) <  new.number_of_guests or sum(t.capacity) is null
        ) then
            raise exception 'The capacity of the tables for this reservation is insufficient.';
        end if;
        return new;
    end;
$$language plpgsql;

drop trigger if exists check_reservation_guest_and_status_trigger on reservations;
create or replace trigger check_reservation_guest_and_status_trigger
before INSERT OR UPDATE
on reservations
for each row
execute function check_reservation_guest_and_status();


--trigger pour la table des tables
--si on change la capacité d'une table ou on suprrime une table ça casse une reservation

drop function if exists check_capacity_tables();
create or replace function check_capacity_tables()
returns trigger as
$$
    begin
        if exists(
            select 1
            from reservations r
            join reservation_tables rt on r.id = rt.reservation
            join tables t on t.id = rt."table"
            where r.status in ('confirmed', 'completed')
            and r.id in (             --les reservations qui utilisent les tables modifiés
                select rt2.reservation
                from reservation_tables rt2
                where old.id = rt2."table"
            )
            group by r.id, r.number_of_guests  --pour chaque reservation
            having sum(t.capacity) < r.number_of_guests --On vérifie si la somme des capacités de toutes les tables associées à la réservation est insuffisante
        ) then
            raise exception 'Insufficient table capacity for this reservation.';
        end if;
        return null;
--         if tg_op in ('UPDATE') then
--             return new;
--         elsif tg_op in ('DELETE') then
--             return old;
--         end if;
    end;
$$language plpgsql;

drop trigger if exists check_capacity_tables_trigger on tables;
create or replace trigger check_capacity_tables_trigger
after UPDATE
on tables
for each row
execute function check_capacity_tables();


/**************************************************************
***********    Tests ******
**************************************************************/
--la table des tables : la reservation id=7 avec 8 guests, à deux tables associées 2 et 3
-- delete from tables
-- where id = 3;
--
-- UPDATE tables
-- SET capacity = 2
-- WHERE id = 3;
-- --la table des reservations :
-- --le cas d'insert : nouveau reservation avec un status ('confirmed', 'completed') mais les tables == null
-- insert into reservations (client, restaurant, datetime, number_of_guests, status)
-- values (3, 1, '2025-12-10 19:00:00', 10, 'confirmed');
-- --le cas d'un update :
-- UPDATE reservations
-- SET number_of_guests = 10
-- WHERE id = 1;
--
-- UPDATE reservations
-- SET status = 'confirmed'
-- WHERE id = 2;
--
-- --la table des reservation_tables :
-- --le teste passe pas
-- BEGIN;
-- DELETE FROM reservation_tables
-- WHERE reservation = 7;
-- COMMIT;
--
-- -- test passe aprés la transaction, la vérification est valide pas d'erreur
-- BEGIN;
-- DELETE FROM reservation_tables WHERE reservation = 7;
-- UPDATE reservations SET status = 'cancelled' WHERE id = 7;
-- COMMIT;
--
-- BEGIN;
--
-- ROLLBACK;