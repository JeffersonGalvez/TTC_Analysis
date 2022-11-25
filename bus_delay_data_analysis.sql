-- TTC Bus delays data explorationa and analysis
-- loading database
USE ttc_sql_project;

-- what is the date range of this data frame (df)?
SELECT MIN(Date) AS earlieast_date 
	, MAX(Date) AS latest_date
FROM bus_delay;
-- df spans fron 01 Jan 2022 to 30 Sep 2022

-- How many different routes are in the bus_delay df?
SELECT COUNT(DISTINCT Route) AS distinct_count_route
FROM bus_delay; 
-- 219 unique bus routes

-- which bus route is most prone to delays?
SELECT Route
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY Route
ORDER BY count_incident DESC
LIMIT 1;
-- route 36 had the most delays at 1 473 

-- what are the different forms/causes of bus delay, in descending order?
SELECT Incident
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY Incident
ORDER BY count_incident DESC;
-- 'Operations - Operator' was the most common for of delay, at 15 929,
-- followed by 'Mechanical' at 12 242 and 'Collision - TTC' at 2 472

-- what percentage of all bus delays are due to the top 3 causes?
SELECT (SUM(Incident = 'Operations - Operator')/COUNT(*)) * 100 AS percent_operations
	, (SUM(Incident = 'Mechanical')/COUNT(*)) * 100 AS percent_mechanical
    , (SUM(Incident = 'Collision - TTC')/COUNT(*)) * 100 AS percent_collision
FROM bus_delay;
-- 'Operations - Operator' = 36.6%, 'Mechanical' = 28.1% and 'Collision - TTC' = 5.7%

-- what are each bus routes most common form of delay?
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
  FROM bus_delay
  GROUP BY Route
	, Incident
	) T
WHERE rn=1;
-- the resulting information of this query is best displayed when visualized

-- which month has the most bus delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_incident DESC;
-- August is the most bus delay-prone month at 6 001 and February is the least at 3 885

-- what percentage of bus delays occurred within August, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'August')/COUNT(*)) * 100 AS percent_Aug_delays
FROM bus_delay;
-- August accounted for 13.8% of all bus delays 

-- what hour of the day are bus delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY HOUR(Time)
ORDER BY count_incident DESC;
-- 15:00 and 16:00 hold the most bus delays at 3 329 and 3 269, respectively

-- what is the average bus delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM bus_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;
-- Sun = 22.0 min, Sat = 21.2 min, Wed = 19.6 min, Mon = 19.6 min, Fri = 18.7 min, Thu = 18.5 and Tue = 17.6 min

-- what is the average bus delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
-- what effect do the delays have on on the sceduled number of buses?
SELECT Route
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_minutes
    , ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1) AS scheduled_no_12h
    , ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1) AS effective_no_12h
    , (ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1)) - (ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1)) AS loss_no_buses
FROM bus_delay
GROUP BY Route
ORDER BY loss_no_buses DESC;
-- route 306 has the largest delay-to-gap difference at 30 min, with an average delay of 30 min and a scheduled delay of 60 min
-- this means that in a 12 h period, route 306 is effectively delivering 8 buses rather than the scheduled 12, an effective loss of 4 scheduled runs
-- however, route 600 has the greatest overall number of effective loss of 47.4 scheduled runs in a 12 h period

-- which vehicle has the most 'Mechanical' bus delays?
SELECT DISTINCT Vehicle
	, COUNT(Incident) AS count_mechanical_incident
FROM bus_delay
WHERE Incident = 'Mechanical'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;
-- assuming bus (vehicle) no. 0 is real, it has experienced the most mechanical-related elays of 41
-- followed by bus (vehcile) no. 9037 at 24 