
DROP FUNCTION IF EXISTS public.get_reservations(status_type);

CREATE OR REPLACE FUNCTION get_reservations(p_status status_type DEFAULT NULL) RETURNS jsonb AS
$$
BEGIN
    PERFORM auth.check_logged();
    RETURN (
        SELECT COALESCE(
                       jsonb_agg(
                               jsonb_build_object(
                                       'id', r.id,
                                       'client', r.client,
                                       'datetime', r.datetime,
                                       'number_of_guests', r.number_of_guests,
                                       'status', r.status,
                                       'special_requests', r.special_requests,
                                       'restaurant', (
                                           SELECT jsonb_build_object('name', res.name, 'city', res.city)
                                           FROM restaurants res
                                           WHERE res.id = r.restaurant
                                       )
                               )
                               ORDER BY r.datetime DESC
                       ),
                       '[]'::jsonb
               )
        FROM reservations r
        WHERE (auth.role() = 'admin' OR r.client = (SELECT id FROM users us WHERE us.email = auth.email()))
          AND (p_status IS NULL OR r.status = p_status)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_reservations(status_type) TO authenticated;

