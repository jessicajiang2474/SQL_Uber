-- Rainmakers

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q10 cascade;

create table q10(
	driver_id INTEGER,
	month CHAR(2),
	mileage_2014 FLOAT,
	billings_2014 FLOAT,
	mileage_2015 FLOAT,
	billings_2015 FLOAT,
	billings_increase FLOAT,
	mileage_increase FLOAT
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS Months CASCADE;
CREATE VIEW Months AS
SELECT to_char(DATE '2014-01-01' + (interval '1' month * generate_series(0,11)), 'MM') as month;

DROP VIEW IF EXISTS DriverMonth CASCADE;
CREATE VIEW DriverMonth AS
SELECT driver_id, month
FROM Driver, Months;

DROP VIEW IF EXISTS RequestsByMonth2014 CASCADE;
CREATE VIEW RequestsByMonth2014 AS
SELECT request_id, client_id, to_char(datetime, 'MM') as month, source, destination
FROM Request
WHERE EXTRACT(YEAR FROM datetime) = 2014;

DROP VIEW IF EXISTS SourceRequestsByMonth2014 CASCADE;
CREATE VIEW SourceRequestsByMonth2014 AS
SELECT request_id, client_id, month, location as source, destination
FROM RequestsByMonth2014, Place
WHERE source = name;

DROP VIEW IF EXISTS LocationRequestsByMonth2014 CASCADE;
CREATE VIEW LocationRequestsByMonth2014 AS
SELECT request_id, client_id, month, source, location as destination
FROM SourceRequestsByMonth2014, Place
WHERE destination = name;

DROP VIEW IF EXISTS Driver2014Stats CASCADE;
CREATE VIEW Driver2014Stats AS
SELECT driver_id, month, sum(loc.source <@> loc.destination) as mileage_2014, 
	sum(amount) as billings_2014
FROM LocationRequestsByMonth2014 loc, Dispatch, Billed
WHERE loc.request_id = Dispatch.request_id and Dispatch.request_id = Billed.request_id
GROUP BY driver_id, month;

DROP VIEW IF EXISTS AllDriver2014NoStats CASCADE;
CREATE VIEW AllDriver2014NoStats AS
SELECT driver_id, month
FROM (
	(SELECT driver_id, month from DriverMonth)
	EXCEPT
	(SELECT driver_id, month from Driver2014Stats)) as t1;

DROP VIEW IF EXISTS RowsToRemove2014 CASCADE;
CREATE VIEW RowsToRemove2014 AS
SELECT d1.driver_id, d1.month
FROM AllDriver2014NoStats d1, Driver2014Stats d2
WHERE d1.driver_id = d2.driver_id and d1.month = d2.month;

DROP VIEW IF EXISTS Driver2014NoStats CASCADE;
CREATE VIEW Driver2014NoStats AS
SELECT driver_id, month, 0 as mileage_2014, 0 as billings_2014
FROM (
	(SELECT driver_id, month FROM AllDriver2014NoStats)
	EXCEPT
	(SELECT driver_id, month from RowsToRemove2014)) as t1;

DROP VIEW IF EXISTS AllDriver2014Stats CASCADE;
CREATE VIEW AllDriver2014Stats AS 
SELECT driver_id, month, mileage_2014, billings_2014
FROM (
	(SELECT driver_id, month, mileage_2014, billings_2014 FROM Driver2014Stats)
	UNION
	(SELECT driver_id, month, mileage_2014, billings_2014 FROM Driver2014NoStats)) as t1;

DROP VIEW IF EXISTS RequestsByMonth2015 CASCADE;
CREATE VIEW RequestsByMonth2015 AS
SELECT request_id, client_id, to_char(datetime, 'MM') as month, source, destination
FROM Request
WHERE EXTRACT(YEAR FROM datetime) = 2015;

DROP VIEW IF EXISTS SourceRequestsByMonth2015 CASCADE;
CREATE VIEW SourceRequestsByMonth2015 AS
SELECT request_id, client_id, month, location as source, destination
FROM RequestsByMonth2015, Place
WHERE source = name;

DROP VIEW IF EXISTS LocationRequestsByMonth2015 CASCADE;
CREATE VIEW LocationRequestsByMonth2015 AS
SELECT request_id, client_id, month, source, location as destination
FROM SourceRequestsByMonth2015, Place
WHERE destination = name;

DROP VIEW IF EXISTS Driver2015Stats CASCADE;
CREATE VIEW Driver2015Stats AS
SELECT driver_id, month, sum(loc.source <@> loc.destination) as mileage_2015, 
	sum(amount) as billings_2015
FROM LocationRequestsByMonth2015 loc, Dispatch, Billed
WHERE loc.request_id = Dispatch.request_id and Dispatch.request_id = Billed.request_id
GROUP BY driver_id, month;

DROP VIEW IF EXISTS AllDriver2015NoStats CASCADE;
CREATE VIEW AllDriver2015NoStats AS
SELECT driver_id, month
FROM (
	(SELECT driver_id, month from DriverMonth)
	EXCEPT
	(SELECT driver_id, month from Driver2015Stats)) as t1;

DROP VIEW IF EXISTS RowsToRemove2015 CASCADE;
CREATE VIEW RowsToRemove2015 AS
SELECT d1.driver_id, d1.month
FROM AllDriver2015NoStats d1, Driver2015Stats d2
WHERE d1.driver_id = d2.driver_id and d1.month = d2.month;

DROP VIEW IF EXISTS Driver2015NoStats CASCADE;
CREATE VIEW Driver2015NoStats AS
SELECT driver_id, month, 0 as mileage_2015, 0 as billings_2015
FROM (
	(SELECT driver_id, month FROM AllDriver2015NoStats)
	EXCEPT
	(SELECT driver_id, month from RowsToRemove2015)) as t1;

DROP VIEW IF EXISTS AllDriver2015Stats CASCADE;
CREATE VIEW AllDriver2015Stats AS 
SELECT driver_id, month, mileage_2015, billings_2015
FROM (
	(SELECT driver_id, month, mileage_2015, billings_2015 FROM Driver2015Stats)
	UNION
	(SELECT driver_id, month, mileage_2015, billings_2015 FROM Driver2015NoStats)) as t1;

DROP VIEW IF EXISTS DriversWithStats CASCADE;
CREATE VIEW DriversWithStats AS
SELECT d1.driver_id as driver_id, d1.month as month, mileage_2014, billings_2014, mileage_2015, billings_2015, 
	billings_2015 - billings_2014 as billings_increase, mileage_2015 - mileage_2014 as mileage_increase
FROM AllDriver2014Stats d1, AllDriver2015Stats d2
WHERE d1.driver_id = d2.driver_id and d1.month = d2.month;

-- Your query that answers the question goes below the "insert into" line:
insert into q10
SELECT driver_id, month, mileage_2014, billings_2014, mileage_2015, billings_2015, billings_increase, mileage_increase
FROM DriversWithStats;