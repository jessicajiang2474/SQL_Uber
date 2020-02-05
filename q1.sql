
-- Months


SET SEARCH_PATH TO uber, public;
drop table if exists q1 cascade;

create table q1(
    client_id INTEGER,
    email VARCHAR(30),
months INTEGER
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.

DROP VIEW IF EXISTS compRide CASCADE;
-- all the compeleted ride:
CREATE VIEW compRide AS
  (SELECT request_id From Request) INTERSECT (SELECT request_id From Dropoff);



DROP VIEW IF EXISTS _month_ CASCADE;
-- clients who have had a ride and their corresponding number of months
CREATE VIEW _month_ AS
  SELECT r.client_id, count(DISTINCT CONCAT(EXTRACT(YEAR FROM datetime), EXTRACT(MONTH FROM datetime))) as months
  FROM Request r, compRide c
  WHERE c.request_id = r.request_id
  GROUP BY client_id;



DROP VIEW IF EXISTS otherClient CASCADE;
-- all clients who have never had a ride
CREATE VIEW otherClient AS
  (SELECT client_id FROM Client)
  EXCEPT (SELECT client_id FROM _month_);





DROP VIEW IF EXISTS allClient CASCADE;
-- all clients a ndtheir corresponding numbers of months
CREATE VIEW allClient AS
  (SELECT client_id, 0 as months From otherClient)
   UNION
   (SELECT * from _month_);





DROP VIEW IF EXISTS answer1 CASCADE;

CREATE VIEW answer1 AS
  Select c.client_id as client_id, m.months as month, email
  From Client c, allClient m
  Where c.client_id = m.client_id;

-- Your query that answers the question goes below the "insert into" line:
insert into q1
  SELECT client_id, email, month
  From answer1;
