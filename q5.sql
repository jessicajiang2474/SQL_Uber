--Bigger and smaller spenders
--CONVERT(CHAR(4), date_of_birth, 100) + CONVERT(CHAR(4), date_of_birth, 120)
-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q5 cascade;

create table q5(
    client_id INTEGER,
    month VARCHAR ,
    total FLOAT  ,
    comparison VARCHAR

);


DROP VIEW IF EXISTS compRequest CASCADE;
-- all the completed ride
CREATE VIEW compRequest AS
  ( SELECT request_id FROM Request ) UNION (SELECT request_id FROM DropOff);



DROP VIEW IF EXISTS compSeparate CASCADE;
-- all the completed ride and year and month
CREATE VIEW compSeparate AS
   SELECT r.client_id,c.request_id, EXTRACT(year from datetime) AS year , to_char(datetime, 'MM') AS month

   FROM  Request r, compRequest c
   WHERE r.request_id = c.request_id;


DROP VIEW IF EXISTS perMonth CASCADE;
-- each client's per month requests amount
CREATE VIEW perMonth AS
   SELECT s.client_id, SUM(amount) as total, year, month,
          CONCAT(CAST(s.year AS varchar(4)), ' ',CAST(s.month AS varchar(2)) ) AS yearmonth
   FROM  compSeparate s, Billed b
   WHERE s.request_id =  b.request_id
   GROUP BY client_id, year, month ;




DROP VIEW IF EXISTS comb CASCADE;
-- all possible combination of client and month
CREATE VIEW comb AS
   SELECT *
   FROM
  (SELECT year,month,CONCAT(CAST(year AS varchar(4)), ' ',CAST(month AS varchar(2)) ) AS yearmonth FROM compSeparate)AS co
    ,(SELECT client_id FROM  Client) AS cl;


DROP VIEW IF EXISTS norideM CASCADE;
-- the months the certain clients do not have a ride
CREATE VIEW norideM AS
   SELECT client_id, year, month, yearmonth,0 as total
   FROM (SELECT year,month,yearmonth,client_id FROM comb EXCEPT SELECT year,month,yearmonth,client_id FROM perMonth) AS pe;


DROP VIEW IF EXISTS allRide CASCADE;
-- all combinations of client and month and the corresponding bills
CREATE VIEW allRide AS
  (SELECT client_id, year, month,yearmonth,total FROM perMonth)
  UNION
  (SELECT  client_id, year, month,yearmonth,total from noRideM);



DROP VIEW IF EXISTS monthAvg CASCADE;
-- the average total of each month
CREATE VIEW monthAvg AS
    SELECT avg(total) as average, CONCAT(CAST(year AS varchar(4)), ' ',CAST(month AS varchar(2)) ) AS ym
    FROM perMonth
    GROUP BY year, month;




DROP VIEW IF EXISTS Answer CASCADE;
-- the average total of each month
CREATE VIEW Answer AS
    SELECT client_id,yearmonth AS month, total,
    CASE
    WHEN total <  average THEN 'below'
    WHEN total >= average THEN 'at or above'
    END AS comparison
    FROM  allRide p, monthAvg m
    WHERE p.yearmonth = m.ym;





   -- Define views for your intermediate steps here:


-- Your query that answers the question goes below the "insert into" line:
insert into q5
SELECT *
FROM Answer;