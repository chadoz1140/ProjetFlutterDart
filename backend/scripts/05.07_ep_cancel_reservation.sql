/*Annule une réservation*/

drop function if exists cancel_reservation(reservation_id int);

create or replace function cancel_reservation(reservation_id int)
    returns reservation_details as
$$
declare
    updated_reservation reservations;
begin
    if not exists (
        select 1
        from reservations r
        where r.id = cancel_reservation.reservation_id
          and r.client = auth.id()
          and r.status in ('pending', 'confirmed')
    ) then
        raise exception 'Reservation not found or not cancellable';
    end if;

    delete from reservation_tables rt
    where rt.reservation = cancel_reservation.reservation_id;

    update reservations r
    set status = 'cancelled'
    where r.id = cancel_reservation.reservation_id
      and r.client = auth.id()
    returning * into updated_reservation;

    return get_reservation_details(updated_reservation.id);
end;
$$ language plpgsql security definer;

revoke execute on function public.cancel_reservation(int) from anon;
grant execute on function public.cancel_reservation(int) to authenticated;
