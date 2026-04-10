/************************************************
Trigger de transition de statut de réservation
************************************************/

create or replace function reservation_status_transition()
       returns trigger as
$$
begin
    -- Règle d'insérer une nouvelle réservation
    if tg_op = 'INSERT' then
       if new.status is distinct from 'pending' then
            raise exception 'reservation must start with status pending.';
       end if;
       return new;
    end if;

    -- Aucune modification par rapport aux transitions cancelled et completed
    if old.status in ('cancelled', 'completed') then
       raise exception 'Cannot modify a completed or cancelled reservation.';
    end if;

    -- Aucun changement
    if new.status = old.status then
       return new;
    end if;

    -- pending transition
    if old.status = 'pending' then
       if new.status = 'confirmed' then
                return new;
       end if;

       if new.status = 'cancelled' then
          return new;
       end if;

       raise exception 'Invalid transition pending->%', new.status;
    end if;

    -- confirmed transition
      if old.status ='confirmed' then
         if new.status = 'completed' then
            return new;
         end if;

         if new.status = 'cancelled' then
            return new;
         end if;

         if new.status = 'pending' then
            if new.datetime <= now() then
                raise exception 'Cannot revert confirmed->pending for past reservation.';
            end if;
            return new;
         end if;

         raise exception 'Invalid transition confirmed->%', new.status;
      end if;

      -- fallback
      raise exception 'Invalid transitions.';
end;

$$ language plpgsql;

drop trigger if exists reservation_status_transition_trigger on reservations;


create trigger reservation_status_transition_trigger
before insert or update on reservations
for each row
execute function reservation_status_transition();

