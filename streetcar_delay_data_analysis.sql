-- TTC Streetcar delays data exploration and analysis
-- loading database
USE ttc_sql_project;

-- what is the date range of this data frame (table)?
SELECT MIN(Date) AS earlieast_date 
	, MAX(Date) AS latest_date
FROM streetcar_delay_valid;
-- table spans fron 01 Jan 2022 to 30 Sep 2022

-- what are the top 10 of streetcar delays (in descending order of occurance)?
SELECT Incident
	, COUNT(Incident) AS count_incident
FROM streetcar_delay_valid
GROUP BY Incident
ORDER BY count_incident DESC;
-- 1) 'Operation' = 6548, 2) 'Mechanical' = 1280, 3) 'General Delay' = 1078, 4) 'Security' = 931, 5) 'Held By' = 864
-- 6) 'Emergency Services' = 812, 7) 'Cleaning - Unsanitary' = 676, 8) 'Diversion' = 548, 9) 'Utilized Off Route' = 447, 10) 'Collision - TTC Involved' = 406

-- what is the percentage of all streetcar delay causes?
SELECT (SUM(Incident = 'Operations')/COUNT(*)) * 100 AS percent_operations
	, (SUM(Incident = 'Mechanical')/COUNT(*)) * 100 AS percent_mechanical
    , (SUM(Incident = 'General Delay')/COUNT(*)) * 100 AS percent_general_delay
    , (SUM(Incident = 'Security')/COUNT(*)) * 100 AS percent_security
    , (SUM(Incident = 'Held By')/COUNT(*)) * 100 AS percent_held_by
    , (SUM(Incident = 'Emergency Services')/COUNT(*)) * 100 AS percent_emergency
    , (SUM(Incident = 'Cleaning - Unsanitary')/COUNT(*)) * 100 AS percent_cleaning
    , (SUM(Incident = 'Diversion')/COUNT(*)) * 100 AS percent_diversion
    , (SUM(Incident = 'Utilized Off Route')/COUNT(*)) * 100 AS percent_off_route
    , (SUM(Incident = 'Collision - TTC Involved')/COUNT(*)) * 100 AS percent_collision
    , ((SUM(Incident = 'Investigation') + 
		SUM(Incident = 'Overhead') + 
		SUM(Incident = 'Late Entering Service') + 
        SUM(Incident = 'Rail/Switches') + 
        SUM(Incident = 'Cleaning - Disinfection')) / COUNT(*)) * 100 AS percent_other
FROM streetcar_delay_valid;
-- results best displayed as visual

-- how many different streetcar routes are in the streetcar_delay_valid table?
SELECT COUNT(DISTINCT Route) AS distinct_count_route
FROM streetcar_delay_valid;
-- there are a total of 12 unique streetcars

-- which streetcar route is most prone to delays?
SELECT Route
	, COUNT(Incident) AS count_incident
FROM streetcar_delay_valid
GROUP BY Route
ORDER BY count_incident DESC
LIMIT 5;
-- route 501 has experienced the most delays at 3803

-- which month has the most streetcar delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Incident) AS count_streetcar_incident
FROM streetcar_delay_valid
GROUP BY MONTHNAME(Date)
ORDER BY count_streetcar_incident DESC;
-- January saw the most streetcar delays at 2179 and August experienced the least as 1755

-- what percentage of streetcar delays occurred within January, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'January')/COUNT(*)) * 100 AS percent_Jan_delays
FROM bus_delay;
-- January holds 13.3% of all streetcar delays

-- what is the average streetcar delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM streetcar_delay_valid
GROUP BY Day
ORDER BY avg_delay_minutes DESC;
-- Sun = 16.4 min, Sat = 14.6 min, Mon = 14.3 min, Fri = 13.4 min, Thu = 13.1, Wed = 13.0 min and Tue = 12.1 

-- what hour of the day are streetcar delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Incident) AS count_streetcar_incident
FROM streetcar_delay_valid
GROUP BY HOUR(Time)
ORDER BY hour_of_day ASC;
-- 13:00 and 16:00 are the most streetcar delay-prone hours at 992 and 980, respectively

-- what is the average streetcar delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
-- what effect do the delays have on on the sceduled number of streetcars?
SELECT Route
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_minutes
    , ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1) AS target_streetcar_12h
    , ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1) AS actual_streetcar_12h
    , (ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1)) - (ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1)) AS loss_num_streetcars
FROM streetcar_delay_valid
GROUP BY Route
ORDER BY loss_num_streetcars DESC;
-- route 310 has the largest delay-to-gap difference at 21.0 min, with an average delay of 30.8 min and average scheduled gap of 51.8 min
-- this means that in a 12 h period, route 310 is effectively delivering 8.7 streetcars rather than the scheduled 13.9, an effective loss of 5.2 scheduled runs
-- however, route 504 has the greatest overall number of effective loss of 16.7 scheduled runs in a 12 h period

-- what are most cause of delays for the streetcar routes which have the highest loss of service (in 12h)?
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
  FROM streetcar_delay_valid
  GROUP BY Route
	, Incident
	) T
WHERE rn=1
	AND (Route = 512
    OR Route = 504
    OR Route = 511
    OR Route = 509
    OR Route = 510);
-- all are due to Operations type delay

-- which streetcar has the most 'Mechanical' delay?
SELECT DISTINCT Vehicle
	, COUNT(Incident) AS count_mechanical_incident
FROM streetcar_delay_valid
WHERE Incident = 'Mechanical'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;
-- assuming streetcar (vheicle) no. 0 is real, it has the most mechanical-related delays at 18
-- followed by streetcar (vheicle) no. 4592 at 10