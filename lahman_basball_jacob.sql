--#1

SELECT MAX(yearid), MIN(yearid)
FROM batting;

------------------------------------------------------------------------------------------
--#2

SELECT 
    height AS height_feet,
    namefirst || ' ' || namelast AS Full_Name,
    team_names.name,
    COUNT(appearances.playerid) AS games_played
FROM people
    INNER JOIN appearances USING(playerid)
    INNER JOIN (
        		SELECT DISTINCT teamid, yearid, name 
        		FROM teams) 
				AS team_names USING(teamid,yearid)                   	 		 
WHERE height IS NOT NULL AND people.playerid = 'gaedeed01'
GROUP BY height, namefirst, namelast, team_names.name
ORDER BY height_feet ASC;



------------------------------------------------------------------------------------------
--#3

SELECT namefirst || ' ' || namelast AS full_name,schoolid,people.playerid, SUM(salary)::NUMERIC::MONEY AS Salary
FROM people
    INNER JOIN (
        SELECT DISTINCT playerid, schoolid 
        FROM collegeplaying
    ) AS cp USING(playerid)
    INNER JOIN schools USING(schoolid)
	INNER JOIN salaries USING(playerid)
WHERE schools.schoolname = 'Vanderbilt University'
GROUP BY people.playerid,schoolid,full_name
ORDER BY salary DESC;
--- Teacher Answer [BELOW]
WITH vandy_players AS(
SELECT DISTINCT playerID
FROM collegeplaying
WHERE schoolid = 'vandy'
)
SELECT namefirst || ' ' || namelast AS full_name, SUM(salary)::NUMERIC::MONEY AS total_salary
FROM vandy_players
	INNER JOIN salaries USING(playerID)
	INNER JOIN people USING (playerID)
GROUP BY full_name,playerid
ORDER BY total_salary DESC




------------------------------------------------------------------------------------------
--#4
SELECT CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN('1B','2B','3B','SS') THEN 'Infield'
		WHEN pos IN('P','C') THEN 'Battery' ELSE POS END AS group_players,
		SUM(po) AS Number_of_Putouts
FROM fielding
GROUP BY group_players
ORDER BY Number_of_Putouts;




------------------------------------------------------------------------------------------
--#5 Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
--			Do the same for home runs per game. Do you see any trends?
WITH so_hr_decade as (SELECT (yearid/10) * 10 AS decade,ROUND(SUM(SO)::numeric/(SUM(g)),2) AS avg_so,
						ROUND(SUM(hr)::numeric/(SUM(g)),2) AS avg_hr
						FROM teams
						GROUP by decade)
SELECT *
FROM so_hr_decade
WHERE decade >= 1920 AND avg_so IS NOT NULL
ORDER BY decade DESC;
-----
WITH decades AS (
SELECT generate_series(1920,2020,10) AS decade_start
)
SELECT 
	decade_start || 's' AS decade,
	ROUND(SUM(SO)::numeric / SUM(g), 2) AS avg_so,
	ROUND(SUM(HR)::numeric / SUM(g), 2) AS avg_hr
FROM decades
	INNER JOIN teams on teams.yearid BETWEEN decades.decade_start AND decades.decade_start + 9
GROUP BY decade
ORDER BY decade DESC;





--- Strikes outs nearly tripled HR near the 2000's, doing some reaserch this was dubbed the 'Steriod Era', AVG 'SO' increases too due to pitchers catching up but also because 

-- Batters tend to go for full home runs (Full strength bat swing & extreme angles) naturally dropping accuracy. This is also known as the 'Three True Outcomes' 
-----------------------------------------------------------------------------------------------------------------------

