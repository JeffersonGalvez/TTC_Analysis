-- TTC subway delays data exploration and analysis
-- loading database
USE ttc_sql_project;

-- tables to analyze
SELECT MIN(Date) AS earlieast_date 
	, MAX(Date) AS latest_date
FROM subway_delay;
-- df spans fron 01 Jan 2022 to 31 Oct 2022

-- How many different subway routes are in the subway_delay df?
SELECT COUNT(DISTINCT Line) AS distinct_count_route
FROM subway_delay;
-- there are a total of 5 subway lines (4 legitamate and 1 NULL)

-- What are the different causes of subway delays (in descending order of occurance)?
SELECT subway_delay.Code
	, COUNT(subway_delay.Code) AS count_code
    , delay_codes_subway.code_description
FROM subway_delay
LEFT JOIN delay_codes_subway
	ON subway_delay.Code = delay_codes_subway.Code
GROUP BY subway_delay.Code
	, delay_codes_subway.code_description
ORDER BY count_code DESC;
-- 'SUDP' (Disordely Patron) was the most common form of subway delay at 1 555
-- followed by 'MUIS' (Injured or ill Customer (In Station) - Transported) and 'MUPAA' (Passenger Assistance Alarm Activated - No Trouble Found)
-- at 1 536 and 1 186, respectively

-- what percentage of all bus delays are due to the top 3 causes?
SELECT (SUM(Code = 'SUDP')/COUNT(*)) * 100 AS percent_disorderly_patron
	, (SUM(Code = 'MUIS')/COUNT(*)) * 100 AS percent_injured_ill
    , (SUM(Code = 'MUPAA')/COUNT(*)) * 100 AS percent_alarm
FROM subway_delay;
-- Disordely Patron = 9.4%, Injured or ill Customer = 9.3%, Passenger Assistance Alarm Activated = 7.2%

-- which subway route is most prone to delays?
SELECT Line
	, COUNT(Code) AS count_code
FROM subway_delay
GROUP BY Line
ORDER BY count_code DESC
LIMIT 1;
-- line YU has had the most delays at 8 951

-- what are each subway routes most common form of delay?
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
WHERE Line IS NOT NULL AND rn=1;
-- the resulting information of this query is best displayed when visualized

-- which month has the most subway delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Code) AS count_incident
FROM subway_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_incident DESC;
-- January saw the most streetcar delays at 1 899 and Sepetember experienced the least as 1 680

-- what percentage of subway delays occurred within January, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'January')/COUNT(*)) * 100 AS percent_Jan_delays
FROM subway_delay;
-- January accounted fro 11.5% of subway delays

-- what hour of the day are subway delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Code) AS count_code
FROM subway_delay
GROUP BY HOUR(Time)
ORDER BY count_code DESC;
-- 22:00 and 17:00 are the most subway delay-prone hours at 1 155 and 1 055, respectively

-- what is the average subway delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM subway_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;
-- Monday = 4.1 min, Tue = 4.0 min, Sun = 3.9 min, Wed = 3.6 min, Sat = 3.5 min, Fri = 3.5 min, Thu = 3.4 min

-- what is the average subway delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
-- what effect do the delays have on on the sceduled number of subways?
SELECT Line
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_minutes
    , ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1) AS scheduled_no_12h
    , ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1) AS effective_no_12h
    , (ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1)) - (ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1)) AS loss_no_trains
FROM subway_delay
WHERE Line IS NOT NULL
GROUP BY Line
ORDER BY loss_no_trains DESC;
-- line BD and YU have the largest delay-to-gap difference at 1.7 min both
-- line BD had an average delay of 3.8 min and an average scheduled gap of 5.5 min
-- this means that in a 12 h period, line BD is effectively delivering 72.0 streetcars rather than the scheduled 130.9, an effective loss of 58.9 scheduled runs

-- which subway has the most 'MUATC' (mechanical) delay?
-- more on MUATC delay: https://www.ttc.ca/news/2022/September/TTCs-Line-1-now-running-on-an-ATC-signalling-system
SELECT DISTINCT Vehicle
	, COUNT(Code) AS count_mechanical_incident
FROM subway_delay
WHERE Code = 'MUATC'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;
-- subways (vehcile) no. 5751 and 5551 have the most mechanical-related delays at 15 each