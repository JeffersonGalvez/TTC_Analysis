-- Data Processing, Cleaning and Validation

-- 4 tables imported using Data Import Wizard on MySQL workbench 
-- data scource: https://open.toronto.ca/catalogue/?topics=Transportation&owner_division=Toronto%20Transit%20Commission

-- loading database
USE ttc_sql_project;
-- previewing the 50 most recent records of each TTC delay table (see end for 4th table)
SELECT *
FROM bus_delay
ORDER BY Date DESC
LIMIT 50;

SELECT *
FROM streetcar_delay
ORDER BY Date DESC
LIMIT 50;

SELECT *
FROM subway_delay
ORDER BY Date DESC
LIMIT 50;

-- observing data types of each field in each table
DESCRIBE ttc_sql_project.bus_delay;
DESCRIBE ttc_sql_project.streetcar_delay;
DESCRIBE ttc_sql_project.subway_delay;

-- setting safe mode OFF in preparation for table modification
SET SQL_SAFE_UPDATES = 0;

-- re-formatting Date field format from dd-mm-yyy to yyyy-mm-dd in preparation for field data type conversion
-- https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_date-format
UPDATE bus_delay
SET Date = str_to_date(Date, "%e-%b-%y");

UPDATE streetcar_delay
SET Date = str_to_date(Date, "%e-%b-%y");
-- subway_delay table Date field already in correct format, but not as date data type

-- converting Date field from text data type to date data type
ALTER TABLE bus_delay
MODIFY Date DATE;

ALTER TABLE streetcar_delay
MODIFY Date DATE;


ALTER TABLE subway_delay
MODIFY Date DATE;

-- re-formatting Time field format from hh:mm to hh:mm:ss in preparation for field data type conversion
UPDATE bus_delay
SET Time = str_to_date(Time, "%T");

UPDATE streetcar_delay
SET Time = str_to_date(Time, "%T");

UPDATE subway_delay
SET Time = str_to_date(Time, "%T");

-- converting Time field from text data type to time data type
ALTER TABLE bus_delay
MODIFY Time TIME;

ALTER TABLE streetcar_delay
MODIFY Time TIME;

ALTER TABLE subway_delay
MODIFY Time TIME;

-- changing columns `Min Delay` and `Min Gap` to delay_minutes and gap_minutes, respectively for clairty and best practice
ALTER TABLE bus_delay 
RENAME COLUMN `Min Delay` TO delay_minutes;
ALTER TABLE bus_delay 
RENAME COLUMN `Min Gap` TO gap_minutes;

ALTER TABLE streetcar_delay 
RENAME COLUMN `Min Delay` TO delay_minutes;
ALTER TABLE streetcar_delay 
RENAME COLUMN `Min Gap` TO gap_minutes;

ALTER TABLE subway_delay 
RENAME COLUMN `Min Delay` TO delay_minutes;
ALTER TABLE subway_delay 
RENAME COLUMN `Min Gap` TO gap_minutes;

-- changing streetcar_delay and subway_delay column names to match bus_delay for consistency and possible future UNION/JOIN
ALTER TABLE streetcar_delay 
RENAME COLUMN Line TO Route;

ALTER TABLE streetcar_delay 
RENAME COLUMN Bound TO Direction;

ALTER TABLE subway_delay
RENAME COLUMN Bound TO Direction;

-- re-ordering columns into a more intuitive order
ALTER TABLE `ttc_sql_project`.`bus_delay` 
CHANGE COLUMN `Day` `Day` TEXT NULL DEFAULT NULL AFTER `Date`,
CHANGE COLUMN `Time` `Time` TIME NULL DEFAULT NULL AFTER `Day`,
CHANGE COLUMN `Vehicle` `Vehicle` INT NULL DEFAULT NULL AFTER `gap_minutes`;

ALTER TABLE `ttc_sql_project`.`streetcar_delay` 
CHANGE COLUMN `Day` `Day` TEXT NULL DEFAULT NULL AFTER `Date`,
CHANGE COLUMN `Time` `Time` TIME NULL DEFAULT NULL AFTER `Day`,
CHANGE COLUMN `Location` `Location` TEXT NULL DEFAULT NULL AFTER `gap_minutes`,
CHANGE COLUMN `Vehicle` `Vehicle` INT NULL DEFAULT NULL AFTER `Location`;

ALTER TABLE `ttc_sql_project`.`subway_delay` 
CHANGE COLUMN `Day` `Day` TEXT NULL DEFAULT NULL AFTER `Date`,
CHANGE COLUMN `Line` `Line` TEXT NULL DEFAULT NULL AFTER `Time`,
CHANGE COLUMN `Station` `Station` TEXT NULL DEFAULT NULL AFTER `gap_minutes`,
CHANGE COLUMN `Vehicle` `Vehicle` INT NULL DEFAULT NULL AFTER `Station`;

