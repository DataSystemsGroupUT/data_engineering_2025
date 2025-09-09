CREATE OR REPLACE VIEW fixed_coordinates AS 
SELECT name_title
, name_first
, name_last
, location_country
, location_coordinates_latitude
, location_coordinates_longitude
, c.latitude
, c.longitude
FROM public.users u 
JOIN countries c 
ON u.location_country = c.name