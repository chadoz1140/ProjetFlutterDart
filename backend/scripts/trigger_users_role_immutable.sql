/**************************************************************
Trigger qui empêche la modification du rôle d'un utilisateur
**************************************************************/
create or replace function users_role_immutable()
    returns trigger as
$$
begin
    if new.role is distinct from old.role then
        raise exception 'User role cannot be changed';
    end if;
    return new;
end;
$$ language plpgsql;

drop trigger if exists users_role_immutable_trigger on users;

create trigger users_role_immutable_trigger
before update of role
on users
for each row
execute function users_role_immutable();


