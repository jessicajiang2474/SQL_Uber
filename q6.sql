-- Frequent riders

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q6 cascade;

create table q6(
	client_id INTEGER,
	year CHAR(4),
	rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS AllRidesWithYears CASCADE;
-- Every ride with the year of the ride
CREATE VIEW AllRidesWithYears AS
SELECT r.request_id, EXTRACT(YEAR FROM r.datetime) as year
FROM Dropoff d, Request r
WHERE d.request_id = r.request_id;

DROP VIEW IF EXISTS ClientRidesPerYear CASCADE;
-- The number of rides each client had in each year
CREATE VIEW ClientRidesPerYear AS
SELECT Client.client_id as client_id, count(AllRidesWithYears.request_id) as num_rides, year
FROM Client, Request, AllRidesWithYears
WHERE Client.client_id = Request.client_id and Request.request_id = AllRidesWithYears.request_id
GROUP BY Client.client_id, year;

DROP VIEW IF EXISTS ClientsNoRideYear CASCADE;
-- All clients with no rides in a year
CREATE VIEW ClientsNoRideYear AS
SELECT distinct client_id, 0 as num_rides, year
FROM Client, AllRidesWithYears;

DROP VIEW IF EXISTS RowsToRemove CASCADE;
-- The clients that already have rides in a year
CREATE VIEW RowsToRemove AS
SELECT client_id, year
FROM (
	(SELECT client_id, year FROM ClientsNoRideYear)
	EXCEPT
	(SELECT client_id, year FROM ClientRidesPerYear)) as t1;

DROP VIEW IF EXISTS ClientRidesPerYearNone CASCADE;
-- The remaining clients who had no rides in a year
CREATE VIEW ClientRidesPerYearNone AS
SELECT c.client_id, num_rides, c.year
FROM ClientsNoRideYear c, RowsToRemove r
WHERE c.client_id = r.client_id and c.year = r.year;

DROP VIEW IF EXISTS AllClientRidesPerYear CASCADE;
CREATE VIEW AllClientRidesPerYear AS
SELECT client_id, num_rides, year
FROM (
	(SELECT client_id, num_rides, year FROM ClientRidesPerYear)
	UNION
	(SELECT client_id, num_rides, year FROM ClientRidesPerYearNone)) as t1;

DROP VIEW IF EXISTS NotTopClient CASCADE;
-- All clients with # of rides per year except the clients with the most rides in each year
CREATE VIEW NotTopClient AS
SELECT c1.client_id as client_id, c1.num_rides as num_rides, c1.year as year
FROM AllClientRidesPerYear c1, AllClientRidesPerYear c2
WHERE c1.client_id != c2.client_id and c1.num_rides < c2.num_rides and c1.year = c2.year;

DROP VIEW IF EXISTS TopClient CASCADE;
-- The top client in each year
CREATE VIEW TopClient AS
(SELECT client_id, num_rides, year FROM AllClientRidesPerYear)
EXCEPT
(SELECT client_id, num_rides, year FROM NotTopClient);

DROP VIEW IF EXISTS NotSecondTopClient CASCADE;
-- All clients with # of rides per year except clients with most and second most rides in each year
CREATE VIEW NotSecondTopClient AS
SELECT c1.client_id as client_id, c1.num_rides as num_rides, c1.year as year
FROM NotTopClient c1, NotTopClient c2
WHERE c1.client_id != c2.client_id and c1.num_rides < c2.num_rides and c1.year = c2.year;

DROP VIEW IF EXISTS SecondTopClient CASCADE;
-- The second top client in each year
CREATE VIEW SecondTopClient AS
(SELECT client_id, num_rides, year FROM NotTopClient)
EXCEPT
(SELECT client_id, num_rides, year FROM NotSecondTopClient);

DROP VIEW IF EXISTS NotThirdTopClient CASCADE;
-- All clients with # of rides per year except clients with most, second most, and third most rides in each year
CREATE VIEW NotThirdTopClient AS
SELECT c1.client_id as client_id, c1.num_rides as num_rides, c1.year as year
FROM NotSecondTopClient c1, NotSecondTopClient c2
WHERE c1.client_id != c2.client_id and c1.num_rides < c2.num_rides and c1.year = c2.year;

DROP VIEW IF EXISTS ThirdTopClient CASCADE;
-- The third top client in each year
CREATE VIEW ThirdTopClient AS
(SELECT client_id, num_rides, year FROM NotSecondTopClient)
EXCEPT
(SELECT client_id, num_rides, year FROM NotThirdTopClient);

DROP VIEW IF EXISTS TopThreeClients CASCADE;
-- The top three clients in each year
CREATE VIEW TopThreeClients AS
(SELECT client_id, num_rides, year FROM TopClient)
UNION
(SELECT client_id, num_rides, year FROM SecondTopClient)
UNION
(SELECT client_id, num_rides, year FROM ThirdTopClient);

DROP VIEW IF EXISTS NotBottomClient CASCADE;
-- All clients with # of rides per year except the clients with the least rides in each year
CREATE VIEW NotBottomClient AS
SELECT c1.client_id as client_id, c1.num_rides as num_rides, c1.year as year
FROM AllClientRidesPerYear c1, AllClientRidesPerYear c2
WHERE c1.client_id != c2.client_id and c1.num_rides > c2.num_rides and c1.year = c2.year;

DROP VIEW IF EXISTS BottomClient CASCADE;
-- The bottom client in each year
CREATE VIEW BottomClient AS
(SELECT client_id, num_rides, year FROM AllClientRidesPerYear)
EXCEPT
(SELECT client_id, num_rides, year FROM NotBottomClient);

DROP VIEW IF EXISTS NotSecondBottomClient CASCADE;
-- All clients with # of rides per year except the clients with the least and second least rides in each year
CREATE VIEW NotSecondBottomClient AS
SELECT c1.client_id as client_id, c1.num_rides as num_rides, c1.year as year
FROM NotBottomClient c1, NotBottomClient c2
WHERE c1.client_id != c2.client_id and c1.num_rides > c2.num_rides and c1.year = c2.year;

DROP VIEW IF EXISTS SecondBottomClient CASCADE;
-- The second bottom client in each year
CREATE VIEW SecondBottomClient AS
(SELECT client_id, num_rides, year FROM NotBottomClient)
EXCEPT
(SELECT client_id, num_rides, year FROM NotSecondBottomClient);

DROP VIEW IF EXISTS NotThirdBottomClient CASCADE;
-- All clients with # of rides per year except the clients with the least, second least, and third least rides in each year
CREATE VIEW NotThirdBottomClient AS
SELECT c1.client_id as client_id, c1.num_rides as num_rides, c1.year as year
FROM NotSecondBottomClient c1, NotSecondBottomClient c2
WHERE c1.client_id != c2.client_id and c1.num_rides > c2.num_rides and c1.year = c2.year;

DROP VIEW IF EXISTS ThirdBottomClient CASCADE;
CREATE VIEW ThirdBottomClient AS
(SELECT client_id, num_rides, year FROM NotSecondBottomClient)
EXCEPT
(SELECT client_id, num_rides, year FROM NotThirdBottomClient);

DROP VIEW IF EXISTS BottomThreeClients CASCADE;
CREATE VIEW BottomThreeClients AS
(SELECT client_id, num_rides, year FROM BottomClient)
UNION
(SELECT client_id, num_rides, year FROM SecondBottomClient)
UNION
(SELECT client_id, num_rides, year FROM ThirdBottomClient);

-- uhh might have to do distinct rows, what if the case where there is only 3 or less riders in a year, then they will repeat in answer
-- Your query that answers the question goes below the "insert into" line:
insert into q6
SELECT client_id, year, num_rides as rides
FROM (
	(SELECT client_id, num_rides, year
	FROM TopThreeClients)
	UNION
	(SELECT client_id, num_rides, year
	FROM BottomThreeClients)) as t1;