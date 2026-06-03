/***************************************************************************
 Empêche la modification des clés primaires composées des tables
 d'association.
****************************************************************************/

CREATE OR REPLACE FUNCTION prevent_primary_key_update()
    RETURNS trigger AS
$$
BEGIN
    RAISE EXCEPTION 'Primary key columns cannot be updated.';
END;
$$ LANGUAGE plpgsql;




DROP TRIGGER IF EXISTS reservation_tables_primary_key_immutable_trigger
    ON reservation_tables;

CREATE TRIGGER reservation_tables_primary_key_immutable_trigger
    BEFORE UPDATE OF reservation, "table"
    ON reservation_tables
    FOR EACH ROW
    EXECUTE FUNCTION prevent_primary_key_update();



DROP TRIGGER IF EXISTS restaurant_managers_primary_key_immutable_trigger
    ON restaurant_managers;

CREATE TRIGGER restaurant_managers_primary_key_immutable_trigger
    BEFORE UPDATE OF restaurant, manager
    ON restaurant_managers
    FOR EACH ROW
    EXECUTE FUNCTION prevent_primary_key_update();