-- Rest bylaw

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q3 cascade;

create table q3(
    driver integer NOT NULL REFERENCES Driver,
    start DATE,
    driving varchar,
    breaks varchar
);

-- Do this for each of the views that define your intermediate steps.
-- (But give them better names!) The IF EXISTS avoids generating an error
-- the first time this file is imported.

DROP VIEW IF EXISTS PickupNew CASCADE;
--the driver of each pickup and separete datetime
CREATE VIEW PickupNew AS
  SELECT  driver_id, p.request_id, p.datetime, EXTRACT(year from p.datetime) AS year,
         EXTRACT(month from p.datetime) AS month , EXTRACT(day FROM p.datetime) AS day
  From Pickup p, Dispatch d
  WHERE p.request_id = d.request_id;




DROP VIEW IF EXISTS DropoffNew CASCADE;
--the driver of each dropoff and separete datetime
CREATE VIEW DropoffNew AS
  SELECT  driver_id,dr.request_id, dr.datetime, EXTRACT (year from dr.datetime) AS year,
          EXTRACT(month from dr.datetime) AS month , EXTRACT(day FROM dr.datetime) AS day
  From Dropoff dr, Dispatch di
  WHERE dr.request_id = di.request_id;




DROP VIEW IF EXISTS Timerange CASCADE;
-- each request's time spent
CREATE VIEW Timerange AS
   SELECT d.driver_id, d.request_id, p.datetime AS pickuptime, d.datetime AS dropofftime,
          EXTRACT(EPOCH FROM( d.datetime - p.datetime )) AS range, p.year,
          p.month, p.day
   From PickupNew p,DropoffNew d
   WHERE d.year = p.year AND d.month = p.month AND d.day = p.day AND d.request_id = p.request_id;




DROP VIEW IF EXISTS DriverTime CASCADE;
--each driver's one day total driving time
CREATE VIEW DriverTime AS
     SELECT driver_id,year,month,day, Sum(range) AS totaltime
     FROM TimeRange t
     GROUP BY driver_id,year,month,day;



DROP VIEW IF EXISTS DropPick CASCADE;
--the most positively close pickup time to each dropoff time of a driver per day, and the correspondind elapsed
CREATE VIEW DropPick AS
    Select d.driver_id,d.year,d.month,d.day,d.datetime AS dtime, MIN(p.datetime) AS ptime,
      EXTRACT(EPOCH FROM( MIN(p.datetime) -d.datetime  )) as break
    FROM PickupNew p,DropoffNew d
    WHERE d.driver_id = p.driver_id AND d.year = p.year
          AND d.month = p.month AND d.day = p.day AND p.datetime > d.datetime
    GROUP BY d.driver_id,d.year,d.month,d.day, d.datetime;


Drop VIEW IF EXISTS NoBreak CASCADE;
--the date of each driver does not have any break last more than 15 minutes
CREATE VIEW Nobreak AS
  (SELECT driver_id,year,month,day
   From DropPick)
  EXCEPT
  (SELECT driver_id,year,month,day
  FROM DropPick
  WHERE break > 900);


Drop VIEW IF EXISTS Nobylaw CASCADE;
--the date of each driver does not have any break last more than 15 minutes or work more than 12 hrs
--the total work time and breaktime for each driver who are not bylaw
CREATE VIEW Nobylaw AS
  (SELECT bre.driver_id, bre.year,bre.month ,bre.day,SUM(break) AS totalbreak, SUM(totaltime) as totaltime
   FROM NoBreak bre, DriverTime dri,DropPick dro
   WHERE dri.driver_id = dro.driver_id AND dri.driver_id = bre.driver_id AND dro.driver_id = bre.driver_id AND
         dri.year = dro.year AND dri.year  = bre.year AND dro.year = bre.year AND
         dri.month =dro.month  AND dri.month  =dro.month AND dro.month =dro.month AND
         dri.day=dro.day  AND   dri.day=bre.day  AND   bre.day=dro.day
   GROUP BY bre.driver_id,bre.year,bre.month,bre.day
   )
   UNION
   (SELECT dri.driver_id,dri.year,dri.month , dri.day, SUM(break) AS totalbreak, SUM(totaltime) as totaltime
   FROM DriverTime dri , DropPick dro
   WHERE totaltime>43200 AND dri.driver_id = dro.driver_id AND
          dri.year = dro.year AND dri.month = dro.month AND dri.day=dro.day
   GROUP BY dri.driver_id,dri.year,dri.month ,dri.day);



Drop VIEW IF EXISTS ContiThreePre CASCADE;
--the first day of the continuous three days of those drivers who are not bylaw
CREATE VIEW ContiThreePre AS
    SELECT by.driver_id,by.year,by.month ,by.day, pi.datetime, by.totalbreak, by.totaltime
    FROM NoBylaw by, PickupNew pi
    WHERE by.driver_id =pi.driver_id AND by.year = pi.year AND by.month = pi.month AND by.day  =pi.day;





Drop VIEW IF EXISTS ContiThree CASCADE;
--the first day of the continuous three days of those drivers who are not bylaw
CREATE VIEW ContiThree AS
    SELECT p1.driver_id AS driver,CAST(CONCAT(p1.year, '-', p1.month, '-', p1.day) AS DATE) AS start,
    p1.totaltime * interval '1 sec' AS driving,
    p1.totalbreak * interval '1 sec' AS breaks
    FROM  ContiThreePre p1, ContiThreePre p2,  ContiThreePre p3
    WHERE EXTRACT(DAY FROM p2.datetime - p1.datetime) = 1 AND EXTRACT(DAY FROM p3.datetime - p2.datetime) = 1
           AND EXTRACT(DAY FROM p3.datetime - p1.datetime) = 2;


















-- Your query that answers the question goes below the "insert into" line:
insert into q3
SELECT *
FROM ContiThree;