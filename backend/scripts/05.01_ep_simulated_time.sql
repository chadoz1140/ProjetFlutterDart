drop function if exists get_system_time;

create or replace function get_system_time()
    returns system_time_info as
$$
    select row(simulated_time)::system_time_info
    from system_time
    limit 1;

$$ language sql security definer;

grant execute on function get_system_time() to anon, authenticated;


/** Met à jour le temps simulé **/

drop function if exists set_system_time(timestamp);

create or replace function set_system_time(p_simulated_time timestamp)
    returns void as
$$
begin
    if exists (select 1 from system_time) then
        update system_time set simulated_time = p_simulated_time;
    else
        insert into system_time (simulated_time) values (p_simulated_time);
    end if;
end;
$$ language plpgsql security definer;

grant execute on function set_system_time(timestamp) to authenticated;
