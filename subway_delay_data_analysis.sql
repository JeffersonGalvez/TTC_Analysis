-- TTC subway delays data exploration and analysis
-- loading database
USE ttc_sql_project;

-- tables to analyze
SELECT MIN(Date) AS earlieast_date 
	, MAX(Date) AS latest_date
FROM subway_delay;
-- df spans fron 01 Jan 2022 to 31 Oct 2022

-- What are the different causes of subway delays (in descending order of occurance)?
SELECT subway_delay.Code
	, COUNT(subway_delay.Code) AS count_code
    , delay_codes_subway.code_description
FROM subway_delay
INNER JOIN delay_codes_subway
	ON subway_delay.Code = delay_codes_subway.Code
GROUP BY subway_delay.Code
	, delay_codes_subway.code_description
ORDER BY count_code DESC;
-- 1) 'SUDP' (Disordely Patron) = 1 555, 2) 'MUIS' (Injured or ill Customer (In Station) - Transported) = 1 536, 3) 'MUPAA' (Passenger Assistance Alarm Activated - No Trouble Found) = 1 186
-- 4) 'PUOPO' (OPTO (COMMS) Train Door Monitoring) = 961, 5) 'SUO' (Passenger Other) = 784, 6) 'MUATC' (ATC Project) = 721, 7) 'MUIRS' (Injured or ill Customer (In Station) - Medical Aid Refused) = 716
-- 8) 'MUO; (Miscellaneous Other) = 676, 9) 'MUSC' (Miscellaneous Speed Control) = 614, 10) 'SUUT' (Unauthorized at Track Level) = 467

-- what percentage of all bus delays are due to the top 3 causes?
SELECT (SUM(Code = 'SUDP')/COUNT(*)) * 100 AS percent_disorderly_patron
	, (SUM(Code = 'MUIS')/COUNT(*)) * 100 AS percent_injured_ill
    , (SUM(Code = 'MUPAA')/COUNT(*)) * 100 AS percent_alarm
    , (SUM(Code = 'PUOPO')/COUNT(*)) * 100 AS percent_train_door
    , (SUM(Code = 'SUO')/COUNT(*)) * 100 AS percent_passenger_other
    , (SUM(Code = 'MUATC')/COUNT(*)) * 100 AS percent_atc_project
    , (SUM(Code = 'MUIRS')/COUNT(*)) * 100 AS percent_medical_refused
    , (SUM(Code = 'MUO')/COUNT(*)) * 100 AS percent_misc_other
    , (SUM(Code = 'MUSC')/COUNT(*)) * 100 AS percent_misc_speed
    , (SUM(Code = 'SUUT')/COUNT(*)) * 100 AS percent_unauth_track
    , ((SUM(Code <> 'SUDP') + 
		SUM(Code <> 'MUIS') + 
		SUM(Code <> 'MUPAA') + 
        SUM(Code <> 'PUOPO') +
        SUM(Code <> 'SUO') +
        SUM(Code <> 'MUATC') +
        SUM(Code <> 'MUIRS') +
        SUM(Code <> 'MUO') +
        SUM(Code <> 'MUSC') +
        SUM(Code <> 'SUUT')) / COUNT(*)) * 100 AS percent_other
FROM subway_delay;
-- results best displayed as visual

SELECT ((SUM(Code = 'SUDP') + 
		SUM(Code = 'MUIS') + 
		SUM(Code = 'MUPAA') + 
        SUM(Code = 'PUOPO') +
        SUM(Code = 'SUO') +
        SUM(Code = 'MUATC') +
        SUM(Code = 'MUIRS') +
        SUM(Code = 'MUO') +
        SUM(Code = 'MUSC') +
        SUM(Code = 'SUUT')) / COUNT(*)) * 100 AS percent_other
FROM subway_delay;

-- How many different subway routes are in the subway_delay df?
SELECT COUNT(DISTINCT Line) AS distinct_count_route
FROM subway_delay
WHERE Line IS NOT NULL;
-- there are a total of 5 subway lines (four legitamate and one is a aggregation of 1 and 2, see repository 'data_cleaning' for more details)

-- how many delayed incidents does each line have?
SELECT Line AS Route
	, COUNT(Code) AS count_code
FROM subway_delay
GROUP BY Line
ORDER BY count_code DESC
LIMIT 5;
-- line 1 has had the most delays at 8 951

-- which month has the most subway delays, in descending order?
SELECT MONTHNAME(Date) AS month
	, COUNT(Code) AS count_subway_incident
FROM subway_delay
GROUP BY MONTHNAME(Date)
ORDER BY count_subway_incident DESC;
-- January saw the most streetcar delays at 1 899 and Sepetember experienced the least as 1 680

-- what percentage of subway delays occurred within January, the most delay-prone month?
SELECT (SUM(MONTHNAME(Date)= 'January')/COUNT(*)) * 100 AS percent_Jan_delays
FROM subway_delay;
-- January accounted fro 11.5% of subway delays

-- what is the average subway delay in minutes, by day of the week?
SELECT Day
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM subway_delay
GROUP BY Day
ORDER BY avg_delay_minutes DESC;
-- Monday = 4.1 min, Tue = 4.0 min, Sun = 3.9 min, Wed = 3.6 min, Sat = 3.5 min, Fri = 3.5 min, Thu = 3.4 min

-- what hour of the day are subway delays most likely to occur? By number of delays
SELECT HOUR(Time) AS hour_of_day
	, COUNT(Code) AS count_subway_incident
FROM subway_delay
GROUP BY HOUR(Time)
ORDER BY hour_of_day ASC;
-- 22:00 and 17:00 are the most subway delay-prone hours at 1 155 and 1 055, respectively

-- what is the average subway delay and the average scheduled gap in minutes, by route? And what is the difference between these two averages?
-- what effect do the delays have on on the sceduled number of subways?
SELECT Line
	, ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
	, ROUND(AVG(gap_minutes), 1) AS avg_gap_minutes
    , ROUND(AVG(gap_minutes), 1) - ROUND(AVG(delay_minutes), 1) AS delay_gap_minutes
    , ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1) AS target_12h
    , ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1) AS actual_12h
    , (ROUND(12 / (ROUND(AVG(gap_minutes), 1) / 60), 1)) - (ROUND(12 / ((ROUND(AVG(delay_minutes)) + ROUND(AVG(gap_minutes))) / 60), 1)) AS loss_num_trains
FROM subway_delay
WHERE Line IS NOT NULL
GROUP BY Line
ORDER BY loss_num_trains DESC;
-- line 2 and 1 have the largest delay-to-gap difference at 1.7 min both
-- line 2 had an average delay of 3.8 min and an average scheduled gap of 5.5 min
-- this means that in a 12 h period, line 2 is effectively delivering 72.0 streetcars rather than the scheduled 130.9, an effective loss of 58.9 scheduled runs

-- which subway has the most 'MUATC' (mechanical) delay?
-- more on MUATC delay: https://www.ttc.ca/news/2022/September/TTCs-Line-1-now-running-on-an-ATC-signalling-system
SELECT DISTINCT Vehicle
	, COUNT(Code) AS count_mechanical_incident
FROM subway_delay
WHERE Code = 'MUATC'
GROUP BY Vehicle
ORDER BY count_mechanical_incident DESC;
-- subways (vehcile) no. 5751 and 5551 have the most mechanical-related delays at 15 each