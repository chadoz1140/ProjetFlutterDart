drop type if exists system_time_info cascade;

create type system_time_info as
(
    simulated_time timestamp
);

drop type if exists table_info cascade;

create type table_info as
(
    id int,
    restaurant int,
    table_number int,
    capacity int
);

drop type if exists service_info cascade;

create type service_info as
(
    id int,
    restaurant int,
    day_of_week int,
    start_time time,
    end_time time
);

drop type if exists client_info cascade;

create type client_info as
(
    id int,
    email text,
    password text,
    full_name text,
    role role_type,
    phone text
);

drop type if exists restaurant_info cascade;

create type restaurant_info as
(
    id int,
    name text,
    address text,
    city text,
    phone text,
    description text,
    rating double precision,
    price_range int,
    slot_duration int
);

drop type if exists reservation_details cascade;

create type reservation_details as
(
    id integer,
    datetime timestamp,
    number_of_guests int,
    status status_type,
    special_requests text,
    client client_info,
    restaurant restaurant_info
);

drop type if exists restaurant_details cascade;

create type restaurant_details as
(
    id int,
    name text,
    address text,
    city text,
    phone text,
    description text,
    rating double precision,
    price_range int,
    slot_duration int,
    tables table_info[],
    services service_info[]
);

drop type if exists restaurant_client_stats cascade;

create type restaurant_client_stats as
(
   restaurant_id             int,
   last_reservation_datetime timestamp,
   pending_count             int
);

drop type if exists restaurant_with_client_info cascade;

create type restaurant_with_client_info as
(
   id                        int,
   name                      text,
   city                      text,
   phone                     text,
   rating                    double precision,
   last_reservation_datetime timestamp,
   pending_requests_count    int
);

drop type if exists initial_reservation_data cascade;
create type initial_reservation_data as
(
    restaurant  restaurant_info,
    reservation_date date,
    selected_slot time,
    slots time[],
    restaurant_closed boolean,
    client_has_reservation_for_all_services boolean, /*pour un seul client 1 seule reservation par service, par restau, par date*/
    over_capacity boolean
);