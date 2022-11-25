-- TTC Streetcar delays data exploration and analysis
-- loading database
USE ttc_sql_project;

-- what is the date range of this data frame (df)?
SELECT MIN(Date) AS earlieast_date 
	, MAX(Date) AS latest_date
FROM streetcar_delay;
-- df spans fron 01 Jan 2022 to 30 Sep 2022

-- how many different streetcar routes are in the streetcar_delay df?
SELECT COUNT(DISTINCT Route) AS distinct_count_route
FROM streetcar_delay;
-- there are a total of 13 unique streetcars

-- what are the different causes of streetcar delays (in descending order of occurance)?
SELECT Incident
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY Incident
ORDER BY count_incident DESC;
-- 'Operation' is the most common form of streetcar delay at 6 556, assumption: similar to 'Operations - Operator' delay in bus_delay df
-- 'Mechanical' is the second most common form at 1 282 and 'General Delay' at 1 080

-- what percentage of all bus delays are due to the top 3 causes?
SELECT (SUM(Incident = 'Operations')/COUNT(*)) * 100 AS percent_operations
	, (SUM(Incident = 'Mechanical')/COUNT(*)) * 100 AS percent_mechanical
    , (SUM(Incident = 'General Delay')/COUNT(*)) * 100 AS percent_general_delay
FROM streetcar_delay;
-- 'Operations' = 47.2%, 'Mechanical' = 9.2% and 'General Delay' = 7.8%

-- which streetcar route is most prone to delays?
SELECT Route
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY Route
ORDER BY count_incident DESC
LIMIT 1;
-- route 501 has experienced the most delays at 3 803

-- what are each streetcar routes most common form of delay?
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
-- the resulting information of this query is best displayed when visualized

-- which month has the most streetcar delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_incident DESC;
-- January saw the most streetcar delays at 2 179 and August experienced the least as 1 172

-- what percentage of streetcar delays occurred within January, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'January')/COUNT(*)) * 100 AS percent_Jan_delays
FROM bus_delay;
-- January holds 13.3% of all streetcar delays

-- what hour of the day are streetcar delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Incident) AS count_incident
FROM streetcar_delay
GROUP BY HOUR(Time)
ORDER BY count_incident DESC;
-- 13:00 and 16:00 are the most streetcar delay-prone hours at 993 and 981, respectively

-- what is the average streetcar delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM streetcar_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;
-- Sun = 16.4 min, Sat = 14.6 min, Mon = 14.3 min, Fri = 13.4 min, Thu = 13.1, Wed = 13.0 min and Tue = 12.1 

-- what is the average streetcar delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
-- what effect do the delays have on on the sceduled number of streetcars?
SELECT Route
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_minutes
    , ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1) AS scheduled_no_12h
    , ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1) AS effective_no_12h
    , (ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1)) - (ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1)) AS loss_no_streetcars
FROM streetcar_delay
GROUP BY Route
ORDER BY loss_no_streetcars DESC;
-- route 310 has the largest delay-to-gap difference at 21.0 min, with an average delay of 30.8 min and average scheduled gap of 51.8 min
-- this means that in a 12 h period, route 310 is effectively delivering 8.7 streetcars rather than the scheduled 13.9, an effective loss of 5.2 scheduled runs
-- however, route 504 has the greatest overall number of effective loss of 16.7 scheduled runs in a 12 h period

-- which streetcar has the most 'Mechanical' delay?
SELECT DISTINCT Vehicle
	, COUNT(Incident) AS count_mechanical_incident
FROM streetcar_delay
WHERE Incident = 'Mechanical'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;
-- assuming streetcar (vheicle) no. 0 is real, it has the most mechanical-related delays at 18
-- followed by streetcar (vheicle) no. 4592 at 10