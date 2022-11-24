-- TTC Streetcar delays data exploration and analysis
-- loading database
USE ttc_sql_project;

-- tables to analyze
SELECT *
FROM streetcar_delay
LIMIT 500;

-- How many different streetcar routes are in the streetcar_delay df?
SELECT COUNT(DISTINCT Route) AS distinct_count_route
FROM streetcar_delay;

-- What are the different causes of streetcar delays (in descending order of occurance)?
SELECT Incident
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY Incident
ORDER BY count_incident DESC;

-- What percentage of all bus delays are due to the top 3 causes?
SELECT (SUM(Incident = 'Operations')/COUNT(*)) * 100 AS percent_operations
	, (SUM(Incident = 'Mechanical')/COUNT(*)) * 100 AS percent_mechanical
    , (SUM(Incident = 'General Delay')/COUNT(*)) * 100 AS percent_collision
FROM streetcar_delay;

-- Which streetcar route is most prone to delays?
SELECT Route
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY Route
ORDER BY count_incident DESC
LIMIT 1;

-- What are each streetcar routes most common form of delay?
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
  FROM streetcar_delay
  GROUP BY Route
	, Incident
	) T
WHERE rn=1;

-- which month has the most streetcar delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_incident DESC;

-- what percentage of streetcar delays occurred within January, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'January')/COUNT(*)) * 100 AS percent_Jan_delays
FROM bus_delay;

-- what hour of the day are streetcar delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY HOUR(Time)
ORDER BY count_incident DESC;

-- what is the average streetcar delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM streetcar_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;

-- what is the average streetcar delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
SELECT Route
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_difference
FROM streetcar_delay
GROUP BY Route
ORDER BY delay_gap_difference DESC;

-- which streetcar has the most 'Mechanical' delay?
SELECT DISTINCT Vehicle
	, COUNT(Incident) AS count_mechanical_incident
FROM streetcar_delay
WHERE Incident = 'Mechanical'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;