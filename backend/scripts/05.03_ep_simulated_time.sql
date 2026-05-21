drop function if exists get_system_time;

create or replace function get_system_time()
    returns system_time_info as
$$
    select row(simulated_time)::system_time_info
    from system_time
    limit 1;

$$ language sql security definer;

grant execute on function get_system_time() to anon, authenticated;
