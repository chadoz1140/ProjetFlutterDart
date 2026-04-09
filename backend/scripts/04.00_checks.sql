--le nom contient au moins 5 caractères
ALTER TABLE restaurants
ADD CONSTRAINT check_name
check( length(trim(name)) >= 5 );

--le nom contient au moins 5 caractères
ALTER TABLE restaurants
ADD CONSTRAINT check_adresse
check ( length(trim(address)) >= 5 );

--l'adresse contient au moins 5 caractères
ALTER TABLE restaurants
ADD CONSTRAINT check_city
check ( length(trim(city)) >= 3 );

-- numéro de téléphone Belge valide
ALTER TABLE restaurants
ADD CONSTRAINT check_phone
CHECK (regexp_match(phone, '^(\+32\s?|0)[1-9]\d{0,2}(\s?\d{2}){3}$') IS NOT NULL)
NOT VALID;

--la description contient au moins 10 caract si fournie
ALTER TABLE restaurants
ADD CONSTRAINT check_description
check ( description is null or length(trim(description)) >= 10);

--la note est comprise entre 0.0 et 5.0
ALTER TABLE restaurants
ADD CONSTRAINT check_rating
check ( rating >= 0.0 and rating <= 5.0  );

--la note est comprise entre 0.0 et 5.0 si fournie
ALTER TABLE restaurants
ADD CONSTRAINT check_price_range
check ( price_range is null or ( price_range >= 1 and price_range <= 4) );

--la durée de créneau autorisée
ALTER TABLE restaurants
ADD CONSTRAINT check_slot_duration
check ( slot_duration in (10, 15, 20, 30, 60) );
