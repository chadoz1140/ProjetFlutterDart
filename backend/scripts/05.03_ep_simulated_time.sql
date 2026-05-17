create or replace function get_system_time()
    returns jsonb as
$$
begin
    return (
        select jsonb_build_object(
                       'simulated_time', simulated_time
               )
        from system_time
        limit 1
    );
end;
$$ language plpgsql security definer;

grant execute on function get_system_time() to anon, authenticated;
