create or replace trigger trigger_restaurant_unmodifiable_service
    before update of restaurant
    on services
    for each row
execute function check_restaurant_is_update();