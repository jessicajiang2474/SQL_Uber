-- Consistent raters

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q9 cascade;

create table q9(
	client_id INTEGER,
	email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS ClientAndDrivers CASCADE;
-- The pairs of client and drivers that has had a ride together
CREATE VIEW ClientAndDrivers AS
SELECT distinct client_id, driver_id
FROM Request, Dispatch, Dropoff
WHERE Request.request_id = Dispatch.request_id and Request.request_id = Dropoff.request_id;

DROP VIEW IF EXISTS RidesRated CASCADE;
-- Rides where drivers have been rated by the client
CREATE VIEW RidesRated AS
SELECT distinct client_id, driver_id
FROM Request, Dispatch, DriverRating, Dropoff
WHERE Request.request_id = Dispatch.request_id and Request.request_id = DriverRating.request_id and 
	Request.request_id = Dropoff.request_id;

DROP VIEW IF EXISTS InvalidClients CASCADE; 
CREATE VIEW InvalidClients AS
SELECT client_id
FROM (
	(SELECT client_id, driver_id FROM ClientAndDrivers)
	EXCEPT
	(SELECT client_id, driver_id FROM RidesRated)) as t1;

DROP VIEW IF EXISTS ValidClients CASCADE;
CREATE VIEW ValidClients AS
SELECT client_id
FROM (
	(SELECT client_id FROM ClientAndDrivers)
	EXCEPT
	(SELECT client_id FROM InvalidClients)) as t1;



-- Your query that answers the question goes below the "insert into" line:
insert into q9
SELECT ValidClients.client_id as client_id, email
FROM ValidClients, Client
WHERE ValidClients.client_id = Client.client_id;
