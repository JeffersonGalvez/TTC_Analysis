-- 3 tables imported using Data Import Wizard on MySQL workbench 
-- data scource: https://open.toronto.ca/catalogue/?topics=Transportation&owner_division=Toronto%20Transit%20Commission

-- loading database
USE ttc_sql_project;

-- Data Processing and Cleaning
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