-- TTC Bus delays data explorationa and analysis
-- loading database
USE ttc_sql_project;

-- what is the date range of this data frame (table)?
SELECT MIN(Date) AS earlieast_date 
	, MAX(Date) AS latest_date
FROM bus_delay_valid;
-- table spans fron 01 Jan 2022 to 30 Sep 2022

-- what are the different causes of bus delays, in descending order?
SELECT Incident
	, COUNT(Incident) AS count_incident
FROM bus_delay_valid
GROUP BY Incident
ORDER BY count_incident DESC;
-- 1) 'Operations - Operator' = 15827, 2) 'Mechanical' = 12191, 3) 'Collision - TTC' = 2421, 4) 'Utilized Off Route' = 2317, 5) 'Security' = 2255
-- 6) 'General Delay' = 2007, 7) 'Diversion' = 1801, 8) 'Emergency Services' = 1614, 9) 'Cleaning - Unsanitary' = 1051, 10) 'Investigation' = 624

-- what is the percentage of all bus delay causes?
SELECT (SUM(Incident = 'Operations - Operator')/COUNT(*)) * 100 AS percent_operations
	, (SUM(Incident = 'Mechanical')/COUNT(*)) * 100 AS percent_mechanical
    , (SUM(Incident = 'Collision - TTC')/COUNT(*)) * 100 AS percent_collision
    , (SUM(Incident = 'Utilized Off Route')/COUNT(*)) * 100 AS percent_off_route
    , (SUM(Incident = 'Security')/COUNT(*)) * 100 AS percent_security
    , (SUM(Incident = 'General Delay')/COUNT(*)) * 100 AS percent_general_delay
    , (SUM(Incident = 'Diversion')/COUNT(*)) * 100 AS percent_diversion
    , (SUM(Incident = 'Emergency Services')/COUNT(*)) * 100 AS percent_emergency
    , (SUM(Incident = 'Cleaning - Unsanitary')/COUNT(*)) * 100 AS percent_cleaning
    , (SUM(Incident = 'Investigation')/COUNT(*)) * 100 AS percent_investigation
    , ((SUM(Incident = 'Vision') + 
		SUM(Incident = 'Held By') + 
		SUM(Incident = 'Road Blocked - NON-TTC Collision') + 
        SUM(Incident = 'Late Entering Service') + 
        SUM(Incident = 'Cleaning - Disinfection')) / COUNT(*)) * 100 AS percent_other
FROM bus_delay_valid;
-- results best displayed as visual

-- How many different routes are in the bus_delay_valid table?
SELECT COUNT(DISTINCT Route) AS distinct_count_route
FROM bus_delay_valid; 
-- 185 unique bus routes

-- which bus route is most prone to delays?
SELECT Route
	, COUNT(Incident) AS count_incident
FROM bus_delay_valid
GROUP BY Route
ORDER BY count_incident DESC
LIMIT 5;
-- route 36 had the most delays at 1 473

-- which month has the most bus delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Incident) AS count_bus_incident
FROM bus_delay_valid
GROUP BY MONTHNAME(Date)
ORDER BY count_bus_incident DESC;
-- August is the most bus delay-prone month at 5937 and February is the least at 3854

-- what percentage of bus delays occurred within August, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'August')/COUNT(*)) * 100 AS percent_Aug_delays
FROM bus_delay_valid;
-- August accounted for 13.7% of all bus delays 

-- what is the average bus delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM bus_delay_valid
GROUP BY Day
ORDER BY avg_delay_minutes DESC;
-- Sun = 22.1 min, Sat = 21.2 min, Wed = 19.8 min, Mon = 19.7 min, Fri = 18.7 min, Thu = 18.5 and Tue = 17.6 min

-- what hour of the day are bus delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Incident) AS count_bus_incident
FROM bus_delay_valid
GROUP BY HOUR(Time)
ORDER BY hour_of_day ASC;
-- 15:00 and 16:00 are the most streetcar delay-prone hours at 3300 and 3241, respectively

-- what is the average bus delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
-- what effect do the delays have on on the sceduled number of buses?
SELECT Route
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_minutes
    , ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1) AS target_12h
    , ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1) AS actual_12h
    , (ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1)) - (ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1)) AS loss_num_buses
FROM bus_delay_valid
GROUP BY Route
ORDER BY loss_num_buses DESC;
-- route 324 has the largest delay-to-gap (delay_gap_minutes) difference at 29.4 min, with an average delay of 36 min and a scheduled delay of 65.4 min
-- this means that in a 12 h period, route 324 is effectively delivering 7.1 buses rather than the scheduled 11, an effective loss of 4 scheduled bus runs
-- however, route 320 has the greatest overall number of effective lost bus runs (loss_num_bus) of 17.9; 41.9 scheduled runs per 12 h

-- what are most cause of delays for the bus routes which have the highest loss of service (in 12h)?
SELECT Route
	, Incident
FROM
	(
  SELECT Route
	, Incident 
    , DENSE_RANK() OVER 
		(
		PARTITION BY Route -- DENSE_RANK() used over ROW_NUMBER() to display any ties of incident count per route
		ORDER BY COUNT(*) DESC
        ) rn
  FROM bus_delay_valid
  GROUP BY Route
	, Incident
	) T
WHERE rn=1
	AND (Route = 36
    OR Route = 100
    OR Route = 320
    OR Route = 944
    OR Route = 954);
-- all routes main cause of delay is Operations - Operator, except for route 944 which is mechanical

-- which vehicle has the most 'Mechanical' bus delays?
SELECT DISTINCT Vehicle
	, COUNT(Incident) AS count_mechanical_incident
FROM bus_delay_valid
WHERE Incident = 'Mechanical'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;
-- assuming bus (vehicle) no. 0 is real, it has experienced the most mechanical-related elays of 41
-- followed by bus (vehcile) no. 9037 at 24 

-- which bus location (station) has the most records of delays, in descending order?
SELECT Location
	, COUNT(Location) AS count_location
FROM bus_delay_valid
GROUP BY Location
ORDER BY count_location DESC;
-- Kennedy station has the highest record of bus delays at 1029