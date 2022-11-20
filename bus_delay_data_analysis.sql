-- Data Exploration and Analysis

-- loading database
USE ttc_sql_project;

-- tables to analyze
SELECT *
FROM bus_delay
LIMIT 500;

-- How many different routes are in my bus_delay df?
SELECT COUNT(DISTINCT Route) AS distinct_count_route
FROM bus_delay;

-- Which bus route is most prone to delays?
SELECT Route
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY Route
ORDER BY count_incident DESC
LIMIT 1;

-- What are the most common forms/causes of bus delay, in descending order?
SELECT Incident
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY Incident
ORDER BY count_incident DESC;

-- What are each bus route's most common form of delay?
SELECT Route
	, Incident
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY Incident
	, Route
ORDER BY count_incident DESC;

-- Which month has the most bus delays, in descending order?
SELECT MONTHNAME(Date)
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_incident DESC;

-- What hour of the day are bus delays most likely to occur? By number of delays
SELECT HOUR(Time)
	, COUNT(Incident) AS count_incident
FROM bus_delay
GROUP BY HOUR(Time);

-- What is the average bus delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM bus_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;

-- What is the average bus delay and the average scheduled gap in minutes, by route?
SELECT Route
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
FROM bus_delay
GROUP BY Route
ORDER BY avg_delay_minutes DESC;

-- Which vehicle has the most 'Mechanical' bus delays?
SELECT DISTINCT Vehicle
	, COUNT(Incident) AS count_mechanical_incident
FROM bus_delay
WHERE Incident = 'Mechanical'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;