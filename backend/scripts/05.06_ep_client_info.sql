create or replace function get_client_info(client_id int)
    returns client_info as
$$
    select row (id, email, password, full_name, role, phone)::client_info
    from users as u
    where u.id = client_id

$$language sql security definer;