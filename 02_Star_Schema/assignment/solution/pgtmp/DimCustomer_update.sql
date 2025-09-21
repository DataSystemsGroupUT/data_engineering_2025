-- Customer moves to Tartu (SCD Type 2)
-- Mark old record as not current
UPDATE DimCustomer SET ValidTo = CURRENT_DATE - INTERVAL '1 day' WHERE CustomerKey = 1 AND ValidTo = '9999-12-31';

-- Insert new record for new location
INSERT INTO DimCustomer (FirstName, LastName, Segment, City, ValidFrom, ValidTo)
VALUES ('Alice', 'Smith', 'Regular', 'Tartu', CURRENT_DATE, '9999-12-31');
