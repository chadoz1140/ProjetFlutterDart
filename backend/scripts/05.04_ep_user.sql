/** Get user info **/
drop function if exists get_client_info(client_id int);

create or replace function get_client_info(client_id int)
    returns client_info as
$$
select row (id, email, password, full_name, role, phone)::client_info
from users as u
where u.id = client_id

$$language sql security definer;

/**************************************************************
 Fonction qui permet de vérifier si un full_name est disponible
 **************************************************************/
create or replace function check_full_name_available(full_name text) returns boolean as
$$
begin
    return not exists(select 1 from users where lower(users.full_name)= lower(check_full_name_available.full_name));
end
$$ language plpgsql security definer;

grant execute on function check_full_name_available to anon;

/**********************************************************
 Fonction qui permet de vérifier si un email est disponible
**********************************************************/
create or replace function check_email_available(email text) returns boolean as
$$
    begin
        return not exists(select 1 from users where lower(users.email) = lower(check_email_available.email));
    end;

$$ language plpgsql security definer;

grant execute on function check_email_available to anon;

/**************************************************************
 Fonction signup
 **************************************************************/

create or replace function signup(email text, full_name text, password text, phone text default null) returns void as
$$
begin
    if not check_full_name_available(full_name) then
        raise exception 'User ''%'' already exists', full_name;
    end if;

    if not check_email_available(email) then
        raise exception  'Email ''%'' already exists', email;
    end if;
    insert into users (email, full_name, password, phone)
    values (signup.email, signup.full_name, signup.password, signup.phone);
end;
$$ language plpgsql security definer;

grant execute on function signup to anon;






