-- Data Processing, Cleaning and Validation

-- 3 tables imported using Data Import Wizard on MySQL workbench 
-- data scource: https://open.toronto.ca/catalogue/?topics=Transportation&owner_division=Toronto%20Transit%20Commission

-- loading database
USE ttc_sql_project;
-- previewing the 50 most recent records of each df
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

-- observing data types of each field in each df
DESCRIBE ttc_sql_project.bus_delay;
DESCRIBE ttc_sql_project.streetcar_delay;
DESCRIBE ttc_sql_project.subway_delay;

-- setting safe mode OFF in preparation for df modification
SET SQL_SAFE_UPDATES = 0;

-- re-formatting Date field format from dd-mm-yyy to yyyy-mm-dd in preparation for field data type conversion
-- https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html#function_date-format
UPDATE bus_delay
SET Date = str_to_date(Date, "%e-%b-%y");

UPDATE streetcar_delay
SET Date = str_to_date(Date, "%e-%b-%y");
-- subway_delay df Date field already in correct format, but not as date data type

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

-- cleaning bus_delay df by deleting invalid route records
DELETE FROM bus_delay
WHERE Route < 7 OR
	Route > 996;
    
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

-- cleaning streetcar_delay df by deleting invalid Route records
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

-- cleaning subway_delay df by deleting invalid Line records
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

-- YU = Yonge-University, BD = Bloor-Danforth, both are individual TTC subway lines
-- indistinguishable which records are YU and BD specific 
-- decided to update all BD/YU and other similar YU/BD Line spelling variations to YU/BD
-- updating all Line spelling variations
UPDATE subway_delay 
SET Line = REPLACE(Line, 'BD/YU', 'YU/BD')
	, Line = REPLACE(Line, 'Y/BD', 'YU/BD')
    , Line = REPLACE(Line, 'YU / BD', 'YU/BD')
    , Line = REPLACE(Line, 'YU & BD', 'YU/BD')
    , Line = REPLACE(Line, 'YU/ BD', 'YU/BD')
    , Line = REPLACE(Line, 'YU/BD LINE', 'YU/BD')
    , Line = REPLACE(Line, 'YU/BD LINES', 'YU/BD')
    , Line = REPLACE(Line, 'YUS AND BD', 'YU/BD')
    , Line = REPLACE(Line, 'YUS/BD', 'YU/BD')
    , Line = REPLACE(Line, 'YU/BDS', 'YU/BD')
    , Line = REPLACE(Line, 'YUS', 'YU')
    , Line = REPLACE(Line, 'B/D', 'BD');