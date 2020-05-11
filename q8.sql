-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
drop table if exists q8 cascade;

create table q8(
  client_id INTEGER,
reciprocals INTEGER,
difference FLOAT
);


DROP VIEW IF EXISTS compRequest CASCADE;
-- all the completed ride
CREATE VIEW compReq AS
  ( SELECT request_id FROM Request ) INTERSECT (SELECT request_id FROM DropOff);


DROP VIEW IF EXISTS compSep CASCADE;
-- all the completed ride and year and month
CREATE VIEW compSep AS
  SELECT r.client_id,c.request_id
  FROM  Request r, compReq c
  WHERE r.request_id = c.request_id;


DROP VIEW IF EXISTS recipR CASCADE;
-- all reciprocal ride and the ratings
CREATE VIEW recipR AS
    SELECT d.request_id, d.rating as driverrate, c.rating as clientrate , d.rating - c.rating as difference
    FROM DriverRating d, ClientRating c
    WHERE d.request_id = c.request_id;




DROP VIEW IF EXISTS answer CASCADE;
-- all reciprocal ride and the ratings difference
CREATE VIEW answer AS
    SELECT client_id, count(c.request_id) as reciprocals ,avg(difference) as difference
    FROM compSep c,recipR r
    WHERE c.request_id = r.request_id
    GROUP BY client_id;

insert into q8
 select * from answer;