-- checking for blank values in field only where `0` is not a valid entry in the context of the field
SELECT * 
FROM bus_delay 
WHERE
    Time = '' OR
    Day = '' OR
    Location = '' OR
    Incident = '' OR
    Direction = '';

SELECT * 
FROM streetcar_delay 
WHERE
    Time = '' OR
    Day = '' OR
    Location = '' OR
    Incident = '' OR
    Bound = '';
    
SELECT * 
FROM subway_delay 
WHERE
    Time = '' OR
    Day = '' OR
    Station = '' OR
    Code = '' OR
    Bound = '' OR
    Line = '';

-- converting blank values into NULL
UPDATE bus_delay
SET Direction = NULL
WHERE Direction = '';

UPDATE streetcar_delay
SET Bound = NULL
WHERE Bound = '';

UPDATE subway_delay
SET Bound = NULL
WHERE Bound = '';
UPDATE subway_delay
SET Line = NULL
WHERE Line = '';

-- bus route number validation: no TTC bus routes < 7 and > 996 exist according to https://www.ttc.ca/routes-and-schedules#/listroutes/bus
-- oberving number of records with routes < 7 or > 996
SELECT COUNT(*) AS count_invalid_routes
FROM bus_delay
WHERE Route < 7 OR
	ROUTE > 996;

-- cleaning bus_delay table by deleting invalid route records
DELETE FROM bus_delay
WHERE Route < 7 OR
	Route > 996;
    
-- identifying unique Locations in bus_delay table
SELECT DISTINCT Location
FROM bus_delay
ORDER BY Location ASC;

-- correcting misspellings and typos
UPDATE bus_delay
SET Location = REPLACE(Location, '1035 SHEPPARD W', '1035 SHEPPARD AVE W')
	, Location = REPLACE(Location, 'AIRPORT TERMINAL #3', 'AIRPORT TERMINAL 3')
    , Location = REPLACE(Location, 'AIRPORT TERMINAL 3 RO', 'AIRPORT TERMINAL 3')
    , Location = REPLACE(Location, 'AITRPORT TERMINAL 3', 'AIRPORT TERMINAL 3')
    , Location = REPLACE(Location, 'ALBION AND ARMEL CT (A', 'ALBION AND ARMEL')
    , Location = REPLACE(Location, 'ALBION AND BANKFIELD-', 'ALBION AND BANKFIELD')
    , Location = REPLACE(Location, 'ALBION AND HWY 27', 'ALBION AND HIGHWAY 27')
    , Location = REPLACE(Location, 'ALBION AND WESTO RD', 'ALBION AND WESTMORE')
    , Location = REPLACE(Location, 'ALBION AND WESTON`', 'ALBION AND WESTON ROAD')
    , Location = REPLACE(Location, 'ALBOIN AND WESTON RD`', 'ALBION AND WESTON ROAD')
    , Location = REPLACE(Location, 'ALLEN AND RIM ROCK`', 'ALLEN AND RIMROCK');
    
-- streetcar_delay Route validation: there are only 13 TTC streetcar Route according to the TTC: https://www.ttc.ca/routes-and-schedules#/listroutes/streetcar
-- displaying streetcar Routes that don't exist 
SELECT *
FROM streetcar_delay
WHERE Route < 301 OR
	Route > 512 OR
    Route BETWEEN 302 and 303 OR
    Route BETWEEN 305 and 309 OR
    ROUTE = 502 OR
    Route BETWEEN 507 and 508
ORDER BY Route DESC;

-- cleaning streetcar_delay table by deleting invalid Route records
DELETE FROM streetcar_delay
WHERE Route < 301 OR
	Route > 512 OR
    Route BETWEEN 302 and 303 OR
    Route BETWEEN 305 and 309 OR
    ROUTE = 502 OR
    Route BETWEEN 507 and 508;
    
-- subway_delay Line validation: distinguishing variation in Line spellings
-- displaying each unique Line
SELECT DISTINCT Line
FROM subway_delay
ORDER BY Line ASC; -- 22 unique Lines, but there are only 4 TTC subway lines

-- cleaning subway_delay table by deleting invalid Line records
DELETE FROM subway_delay
WHERE Line = '506 CARLTON' OR
	Line = '57 MIDLAND' OR
    Line = '69 WARDEN SOUTH' OR
    Line = '96 WILSON' OR
    Line = 'LINE 2 SHUTTLE' OR
    Direction = 'B';

