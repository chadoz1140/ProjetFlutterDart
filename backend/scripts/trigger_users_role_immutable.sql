/**************************************************************
Trigger qui empêche la modification du rôle d'un utilisateur
**************************************************************/
create or replace function users_role_immutable()
    returns trigger as
$$
begin
    raise exception 'User role cannot be changed';
end;
$$ language plpgsql;

create trigger users_role_immutable_trigger
before update of role
on users
for each row
execute function users_role_immutable();

select * from users;

update users set role= 'manager' where id = 1;
update users set role= 'client' where id = 2;

