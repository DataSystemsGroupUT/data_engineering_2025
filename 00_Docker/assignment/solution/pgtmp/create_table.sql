DROP TABLE IF EXISTS countries; 

CREATE TABLE countries (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    iso3 CHAR(3),
    iso2 CHAR(2),
    numeric_code INTEGER,
    phone_code VARCHAR(20),
    capital VARCHAR(255),
    currency CHAR(3),
    currency_name VARCHAR(255),
    currency_symbol VARCHAR(10),
    tld VARCHAR(10),
    native VARCHAR(255),
    region VARCHAR(100),
    region_id INTEGER,
    subregion VARCHAR(100),
    subregion_id INTEGER,
    nationality VARCHAR(100),
    timezones TEXT,
    latitude NUMERIC(15, 8),
    longitude NUMERIC(15, 8),
    emoji VARCHAR(5),
    emojiU VARCHAR(50)
);

-- It's better to manually create users table. 
-- Currently filtered out for demo purposes.
-- See further comment in ingest.py

-- DROP TABLE IF EXISTS users;

-- CREATE TABLE users
-- (
--     name_title text,
--     name_first text,
--     name_last text,
--     location_street_number text,
--     location_street_name text,
--     location_city text,
--     location_state text,
--     location_country text,
--     location_postcode text,
--     location_coordinates_latitude text,
--     location_coordinates_longitude text,
--     location_timezone_offset text,
--     location_timezone_description text
-- )