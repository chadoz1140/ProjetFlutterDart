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