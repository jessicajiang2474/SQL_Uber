-- Lure them back

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q2 cascade;

create table q2(
    client_id INTEGER,
    name VARCHAR(41),
    email VARCHAR(30),
    billed FLOAT ,
decline INTEGER
);


DROP VIEW IF EXISTS compRequest CASCADE;
-- all the completed ride
CREATE VIEW compRequest AS
    ( SELECT request_id FROM Request ) UNION (SELECT request_id FROM DropOff);



DROP VIEW IF EXISTS compSeparate CASCADE;
-- all the completed ride and year and month
CREATE VIEW compSeparate AS
    SELECT r.client_id,r.request_id,r.datetime,r.source,r.destination
    FROM  Request r, compRequest c
    WHERE r.request_id = c.request_id;


-- Define views for your intermediate steps here:
DROP VIEW IF EXISTS FormerSpender CASCADE;
CREATE VIEW FormerSpender AS
    SELECT Client.client_id as client_id, CONCAT(Client.firstname, ' ', Client.surname) as name,
           coalesce(Client.email, 'unknown') as email, sum(amount) as billed
    FROM Client, compSeparate, Billed
    WHERE Client.client_id = compSeparate.client_id and compSeparate.request_id = Billed.request_id AND EXTRACT(YEAR FROM compSeparate.datetime)<2014
    GROUP BY Client.client_id
    HAVING sum(amount) >= 500;

DROP VIEW IF EXISTS Rides2014 CASCADE;
--select clients who have 0~10 ride in 2014
CREATE VIEW Rides2014 AS
    SELECT client_id , count(request_id)as num_rides
    FROM  compSeparate
    WHERE  EXTRACT(YEAR FROM datetime) = 2014
    GROUP BY client_id
    HAVING count(request_id) < 11 and count(request_id) > 0;



DROP VIEW IF EXISTS Rides2015 CASCADE;
-- select clients who have ride in 2015
CREATE VIEW Rides2015 AS
    SELECT client_id , count(request_id) as num_rides
    FROM compSeparate
    WHERE  EXTRACT(YEAR FROM datetime) = 2015
    GROUP BY client_id;



DROP VIEW IF EXISTS all2015 CASCADE;
-- select all clients with no ride in 2015
CREATE VIEW other2015 AS
    (SELECT client_id FROM Client)
    EXCEPT (SELECT client_id FROM Rides2015);


DROP VIEW IF EXISTS all2015 CASCADE;
-- all clients a ndtheir corresponding numbers of months
CREATE VIEW all2015 AS
    (SELECT client_id, 0 as num_rides From other2015)
    UNION
    (SELECT * from Rides2015);



DROP VIEW IF EXISTS Difference CASCADE;
CREATE VIEW Difference AS
    SELECT r4.client_id as client_id, r4.num_rides - r5.num_rides as decline
    FROM all2015 r5, Rides2014 r4
    WHERE r4.client_id = r5.client_id AND r4.num_rides > r5.num_rides;


DROP VIEW IF EXISTS Satisfied CASCADE;
CREATE VIEW Satisfied AS
    (SELECT client_id from FormerSpender ) intersect (SELECT client_id FROM Difference) ;


DROP VIEW IF EXISTS Answer CASCADE;
CREATE VIEW Answer AS
    SELECT f.client_id, name, email, billed, decline
     FROM FormerSpender f, Satisfied s, Difference d
     WHERE f.client_id = s.client_id AND f.client_id = d.client_id AND s.client_id = d.client_id;



-- Your query that answers the question goes below the "insert into" line:
insert into q2
    SELECT * From Answer;