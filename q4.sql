-- Do drivers improve?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q4 cascade;

create table q4(
	type VARCHAR(9),
	number INTEGER,
	early FLOAT,
	late FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS TrainedDrivers CASCADE;
-- All drivers that are trained and have given a ride on at least 10 different days
CREATE VIEW TrainedDrivers AS
SELECT Driver.driver_id as driver_id
FROM Driver, Dispatch, Request
WHERE Driver.driver_id = Dispatch.driver_id and Dispatch.request_id = Request.request_id and Driver.trained = true
GROUP BY Driver.driver_id
HAVING count(distinct to_char(Request.datetime, 'YYYY-MM-DD')) > 9;

DROP VIEW IF EXISTS AllDays CASCADE;
-- All the days drivers have given rides
CREATE VIEW AllDays AS
SELECT distinct Driver.driver_id as driver_id, Request.datetime as date
FROM Driver, Dispatch, Request
WHERE Driver.driver_id = Dispatch.driver_id and Dispatch.request_id = Request.request_id
GROUP BY Driver.driver_id, Request.datetime;

DROP VIEW IF EXISTS NotFirstDay CASCADE;
-- All the days drivers have given rides except the first day
CREATE VIEW NotFirstDay AS
SELECT a1.driver_id as driver_id, a1.date as date
FROM AllDays a1, AllDays a2
WHERE a1.driver_id = a2.driver_id and (a1.date - a2.date) > INTERVAL '0'
GROUP BY a1.driver_id, a1.date;

DROP VIEW IF EXISTS FirstDay CASCADE;
-- First days of all drivers
CREATE VIEW FirstDay AS
SELECT driver_id, date
FROM (
	(SELECT driver_id, date FROM AllDays) 
	EXCEPT 
	(SELECT driver_id, date FROM NotFirstDay)) as t1;

DROP VIEW IF EXISTS DayDivider CASCADE;
-- The fifth day (4 days from the first day) on the job
CREATE VIEW DayDivider AS
SELECT driver_id, date + interval '4 day' as date
FROM FirstDay;

DROP VIEW IF EXISTS TrainedEarlyRatings CASCADE;
CREATE VIEW TrainedEarlyRatings AS
SELECT TrainedDrivers.driver_id as driver_id, avg(rating) as early
FROM TrainedDrivers, DayDivider, Dispatch, Request, DriverRating
WHERE TrainedDrivers.driver_id = Dispatch.driver_id and Dispatch.request_id = Request.request_id 
	and Request.request_id = DriverRating.request_id and TrainedDrivers.driver_id = DayDivider.driver_id and
	(date - Request.datetime) >= INTERVAL '0'
GROUP BY TrainedDrivers.driver_id;

DROP VIEW IF EXISTS TrainedLateRatings CASCADE;
CREATE VIEW TrainedLateRatings AS
SELECT TrainedDrivers.driver_id as driver_id, avg(rating) as late
FROM TrainedDrivers, DayDivider, Dispatch, Request, DriverRating
WHERE TrainedDrivers.driver_id = Dispatch.driver_id and  
	Dispatch.request_id = Request.request_id and Request.request_id = DriverRating.request_id 
	and TrainedDrivers.driver_id = DayDivider.driver_id and (Request.datetime - date) >= INTERVAL '0'
GROUP BY TrainedDrivers.driver_id;

DROP VIEW IF EXISTS TrainedComplete CASCADE;
CREATE VIEW TrainedComplete AS
SELECT 'trained' as type, count(TrainedDrivers.driver_id) as number, avg(early) as early, avg(late) as late
FROM TrainedDrivers, TrainedEarlyRatings, TrainedLateRatings
WHERE TrainedDrivers.driver_id = TrainedEarlyRatings.driver_id and TrainedEarlyRatings.driver_id = TrainedLateRatings.driver_id;

DROP VIEW IF EXISTS UntrainedDrivers CASCADE;
CREATE VIEW UntrainedDrivers AS
SELECT Driver.driver_id as driver_id
FROM Driver, Dispatch, Request
WHERE Driver.driver_id = Dispatch.driver_id and Dispatch.request_id = Request.request_id and Driver.trained = false
GROUP BY Driver.driver_id
HAVING count(distinct to_char(Request.datetime, 'YYYY-MM-DD')) > 9;

DROP VIEW IF EXISTS UntrainedEarlyRatings CASCADE;
CREATE VIEW UntrainedEarlyRatings AS
SELECT UntrainedDrivers.driver_id as driver_id, avg(rating) as early
FROM UntrainedDrivers, DayDivider, Dispatch, Request, DriverRating
WHERE UntrainedDrivers.driver_id = Dispatch.driver_id and 
	Dispatch.request_id = Request.request_id and Request.request_id = DriverRating.request_id and
	UntrainedDrivers.driver_id = DayDivider.driver_id and (Request.datetime - date) < INTERVAL '0'
GROUP BY UntrainedDrivers.driver_id;

DROP VIEW IF EXISTS UntrainedLateRatings CASCADE;
CREATE VIEW UntrainedLateRatings AS
SELECT UntrainedDrivers.driver_id as driver_id, avg(rating) as late
FROM UntrainedDrivers, DayDivider, Dispatch, Request, DriverRating
WHERE UntrainedDrivers.driver_id = Dispatch.driver_id and 
	Dispatch.request_id = Request.request_id and Request.request_id = DriverRating.request_id and
	UntrainedDrivers.driver_id = DayDivider.driver_id and (Request.datetime - date) > INTERVAL '0'
GROUP BY UntrainedDrivers.driver_id;

DROP VIEW IF EXISTS UntrainedComplete CASCADE;
CREATE VIEW UntrainedComplete AS
SELECT 'untrained' as type, count(UntrainedDrivers.driver_id) as number, avg(early) as early, avg(late) as late
FROM UntrainedDrivers, UntrainedEarlyRatings, UntrainedLateRatings
WHERE UntrainedDrivers.driver_id = UntrainedEarlyRatings.driver_id and UntrainedEarlyRatings.driver_id = UntrainedLateRatings.driver_id;


-- Your query that answers the question goes below the "insert into" line:
insert into q4
SELECT type, number, early, late 
FROM 
((SELECT type, number, early, late FROM TrainedComplete)
UNION
(SELECT type, number, early, late FROM UntrainedComplete)) as t1;