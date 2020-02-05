-- Ratings histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q7 cascade;

create table q7(
	driver_id INTEGER,
	r5 INTEGER,
	r4 INTEGER,
	r3 INTEGER,
	r2 INTEGER,
	r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS RatingFive CASCADE;
-- Drivers who have received a request 
CREATE VIEW RatingFive AS
SELECT driver_id, count(DriverRating.request_id) as r5
FROM DriverRating, Request, Dispatch, Dropoff
WHERE DriverRating.request_id = Request.request_id and Request.request_id = Dispatch.request_id and
    Request.request_id = Dropoff.request_id and rating = 5
GROUP BY driver_id;

DROP VIEW IF EXISTS NoRatingFive CASCADE;
-- Drivers who did not receive a rating of 5
CREATE VIEW NoRatingFive AS
SELECT driver_id, null as r5
FROM (
    (SELECT driver_id FROM Driver)
    EXCEPT
    (SELECT driver_id FROM RatingFive)) as t1;

DROP VIEW IF EXISTS Five CASCADE;
CREATE VIEW Five AS
SELECT driver_id, r5
FROM (
    (SELECT driver_id, r5 FROM RatingFive) 
    UNION 
    (SELECT driver_id, r5::int FROM NoRatingFive)) as t1;

DROP VIEW IF EXISTS RatingFour CASCADE;
CREATE VIEW RatingFour AS
SELECT driver_id, count(DriverRating.request_id) as r4
FROM DriverRating, Request, Dispatch, Dropoff
WHERE DriverRating.request_id = Request.request_id and Request.request_id = Dispatch.request_id and
    Request.request_id = Dropoff.request_id and rating = 4
GROUP BY driver_id;

DROP VIEW IF EXISTS NoRatingFour CASCADE;
CREATE VIEW NoRatingFour AS
SELECT driver_id, null as r4
FROM (
    (SELECT driver_id FROM Driver)
    EXCEPT
    (SELECT driver_id FROM RatingFour)) as t1;

DROP VIEW IF EXISTS Four CASCADE;
CREATE VIEW Four AS
SELECT driver_id, r4
FROM (
    (SELECT driver_id, r4 FROM RatingFour) 
    UNION 
    (SELECT driver_id, r4::int FROM NoRatingFour)) as t1;

DROP VIEW IF EXISTS RatingThree CASCADE;
CREATE VIEW RatingThree AS
SELECT driver_id, count(DriverRating.request_id) as r3
FROM DriverRating, Request, Dispatch, Dropoff
WHERE DriverRating.request_id = Request.request_id and Request.request_id = Dispatch.request_id and
    Request.request_id = Dropoff.request_id and rating = 3
GROUP BY driver_id;

DROP VIEW IF EXISTS NoRatingThree CASCADE;
CREATE VIEW NoRatingThree AS
SELECT driver_id, null as r3
FROM (
    (SELECT driver_id FROM Driver)
    EXCEPT
    (SELECT driver_id FROM RatingThree)) as t1;

DROP VIEW IF EXISTS Three CASCADE;
CREATE VIEW Three AS
SELECT driver_id, r3
FROM (
    (SELECT driver_id, r3 FROM RatingThree) 
    UNION 
    (SELECT driver_id, r3::int FROM NoRatingThree)) as t1;

DROP VIEW IF EXISTS RatingTwo CASCADE;
CREATE VIEW RatingTwo AS
SELECT driver_id, count(DriverRating.request_id) as r2
FROM DriverRating, Request, Dispatch, Dropoff
WHERE DriverRating.request_id = Request.request_id and Request.request_id = Dispatch.request_id and
    Request.request_id = Dropoff.request_id and rating = 2
GROUP BY driver_id;

DROP VIEW IF EXISTS NoRatingTwo CASCADE;
CREATE VIEW NoRatingTwo AS
SELECT driver_id, null as r2
FROM (
    (SELECT driver_id FROM Driver)
    EXCEPT
    (SELECT driver_id FROM RatingTwo)) as t1;

DROP VIEW IF EXISTS Two CASCADE;
CREATE VIEW Two AS
SELECT driver_id, r2
FROM (
    (SELECT driver_id, r2 FROM RatingTwo) 
    UNION 
    (SELECT driver_id, r2::int FROM NoRatingTwo)) as t1;

DROP VIEW IF EXISTS RatingOne CASCADE;
CREATE VIEW RatingOne AS
SELECT driver_id, count(DriverRating.request_id) as r1
FROM DriverRating, Request, Dispatch, Dropoff
WHERE DriverRating.request_id = Request.request_id and Request.request_id = Dispatch.request_id and
    Request.request_id = Dropoff.request_id and rating = 1
GROUP BY driver_id;

DROP VIEW IF EXISTS NoRatingOne CASCADE;
CREATE VIEW NoRatingOne AS
SELECT driver_id, null as r1
FROM (
    (SELECT driver_id FROM Driver)
    EXCEPT
    (SELECT driver_id FROM RatingOne)) as t1;

DROP VIEW IF EXISTS One CASCADE;
CREATE VIEW One AS
SELECT driver_id, r1
FROM (
    (SELECT driver_id, r1 FROM RatingOne) 
    UNION 
    (SELECT driver_id, r1::int FROM NoRatingOne)) as t1;

DROP VIEW IF EXISTS DriversWithRatings CASCADE;
CREATE VIEW DriversWithRatings AS
SELECT r5.driver_id as driver_id, r5, r4, r3, r2, r1
FROM One r1, Two r2, Three r3, Four r4, Five r5
WHERE r1.driver_id = r2.driver_id and r2.driver_id = r3.driver_id and r3.driver_id = r4.driver_id and
    r4.driver_id = r5.driver_id;




-- Your query that answers the question goes below the "insert into" line:
insert into q7
SELECT driver_id, r5, r4, r3, r2, r1
FROM DriversWithRatings;
