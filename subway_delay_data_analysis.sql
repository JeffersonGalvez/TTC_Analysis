-- TTC subway delays data exploration and analysis
-- loading database
USE ttc_sql_project;

-- tables to analyze
SELECT *
FROM subway_delay
LIMIT 500;

-- How many different subway routes are in the subway_delay df?
SELECT COUNT(DISTINCT Line) AS distinct_count_route
FROM subway_delay;

-- What are the different causes of subway delays (in descending order of occurance)?
SELECT Code
	, COUNT(Code) AS count_code
FROM subway_delay
GROUP BY Code
ORDER BY count_code DESC;

-- What percentage of all bus delays are due to the top 3 causes?
SELECT (SUM(Code = 'SUDP')/COUNT(*)) * 100 AS percent_SUDP
	, (SUM(Code = 'MUIS')/COUNT(*)) * 100 AS percent_MUIS
    , (SUM(Code = 'MUPAA')/COUNT(*)) * 100 AS percent_MUPAA
FROM subway_delay;

-- Which subway route is most prone to delays?
SELECT Line
	, COUNT(Code) AS count_code
FROM subway_delay
GROUP BY Line
ORDER BY count_code DESC
LIMIT 1;

-- What are each subway routes most common form of delay?
SELECT Line
	, Code
FROM
	(
  SELECT Line
	, Code 
    , DENSE_RANK() OVER 
		(
		PARTITION BY Line -- DENSE_RANK() used over ROW_NUMBER() to display any ties of incident count per route
		ORDER BY COUNT(*) DESC
        ) rn
  FROM subway_delay
  GROUP BY Line
	, Code
	) T
WHERE rn=1;

-- which month has the most subway delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Code) AS count_incident
FROM subway_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_incident DESC;

-- what percentage of subway delays occurred within January, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'January')/COUNT(*)) * 100 AS percent_Jan_delays
FROM subway_delay;

-- what hour of the day are subway delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Code) AS count_code
FROM subway_delay
GROUP BY HOUR(Time)
ORDER BY count_incident DESC;

-- what is the average subway delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM subway_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;

-- what is the average subway delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
SELECT Line
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_difference
FROM subway_delay
GROUP BY Line
ORDER BY delay_gap_difference DESC;

-- which subway has the most 'MUATC' delay?
-- more on MUATC delay: https://www.ttc.ca/news/2022/September/TTCs-Line-1-now-running-on-an-ATC-signalling-system
SELECT DISTINCT Vehicle
	, COUNT(Code) AS count_mechanical_incident
FROM subway_delay
WHERE Code = 'MUATC'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;