--#6 Find the player who had the most success stealing bases in 2016, 
--where __success__ is measured as the percentage of stolen base attempts which are successful.
--(A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

--BATTING : SB = Stolen Bases, CS = Caught Stealing
---- BY PLAYER, Highest '__success__' = SB/CS+SB


	WITH success_rate AS (
					SELECT playerID,ROUND(SUM(COALESCE(sb,0))::numeric / SUM(COALESCE(sb,0) + COALESCE(cs,0))::numeric * 100, 2) AS __success__
					FROM batting
					WHERE yearid = 2016
					GROUP BY playerID
					HAVING SUM(COALESCE(sb,0) + COALESCE(cs,0)) >= 20
				ORDER BY __success__ DESC)
SELECT namefirst || ' ' || namelast AS full_name,__success__
FROM Success_rate 
	INNER JOIN people USING(playerid)
ORDER BY __success__ DESC;
-----------------------------------------------
WITH batting_sum AS (SELECT
	playerid,
	sum(sb) AS total_stolen,
	sum(cs) AS total_caught
FROM batting
WHERE yearid = 2016
GROUP BY playerid
)
SELECT namefirst || ' ' || namelast AS full_name, 
	 total_stolen, 
	 total_stolen + total_caught AS total_attempt,
	 ROUND(total_stolen::numeric/(total_stolen + total_caught) * 100,2) AS percent_success
FROM
	batting_sum
	INNER JOIN people USING (playerid)
WHERE total_stolen + total_caught >= 20
ORDER BY percent_success DESC
-----------------------------------------------------------------------------------------------------------------------
--#7
--From 1970 – 2016
--largest number of wins for a team that ** did not win the world series **
-- What is the smallest number of wins for a team that did win the world series

--7a
SELECT name,SUM(w) AS total_wins,yearid
FROM Teams
WHERE wswin = 'N'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name,yearid
ORDER BY total_wins DESC;


--7b
SELECT name,SUM(w) AS total_wins,yearid
FROM Teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
GROUP BY name,yearid
ORDER BY total_wins DESC;

--7c

SELECT name,SUM(w) AS total_wins,yearid
FROM Teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1982 AND 2016
GROUP BY name,yearid
ORDER BY total_wins DESC;
--------------------------
WITH max_wins_by_year AS (SELECT
	Yearid,
	MAX(w) AS w
FROM teams
WHERE yearid >= 1970
GROUP BY yearid
ORDER by yearid
),
most_win_teams AS (
SELECT yearid,
		w,
		wswin,
		name
FROM 
	max_wins_by_year
	INNER JOIN teams USING(yearid,w)
)
SELECT
	SUM(CASE WHEN wswin = 'Y' THEN 1 END) AS num_ws_wins,
	COUNT (*) as total_rows,
	ROUND((SUM(CASE WHEN wswin = 'Y' THEN 1 END)::NUMERIC/COUNT (*))*100,2) AS percent
FROM most_win_teams


--50-day players' strike
--------------------------------------------------------------------------
-- #8
--	Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016
-- Attendance BY TEAM & PARK & PER GAME,
--	2016
-- SELECT park name, team name, and average attendance
-- PARK THRESHOLD = 10 GAMES
-- LIMIT TOP 5 and 
	
(WITH main AS (SELECT park_name,ROUND(AVG(attendance/games),1) AS avg_attendance,year,
				team
		FROM homegames
			INNER JOIN parks USING(park)
		WHERE games>=10
		GROUP BY park_name,team,year
		ORDER BY avg_attendance DESC)
SELECT main.avg_attendance,teams.name AS teams_name,park_name,yearid
FROM main
	INNER JOIN teams ON main.team = teams.teamid AND main.year = teams.yearid
WHERE yearid >=2016
ORDER BY avg_attendance DESC
LIMIT 5)
UNION
(WITH main AS (SELECT park_name,ROUND(AVG(attendance/games),1) AS avg_attendance,year,
				team
		FROM homegames
			INNER JOIN parks USING(park)
		WHERE games>=10
		GROUP BY park_name,team,year
		ORDER BY avg_attendance DESC)
SELECT main.avg_attendance,teams.name AS teams_name,park_name,yearid
FROM main
	INNER JOIN teams ON main.team = teams.teamid AND main.year = teams.yearid
WHERE yearid >=2016
ORDER BY avg_attendance ASC
LIMIT 5);
------------------------------------------------------------------------------------------------------

--#9
---Which managers have won the TSN Manager of the Year award 
--in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award

(WITH Names_of_winners AS (SELECT namefirst,namelast,playerid,yearid ---Need year ID bc they only won it that year
FROM people
	INNER JOIN (SELECT playerid,awardid, yearid
			FROM awardsmanagers
			WHERE awardid ILIKE '%TSN Manager of the Year%' AND playerid IN (
              SELECT playerid FROM awardsmanagers WHERE lgid = 'AL' AND awardid ILIKE '%TSN Manager of the Year%'
              INTERSECT
              SELECT playerid FROM awardsmanagers WHERE lgid = 'NL' AND awardid ILIKE '%TSN Manager of the Year%')
			  )
			  AS tsn_award_al_nl USING(playerid))
SELECT DISTINCT namefirst, --I added distinct so we can stop seeing duplicates
		namelast,
		teams.name as Teams_managed
FROM Names_of_winners
	INNER JOIN managers USING(playerid,yearid)
			INNER JOIN teams USING(teamid,yearid)
ORDER BY namefirst DESC)



--------------------------------------------------------------------------
---#10
WITH career_total AS (SELECT 
        playerid, 
        MAX(hr) AS career_high_hr,
        COUNT(DISTINCT yearid) AS years_played
    FROM batting
    GROUP BY playerid)
SELECT 
	people.namegiven,
	batting.hr AS HR_2016,playerid
FROM batting
	INNER JOIN people
		USING(playerid)
	INNER JOIN career_total USING(playerid)
WHERE batting.yearid = 2016
	AND batting.hr >=1
	AND career_total.years_played >= 10
	AND batting.hr = career_total.career_high_hr
ORDER BY hr_2016 DESC;
  --- OR --- (MORE NUANCED)
WITH career_stats AS (
	SELECT playerid, yearid,
			SUM(hr) AS total_hr_for_season
	FROM batting
	GROUP BY playerid,yearid
	ORDER BY playerid --- every player give every year they played.
),
career_summaries AS (
	SELECT
		Playerid,
		MAX(total_hr_for_season) AS Career_high_hr,
		COUNT(yearid) AS total_years_played
	FROM career_stats
	GROUP BY playerid)
SELECT
	people.namegiven,
	people.namefirst,
	people.namelast,
	career_stats.total_hr_for_season AS HR_2016
FROM career_stats
	INNER JOIN people USING(playerid)
	INNER JOIN career_summaries USING(playerid)
WHERE career_stats.yearid = 2016
	AND career_stats.total_hr_for_season >= 1
	AND career_summaries.total_years_played >= 10
	AND career_stats.total_hr_for_season = career_summaries.Career_high_hr
ORDER BY hr_2016 DESC;


--- TEACHER ANSWER [BELOW]
WITH batting_summary AS (
SELECT
	playerid,
	yearid,
	sum(hr) AS total_hr_per_year
FROM batting
GROUP BY
	playerid,
	yearid
),
decaders AS (
SELECT
	playerid,
	count(yearid) AS years_in_league
FROM batting_summary
GROUP BY playerid
HAVING COUNT (yearid) >= 10
), eligible_players AS (
SELECT
	playerid,
	total_hr_per_year
FROM decaders
	INNER JOIN batting_summary USING(playerid)
WHERE yearid=2016
	AND total_hr_per_year > 1
), 
Career_best AS (
SELECT playerid,
	   MAX(total_hr_per_year) AS career_best
FROM batting_summary
GROUP BY playerid)
SELECT namefirst || ' ' || namelast AS fullname,
		career_best AS home_run_hits_in_2016
FROM
	eligible_players ep
	INNER JOIN Career_best cb ON ep.playerid = cb.playerid
							  AND ep.total_hr_per_year = cb.Career_best
	INNER JOIN people ON ep.playerid = people.playerid



--------------------------------------------------------------------------

--#11

SELECT COUNT(w) AS wins, ROUND(AVG(salaries.salary::numeric/1000000),2) AS avg_salary_Millions, teams.yearid,
		name,teams.teamid
FROM teams
	INNER JOIN salaries USING(teamid)
WHERE teams.yearid >= 2000
GROUP BY teams.teamid,name,teams.yearid
ORDER BY avg_salary_Millions DESC;

WITH TEAM_STATS AS (SELECT 
    teams.name,
    teams.yearid,
    teams.w AS wins,
    ROUND(SUM(salaries.salary)::numeric / 1000000, 2) AS total_payroll_millions,
	ROUND((SUM(salaries.salary)::numeric / teams.w) / 1000000, 2) AS cost_per_win_mil
FROM teams
INNER JOIN salaries 
    ON teams.teamid = salaries.teamid 
    AND teams.yearid = salaries.yearid
WHERE teams.yearid >= 2000 
GROUP BY 
    teams.name, 
    teams.yearid, 
    teams.w, 
    teams.teamid
)
SELECT ROUND(REGR_R2(wins, TEAM_STATS.total_payroll_millions)::numeric, 4) AS r_squared_total
FROM team_stats;

--- no correlation/very low linear relationship 
-- You can't but the world series </3
----------------------------------------------------------------------------------------------

-- #13
--- TOTAL CY Winner pitcher stats
WITH throw_dhand AS (SELECT playerid,throws
FROM people
),
Player_cy_award AS (SELECT playerid,awardid,yearid
FROM awardsplayers
WHERE awardid = 'Cy Young Award'
),
STATS AS (SELECT Player_cy_award.playerid,appearances.teamid,throws,awardid,Player_cy_award.yearid
FROM appearances
	INNER JOIN throw_dhand USING(playerid)
	INNER JOIN Player_cy_award ON appearances.yearid = player_cy_award.yearid
				AND appearances.playerid = player_cy_award.playerid
), 
stat_wins AS (SELECT stats.playerid, teams.teamid,
					stats.yearid, STATS.awardid, 
					STATS.throws, SUM(w) AS total_wins
FROM teams
	INNER JOIN stats ON teams.yearid = stats.yearid 
					AND teams.teamid = stats.teamid
GROUP BY stats.playerid, teams.teamid,stats.yearid, STATS.awardid, STATS.throws
ORDER BY total_wins DESC
),
cy_young_final AS (SELECT throws,COUNT(*) AS wins_per_hand, --FINAL CY Pop & rarity
		COUNT(*) AS Cy_Young_Award_count,
		SUM(COUNT(*)) OVER() AS total_awards_given,
		100*(COUNT(*)/(SUM(COUNT(*)) OVER())) AS rarity
FROM stat_wins
GROUP BY throws
),
test AS (SELECT playerid,SUM(w) as wins --TOTAL pitcher stats
FROM pitching
group by playerid
HAVING SUM(w) >=1
),
pop_final AS (SELECT throws,COUNT(DISTINCT playerid) AS Pitcher_count,
					100*COUNT(DISTINCT playerid)/SUM(COUNT(DISTINCT playerID)) OVER() AS population_p
FROM people
	INNER JOIN test USING(playerid)
WHERE throws IN('L','R')
GROUP BY throws
)
SELECT
	pop_final.throws, pop_final.Pitcher_count, ROUND(pop_final.population_p,2) as Full_Population_percent
	,cy_young_final.Cy_Young_Award_count,
	ROUND(cy_young_final.rarity,2) AS CY_AWARD_percent,
	ROUND((cy_young_final.rarity / pop_final.population_p), 2) AS effectiveness_index
FROM pop_final
	INNER JOIN cy_young_final ON pop_final.throws = cy_young_final.throws.

--Effectiveness Index is = predicted % VS actual %, predicted % = total pop of pitcher %, actualy % = CY_AWARD_percent based of its total pop
-- So you wanna do CY_AWARD_percent/Full_Population_percent.
-- When 1 = Matches proporiton estimated, X<1 (less than 1) means preform LESS than exected, X<1 (Preform) means preform MORE than exected.
-- If the throwing hand has no impact then both distrubutions should perfectly mirror 1
-- THEREFORE, left-handed pitchers ARE more likely to win the Cy Young Award, by 21% (1.21) over the estimate (1)


-----------------------------------------------------------------------------

--# 13 Hall of Fame Analysis

WITH TEST2 AS (SELECT playerid,SUM(w) as wins --TOTAL pitcher stats
FROM pitching
group by playerid
HAVING SUM(w) >=1
),
HOF_winner AS (SELECT playerID
FROM halloffame
WHERE inducted ILIKE 'Y'
),
T_Pitcher_stats AS (SELECT playerid,SUM(w) as wins --TOTAL pitcher stats
FROM pitching
group by playerid
HAVING SUM(w) >=1
),
T_Pitcher_stats_percent AS (SELECT throws,COUNT(DISTINCT playerid) AS Pitcher_count,
					100*COUNT(DISTINCT playerid)/SUM(COUNT(DISTINCT playerID)) OVER() AS total_population_p
FROM people
	INNER JOIN T_Pitcher_stats USING(playerid)
WHERE throws IN('L','R')
GROUP BY throws
),
HOF_percent AS (SELECT COUNT(playerid) TOTAL_Pitchers,throws,
		100*COUNT(DISTINCT playerid)/SUM(COUNT(DISTINCT playerID)) OVER() AS HOF_population_percent
FROM HOF_winner
	INNER JOIN people USING(playerid)
WHERE throws IN('R','L')
GROUP BY throws)
SELECT *, ROUND(HOF_population_percent/total_population_p,2) AS effective_index
FROM HOF_percent
	INNER JOIN T_Pitcher_stats_percent ON HOF_percent.throws = T_Pitcher_stats_percent.throws

--Interestingly enough, while theyre more likely to PEAK, theyre 32% less likely to be a Hall of Fame'r
-- Maybe because theyre more prone to injury/More about burst preformance vs longevity.