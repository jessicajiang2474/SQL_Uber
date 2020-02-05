DROP SCHEMA IF EXISTS uber cascade;
CREATE SCHEMA uber;
SET search_path TO uber, public;

-- A person who is registered as a client of the company's driving services.
CREATE TABLE Client (
  client_id integer PRIMARY KEY,
  surname varchar(25) NOT NULL,
  firstname varchar(15) NOT NULL,
  email varchar(30)
) ;

-- A driver for the company.  dob is their date of birth.
-- Trained indicates whether or not they attended the optional new-driver 
-- training.  vehicle is the vehicle that this driver gives rides in.
-- A driver can have only one vehicle associated with them.
CREATE TABLE Driver (
  driver_id integer PRIMARY KEY,
  surname varchar(25) NOT NULL,
  firstname varchar(15) NOT NULL,
  dob date,
  address varchar NOT NULL,
  vehicle varchar(8) NOT NULL,
  trained boolean default false
) ;

-- The name, such as 'Pearson Airport', associated with a location.
CREATE TABLE Place (
   name varchar(30) PRIMARY KEY,
   location point NOT NULL
) ;

-- A row in this table indicates that a driver has indicated at
-- this time that they are available to pick up a user.
CREATE TABLE Available (
  driver_id integer NOT NULL REFERENCES Driver,
  datetime timestamp,
  location point,
  PRIMARY KEY (driver_id, datetime)
) ;


-- Requests for a ride, and associated events

-- A request for a ride.  source is where the client wants to be
-- picked up from, and destination is where they want to be driven to.
CREATE TABLE Request (
  request_id integer PRIMARY KEY,
  client_id integer NOT NULL REFERENCES Client,
  datetime timestamp NOT NULL,
  source varchar(30) NOT NULL References Place(name),
  destination varchar(30) NOT NULL References Place(name)
) ;

-- A row in this table indicates that a driver was dispatched to
-- pick up a client, in response to their request.  car_location is where
-- their car was at the time when the driver was dispatched.
CREATE TABLE Dispatch (
  request_id integer PRIMARY KEY REFERENCES Request,
  driver_id integer NOT NULL REFERENCES Driver,
  car_location point,
  datetime timestamp
) ;

-- A row in this table indicates that the client who made this request was
-- picked up at this time.
CREATE TABLE Pickup (
  request_id integer PRIMARY KEY NOT NULL REFERENCES Dispatch,
  datetime timestamp NOT NULL
) ;

-- A row in this table indicates that the client who made this request was
-- dropped off at this time.
CREATE TABLE Dropoff (
  request_id integer PRIMARY KEY NOT NULL REFERENCES Pickup,
  datetime timestamp NOT NULL
) ;


-- To do with money

-- This table must have a single row indicating the current rates.
-- base is the cost for being picked up, and per_mile is the additional 
-- cost for every mile travelled.
CREATE TABLE Rates (
  base real NOT NULL,
  per_mile real NOT NULL
);

-- This client associated with this request was billed this amount for the 
-- ride.
CREATE TABLE Billed (
  request_id integer PRIMARY KEY REFERENCES Dropoff,
  amount real NOT NULL
) ;


-- To do with Ratings

-- The possible values of a rating.
CREATE DOMAIN score AS smallint 
   DEFAULT NULL
   CHECK (VALUE >= 1 AND VALUE <= 5);

-- The driver who gave the ride associated with this dropoff
-- was given this rating by the client who had the ride.
CREATE TABLE DriverRating (
   request_id integer PRIMARY KEY REFERENCES Dropoff,
   rating score NOT NULL
) ;

-- The client who had the ride associated with this dropoff
-- was given this rating by the driver who gave the ride.
CREATE TABLE ClientRating (
   request_id integer PRIMARY KEY REFERENCES Dropoff,
   rating score NOT NULL
) ;