-- observing possibile Line spelling variations amongts similar Line names
SELECT Line
    , sum(case when Line = 'SHP' then 1 else 0 end) AS SHP_count
    , sum(case when Line = 'SRT' then 1 else 0 end) AS SRT_count
    , sum(case when Line = 'BD' then 1 else 0 end) AS BD_count
    , sum(case when Line = 'B/D' then 1 else 0 end) AS B_D_count
    , sum(case when Line = 'BD/YU' then 1 else 0 end) AS BD_YU_count
    , sum(case when Line = 'YU / BD' then 1 else 0 end) AS YU_BD_count
    , sum(case when Line = 'YU/ BD' then 1 else 0 end) AS YU_BD_count2
    , sum(case when Line = 'Y/BD' then 1 else 0 end) AS Y_BD_count
    , sum(case when Line = 'YU/BD LINES' then 1 else 0 end) AS YU_BD_count3
    , sum(case when Line = 'YU & BD' then 1 else 0 end) AS BDandYU_count
    , sum(case when Line = 'YU/ BD' then 1 else 0 end) AS YU_BD_count4
    , sum(case when Line = 'YU/BD' then 1 else 0 end) AS YU_BD_count5
    , sum(case when Line = 'YU/BD LINE' then 1 else 0 end) AS YU_BD_Line_count
    , sum(case when Line = 'YU/BD LINES' then 1 else 0 end) AS YU_BD_Lines_count
    , sum(case when Line = 'YUS' then 1 else 0 end) AS YUS_count
    , sum(case when Line = 'YUS AND BD' then 1 else 0 end) AS YUSandBD_count
    , sum(case when Line = 'YUS/BD' then 1 else 0 end) AS YUS_BD_count
FROM subway_delay
GROUP BY Line
ORDER BY Line ASC; 

-- summing together all BD/YU combination spelling varations
SELECT COUNT(*) AS BD_YU_variation
FROM subway_delay
WHERE Line = 'BD/YU' OR
	Line = 'YU / BD' OR
	Line = 'YU/ BD' OR
	Line = 'Y/BD' OR
	Line = 'YU/BD LINES' OR
	Line = 'YU & BD' OR
	Line = 'YU/ BD' OR
	Line = 'YU/BD' OR
	Line = 'YU/BD LINE' OR 
	Line = 'YU/BD LINES' OR
	Line = 'YUS' OR
	Line = 'YUS AND BD' OR
	Line = 'YUS/BD'; -- 308 total

-- YU = Yonge-University, BD = Bloor-Danforth, both are individual TTC subway lines (1 and 2 respectively)
-- indistinguishable which records are lines 1 and 2 specific
-- decided to update all BD/YU and other similar YU/BD Line spelling variations to 1/2
-- updating all Line spelling variations as well as other known lines into their numeric counterpart for consistency with TTC
UPDATE subway_delay 
SET Line = REPLACE(Line, 'BD/YU', '1/2')
	, Line = REPLACE(Line, 'Y/BD', '1/2')
    , Line = REPLACE(Line, 'YU / BD', '1/2')
    , Line = REPLACE(Line, 'YU & BD', '1/2')
    , Line = REPLACE(Line, 'YU/ BD', '1/2')
    , Line = REPLACE(Line, 'YU/BD LINE', '1/2')
    , Line = REPLACE(Line, 'YU/BD LINES', '1/2')
    , Line = REPLACE(Line, 'YUS AND BD', '1/2')
    , Line = REPLACE(Line, 'YUS/BD', '1/2')
    , Line = REPLACE(Line, 'YU/BDS', '1/2')
    , Line = REPLACE(Line, 'YUS', '1')
    , Line = REPLACE(Line, 'B/D', '2')
    , Line = REPLACE(Line, 'BD', '2')
	, Line = REPLACE(Line, 'YU', '1')
    , Line = REPLACE(Line, 'SHP', '4')
    , Line = REPLACE(Line, 'SRT', '3');

-- observing non TTC delay table; contains corresponding descriptions for subway_delay codes    
SELECT *
FROM delay_codes_subway;

-- imported only 2 fields: subway code and code description
-- Table Data Import Wizard did not recorgnize the field headers, therefor it was altered here
ALTER TABLE `ttc_sql_project`.`delay_codes_subway` 
CHANGE COLUMN `MyUnknownColumn_[1]` `Code` TEXT NULL DEFAULT NULL,
CHANGE COLUMN `MyUnknownColumn_[2]` `code_description`  TEXT NULL DEFAULT NULL;

-- deleting none code or description rows
DELETE FROM delay_codes_subway
WHERE `SUB RMENU CODE` = 'SUB RMENU CODE' OR
	`CODE DESCRIPTION` = 'CODE DESCRIPTION';
    
-- imported ttc_routes table from above URL, via Import Wizard (MySQL)
-- only select columns imported (route_short_name, route_long_name and route_type)
SELECT *
FROM ttc_routes;

-- altering and updating route_type field from integers into text for ease of understanding
ALTER TABLE `ttc_sql_project`.`ttc_routes` 
CHANGE COLUMN `route_type` `route_type` TEXT NULL DEFAULT NULL ;

