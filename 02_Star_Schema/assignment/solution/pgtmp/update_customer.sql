UPDATE DimCustomer
SET ValidTo = CURRENT_DATE - INTERVAL '1 day'
WHERE CustomerKey = 1
  AND ValidTo = '9999-12-31';

INSERT INTO DimCustomer (CustomerKey, FirstName, LastName, Segment, City, ValidFrom, ValidTo)
VALUES (3, 'Alice', 'Smith', 'Regular', 'Tartu', CURRENT_DATE, '9999-12-31');