UPDATE ttc_routes
SET route_type = REPLACE(route_type, 1, 'Subway')
	, route_type = REPLACE(route_type, 0, 'Streetcar')
    , route_type = REPLACE(route_type, 3, 'Bus');
    
-- altering route_short_name to just Route to be consistent with other tables
ALTER TABLE `ttc_sql_project`.`ttc_routes` 
CHANGE COLUMN `route_short_name` `Route` INT NULL DEFAULT NULL;

-- inner joining bus_delay and ttc_routes tables to return only valid/existing bus routes
SELECT *
FROM bus_delay
INNER JOIN ttc_routes
	ON bus_delay.Route = ttc_routes.route_short_name;

-- counting the number of unique bus routes matched from INNER JOIN above    
SELECT COUNT(DISTINCT bus_delay.Route) AS distinct_bus_route_joined
FROM bus_delay
INNER JOIN ttc_routes
	ON bus_delay.Route = ttc_routes.route_short_name;
-- 195 unique TTC bus routes counted after INNER JOIN
-- this is not valid as there are only 191 official TTC bus routes as demonstrted below:
SELECT COUNT(*) AS count_bus_routes
FROM ttc_routes
WHERE route_type = 'Bus';

-- this table was exported for validation (route_joins.csv)
SELECT bus_delay.Route
	, ttc_routes.route_short_name
FROM bus_delay
INNER JOIN ttc_routes
	ON bus_delay.Route = ttc_routes.route_short_name
GROUP BY bus_delay.Route
	, ttc_routes.route_short_name 
ORDER BY bus_delay.Route ASC
	, ttc_routes.route_short_name ASC;
    
-- this table was also exported for validation with above (route_short_name.csv)
SELECT route_short_name
FROM ttc_routes
WHERE route_type = 'Bus'
ORDER BY route_short_name ASC;

-- the 2 expoerted tables/.csv's were combined (widthwise) to creat a new table with 3 columns: route_short_name (route_short_name.csv), Route and route_short_name (last 2 both from route_joins.csv)
-- it was identified that 10 streetcar rows were joined, but 6 bus rows were not
-- 10 - 6 = 4, thus explaining the difference of 4 in the 195 joined rows vs 191 legitamate and valid bus routes
-- streetcar routes within bus_delay table: 301, 306, 501, 503 - 506, 509, 510, 512
-- 6 none recorded bus routes within bus_delay table: 400, 402 - 405
-- please see bus_joins_validation.csv under this same repository the validation performed here between lines 325 - 357

-- cleaning bus_delay table by deleting the 10 streetcar rows
DELETE FROM bus_delay
WHERE Route = 301
	OR Route = 306
    OR Route = 501
    OR Route BETWEEN 503 AND 506
    OR Route BETWEEN 509 AND 510
    OR Route = 512;

-- verifying bus routes
SELECT DISTINCT Route
FROM bus_delay
ORDER BY Route ASC; -- observed 209 rows returned accompanied by some invalid routes

-- creating a new table of validated bus delay data
CREATE TABLE ttc_sql_project.bus_delay_valid AS
	(
	SELECT bus_delay.Date
		, bus_delay.Day
		, bus_delay.Time
		, bus_delay.Route
		, bus_delay.Location
		, bus_delay.Incident
		, bus_delay.delay_minutes
		, bus_delay.gap_minutes
		, bus_delay.Vehicle
		, bus_delay.Direction
	FROM bus_delay
	INNER JOIN ttc_routes
		ON bus_delay.Route = ttc_routes.route_short_name
	WHERE ttc_routes.route_type = 'Bus'
	);
    
-- counting the number of unique streetcar routes matched via INNER JOIN
SELECT COUNT(DISTINCT streetcar_delay.Route) AS distinct_streetcar_route_joined
FROM streetcar_delay
INNER JOIN ttc_routes
	ON streetcar_delay.Route = ttc_routes.route_short_name;
-- only 12 streetcar routes returned

-- counting total number of streetcar routes in streetcar_delay
SELECT COUNT(DISTINCT Route) AS distinct_streetcar_route
FROM streetcar_delay;
-- returned 13 total TTC streetcar routes, which is confirmed via TTC website

-- creating a new table of validated streetcar delay data
CREATE TABLE ttc_sql_project.streetcar_delay_valid AS
	(
	SELECT streetcar_delay.Date
		, streetcar_delay.Day
		, streetcar_delay.Time
		, streetcar_delay.Route
		, streetcar_delay.Incident
		, streetcar_delay.delay_minutes
		, streetcar_delay.gap_minutes
		, streetcar_delay.Location
		, streetcar_delay.Vehicle
		, streetcar_delay.Direction
	FROM streetcar_delay
	INNER JOIN ttc_routes
		ON streetcar_delay.Route = ttc_routes.route_short_name
	WHERE ttc_routes.route_type = 'Streetcar'
    );