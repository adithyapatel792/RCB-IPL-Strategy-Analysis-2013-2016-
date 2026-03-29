-- ============================================================
--  IPL DATA ANALYSIS — SQL SOLUTIONS
--  Presented By : Adithya Lakkakula
--  Database     : ipl
--  Workbench    : MySQL Workbench
-- ============================================================

USE ipl;

-- ============================================================
-- OBJECTIVE QUESTION 1
-- List the different dtypes of columns in table "ball_by_ball"
-- (using information_schema)
-- ============================================================

SELECT
    COLUMN_NAME                 AS column_name,
    DATA_TYPE                          AS data_type,
    COLUMN_TYPE                        AS full_column_type,
    IS_NULLABLE                        AS is_nullable,
    COLUMN_KEY                         AS key_info
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ipl'
  AND TABLE_NAME   = 'Ball_by_Ball'
ORDER BY ORDINAL_POSITION;


-- ============================================================
-- OBJECTIVE QUESTION 2
-- Total runs scored by RCB in the EARLIEST available season
-- Dataset has: Season 7(2014), 8(2015), 9(2016) in Ball_by_Ball
-- Season 1(2008) does NOT exist in this dataset
-- RCB = Team_Id 2, Earliest season with BBB data = Season_Id 7
-- ============================================================

-- Part A: RCB batting runs — earliest available season (2014)
SELECT
    s.Season_Year,
    SUM(b.Runs_Scored)              AS rcb_runs
FROM Ball_by_Ball b
JOIN Matches m ON b.Match_Id    = m.Match_Id
JOIN Season  s ON m.Season_Id   = s.Season_Id
WHERE b.Team_Batting = 2
  AND m.Season_Id = (
        SELECT MIN(m2.Season_Id)
        FROM Ball_by_Ball b2
        JOIN Matches m2 ON b2.Match_Id = m2.Match_Id
        WHERE b2.Team_Batting = 2
      )
GROUP BY s.Season_Year;

-- Part B (Bonus): Including Extra Runs
SELECT
    s.Season_Year,
    SUM(b.Runs_Scored)                              AS batting_runs,
    COALESCE(SUM(er.Extra_Runs), 0)                 AS extra_runs,
    SUM(b.Runs_Scored)
        + COALESCE(SUM(er.Extra_Runs), 0)           AS total_runs_including_extras
FROM Ball_by_Ball b
JOIN Matches     m  ON b.Match_Id    = m.Match_Id
JOIN Season      s  ON m.Season_Id   = s.Season_Id
LEFT JOIN Extra_Runs er
    ON  er.Match_Id   = b.Match_Id
    AND er.Over_Id    = b.Over_Id
    AND er.Ball_Id    = b.Ball_Id
    AND er.Innings_No = b.Innings_No
WHERE b.Team_Batting = 2
  AND m.Season_Id = (
        SELECT MIN(m2.Season_Id)
        FROM Ball_by_Ball b2
        JOIN Matches m2 ON b2.Match_Id = m2.Match_Id
        WHERE b2.Team_Batting = 2
      )
GROUP BY s.Season_Year;

-- ============================================================
-- OBJECTIVE QUESTION 3
-- How many players were more than 25 years of age during
-- Season 2014? (Season_Id = 7, Year = 2014)
-- ============================================================

SELECT
    COUNT(DISTINCT p.Player_Id)  AS players_above_25_in_2014
FROM Player p
JOIN Player_Match pm ON p.Player_Id = pm.Player_Id
JOIN Matches m       ON pm.Match_Id = m.Match_Id
JOIN Season s        ON m.Season_Id = s.Season_Id
WHERE s.Season_Year = 2014
  AND TIMESTAMPDIFF(YEAR, p.DOB, CONCAT(s.Season_Year, '-01-01')) > 25;


-- ============================================================
-- OBJECTIVE QUESTION 4
-- How many matches did RCB win in 2013?
-- Season_Id = 6 (Year 2013), RCB = Team_Id 2
-- ============================================================

SELECT
    COUNT(*)                     AS rcb_wins_2013
FROM Matches m
JOIN Season s ON m.Season_Id = s.Season_Id
WHERE s.Season_Year  = 2013
  AND m.Match_Winner = 2          -- Team_Id 2 = Royal Challengers Bangalore
  AND m.Outcome_type = 1;         -- Outcome 1 = 'Result' (valid match result)


-- ============================================================
-- OBJECTIVE QUESTION 5
-- Top 10 players by strike rate in the last 4 seasons
-- (Seasons 6,7,8,9 → Years 2013,2014,2015,2016)
-- Strike Rate = (Total Runs / Total Balls Faced) * 100
-- ============================================================

SELECT
    p.Player_Name,
    SUM(b.Runs_Scored)                                     AS total_runs,
    COUNT(b.Ball_Id)                                       AS balls_faced,
    ROUND(SUM(b.Runs_Scored) / COUNT(b.Ball_Id) * 100, 2) AS strike_rate
FROM Ball_by_Ball b
JOIN Player p  ON b.Striker = p.Player_Id
JOIN Matches m ON b.Match_Id = m.Match_Id
WHERE m.Season_Id IN (6, 7, 8, 9)      -- Last 4 seasons (2013–2016)
GROUP BY p.Player_Id, p.Player_Name
HAVING balls_faced >= 50               -- Minimum 50 balls for meaningful rate
ORDER BY strike_rate DESC
LIMIT 10;


-- ============================================================
-- OBJECTIVE QUESTION 6
-- Average runs scored by each batsman across all seasons
-- Formula: Total Runs / Number of Seasons played
-- ============================================================

SELECT
    p.Player_Name,
    COUNT(DISTINCT m.Season_Id)                         AS seasons_played,
    COUNT(DISTINCT m.Match_Id)                          AS matches_played,
    SUM(b.Runs_Scored)                                  AS total_runs,
    ROUND(
        SUM(b.Runs_Scored)
        / COUNT(DISTINCT m.Season_Id)
    , 2)                                                AS avg_runs_per_season
FROM Ball_by_Ball b
JOIN Player  p ON b.Striker  = p.Player_Id
JOIN Matches m ON b.Match_Id = m.Match_Id
GROUP BY p.Player_Id, p.Player_Name
ORDER BY avg_runs_per_season DESC;


-- ============================================================
-- OBJECTIVE QUESTION 7
-- Average wickets taken by each bowler across all seasons
-- Formula: Total Wickets / Number of Seasons played
-- (excluding run-outs as they are not credited to bowlers)
-- ============================================================

SELECT
    p.Player_Name,
    COUNT(DISTINCT m.Season_Id)                         AS seasons_played,
    COUNT(DISTINCT m.Match_Id)                          AS matches_bowled,
    COUNT(wt.Player_Out)                                AS total_wickets,
    ROUND(
        COUNT(wt.Player_Out)
        / COUNT(DISTINCT m.Season_Id)
    , 2)                                                AS avg_wickets_per_season
FROM Ball_by_Ball b
JOIN Player        p  ON b.Bowler    = p.Player_Id
JOIN Matches       m  ON b.Match_Id  = m.Match_Id
LEFT JOIN Wicket_Taken wt
    ON  wt.Match_Id   = b.Match_Id
    AND wt.Over_Id    = b.Over_Id
    AND wt.Ball_Id    = b.Ball_Id
    AND wt.Innings_No = b.Innings_No
    AND wt.Kind_Out  != 3               -- exclude run-outs (Out_Id 3)
GROUP BY p.Player_Id, p.Player_Name
ORDER BY avg_wickets_per_season DESC;


-- ============================================================
-- OBJECTIVE QUESTION 8
-- Players whose average runs > overall average runs
-- AND average wickets > overall average wickets
-- ============================================================

-- Step 1: Compute batting averages per player
WITH batting_avg AS (
    SELECT
        b.Striker                                         AS player_id,
        SUM(b.Runs_Scored)                                AS total_runs,
        COUNT(DISTINCT b.Match_Id)                        AS matches_batted,
        SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_Id)  AS avg_runs
    FROM Ball_by_Ball b
    GROUP BY b.Striker
),
-- Step 2: Compute bowling averages per player
bowling_avg AS (
    SELECT
        b.Bowler                                            AS player_id,
        COUNT(wt.Player_Out)                                AS total_wickets,
        COUNT(DISTINCT b.Match_Id)                          AS matches_bowled,
        COUNT(wt.Player_Out) / COUNT(DISTINCT b.Match_Id)  AS avg_wickets
    FROM Ball_by_Ball b
    LEFT JOIN Wicket_Taken wt
        ON  wt.Match_Id   = b.Match_Id
        AND wt.Over_Id    = b.Over_Id
        AND wt.Ball_Id    = b.Ball_Id
        AND wt.Innings_No = b.Innings_No
        AND wt.Kind_Out  != 3
    GROUP BY b.Bowler
),
-- Step 3: Overall averages
overall AS (
    SELECT
        AVG(avg_runs)    AS overall_avg_runs
    FROM batting_avg
),
overall_wkt AS (
    SELECT
        AVG(avg_wickets) AS overall_avg_wickets
    FROM bowling_avg
)
-- Step 4: Filter all-rounders above both benchmarks
SELECT
    p.Player_Name,
    ROUND(ba.avg_runs,    2) AS avg_runs_per_match,
    ROUND(bw.avg_wickets, 2) AS avg_wickets_per_match,
    ROUND(ov.overall_avg_runs,    2) AS overall_avg_runs,
    ROUND(ow.overall_avg_wickets, 2) AS overall_avg_wickets
FROM batting_avg   ba
JOIN bowling_avg   bw ON ba.player_id = bw.player_id
JOIN Player        p  ON ba.player_id = p.Player_Id
CROSS JOIN overall     ov
CROSS JOIN overall_wkt ow
WHERE ba.avg_runs    > ov.overall_avg_runs
  AND bw.avg_wickets > ow.overall_avg_wickets
ORDER BY ba.avg_runs DESC, bw.avg_wickets DESC;


-- ============================================================
-- OBJECTIVE QUESTION 9
-- Create rcb_record table showing RCB wins and losses per venue
-- RCB = Team_Id 2
-- ============================================================

-- Create the table
CREATE TABLE IF NOT EXISTS rcb_record (
    venue_id      INT          NOT NULL,
    venue_name    VARCHAR(450) NOT NULL,
    wins          INT          DEFAULT 0,
    losses        INT          DEFAULT 0,
    no_results    INT          DEFAULT 0,
    total_matches INT          DEFAULT 0,
    PRIMARY KEY (venue_id)
);

-- Populate / refresh
TRUNCATE TABLE rcb_record;

INSERT INTO rcb_record (venue_id, venue_name, wins, losses, no_results, total_matches)
SELECT
    v.Venue_Id,
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner = 2 AND m.Outcome_type = 1 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN m.Match_Winner != 2 AND m.Outcome_type = 1
             AND (m.Team_1 = 2 OR m.Team_2 = 2)                THEN 1 ELSE 0 END) AS losses,
    SUM(CASE WHEN m.Outcome_type != 1                           THEN 1 ELSE 0 END) AS no_results,
    COUNT(*)                                                                        AS total_matches
FROM Matches m
JOIN Venue v ON m.Venue_Id = v.Venue_Id
WHERE m.Team_1 = 2 OR m.Team_2 = 2
GROUP BY v.Venue_Id, v.Venue_Name
ORDER BY total_matches DESC;

-- View the result
SELECT * FROM rcb_record ORDER BY total_matches DESC;


-- ============================================================
-- OBJECTIVE QUESTION 10
-- Impact of bowling style on wickets taken
-- ============================================================

SELECT
    bs.Bowling_skill                    AS bowling_style,
    COUNT(DISTINCT p.Player_Id)         AS bowlers_count,
    COUNT(wt.Player_Out)                AS total_wickets,
    COUNT(DISTINCT wt.Match_Id)         AS matches_involved,
    ROUND(
        COUNT(wt.Player_Out)
        / COUNT(DISTINCT wt.Match_Id)
    , 2)                                AS avg_wickets_per_match,
    ROUND(
        COUNT(wt.Player_Out) * 100.0
        / SUM(COUNT(wt.Player_Out)) OVER()
    , 2)                                AS pct_of_total_wickets
FROM Wicket_Taken wt
JOIN Ball_by_Ball b
    ON  wt.Match_Id   = b.Match_Id
    AND wt.Over_Id    = b.Over_Id
    AND wt.Ball_Id    = b.Ball_Id
    AND wt.Innings_No = b.Innings_No
JOIN Player p         ON b.Bowler         = p.Player_Id
JOIN Bowling_Style bs ON p.Bowling_skill  = bs.Bowling_Id
WHERE wt.Kind_Out != 3                   -- exclude run-outs
GROUP BY bs.Bowling_Id, bs.Bowling_skill
ORDER BY total_wickets DESC;


-- ============================================================
-- OBJECTIVE QUESTION 11
-- Team performance vs previous year (runs scored & wickets taken)
-- LAG window function to compare year-on-year
-- ============================================================

WITH season_stats AS (
    SELECT
        s.Season_Year,
        m.Team_1                         AS team_id,
        SUM(b.Runs_Scored)               AS runs_scored,
        COUNT(wt.Player_Out)             AS wickets_taken
    FROM Matches m
    JOIN Season       s  ON m.Season_Id   = s.Season_Id
    JOIN Ball_by_Ball b  ON b.Match_Id    = m.Match_Id
                        AND b.Team_Batting = m.Team_1
    LEFT JOIN Wicket_Taken wt
        ON  wt.Match_Id   = b.Match_Id
        AND wt.Over_Id    = b.Over_Id
        AND wt.Ball_Id    = b.Ball_Id
        AND wt.Innings_No = b.Innings_No
    GROUP BY s.Season_Year, m.Team_1

    UNION ALL

    SELECT
        s.Season_Year,
        m.Team_2                         AS team_id,
        SUM(b.Runs_Scored)               AS runs_scored,
        COUNT(wt.Player_Out)             AS wickets_taken
    FROM Matches m
    JOIN Season       s  ON m.Season_Id   = s.Season_Id
    JOIN Ball_by_Ball b  ON b.Match_Id    = m.Match_Id
                        AND b.Team_Batting = m.Team_2
    LEFT JOIN Wicket_Taken wt
        ON  wt.Match_Id   = b.Match_Id
        AND wt.Over_Id    = b.Over_Id
        AND wt.Ball_Id    = b.Ball_Id
        AND wt.Innings_No = b.Innings_No
    GROUP BY s.Season_Year, m.Team_2
),
aggregated AS (
    SELECT
        team_id,
        Season_Year,
        SUM(runs_scored)   AS total_runs,
        SUM(wickets_taken) AS total_wickets
    FROM season_stats
    GROUP BY team_id, Season_Year
)
SELECT
    t.Team_Name,
    a.Season_Year,
    a.total_runs,
    a.total_wickets,
    LAG(a.total_runs)    OVER (PARTITION BY a.team_id ORDER BY a.Season_Year) AS prev_year_runs,
    LAG(a.total_wickets) OVER (PARTITION BY a.team_id ORDER BY a.Season_Year) AS prev_year_wickets,
    CASE
        WHEN LAG(a.total_runs)    OVER (PARTITION BY a.team_id ORDER BY a.Season_Year) IS NULL
             THEN 'First Season'
        WHEN a.total_runs > LAG(a.total_runs) OVER (PARTITION BY a.team_id ORDER BY a.Season_Year)
             AND a.total_wickets > LAG(a.total_wickets) OVER (PARTITION BY a.team_id ORDER BY a.Season_Year)
             THEN 'Better'
        WHEN a.total_runs < LAG(a.total_runs) OVER (PARTITION BY a.team_id ORDER BY a.Season_Year)
             AND a.total_wickets < LAG(a.total_wickets) OVER (PARTITION BY a.team_id ORDER BY a.Season_Year)
             THEN 'Worse'
        ELSE 'Mixed'
    END                  AS performance_vs_prev_year
FROM aggregated a
JOIN Team t ON a.team_id = t.Team_Id
ORDER BY t.Team_Name, a.Season_Year;


-- ============================================================
-- OBJECTIVE QUESTION 12
-- Additional KPIs for team strategy
-- ============================================================

-- KPI 1: Net Run Rate (NRR) per team per season
SELECT
    t.Team_Name,
    s.Season_Year,
    ROUND(SUM(b.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS avg_runs_scored_per_match,
    COUNT(DISTINCT m.Match_Id)                                 AS matches_played
FROM Matches m
JOIN Season       s  ON m.Season_Id    = s.Season_Id
JOIN Ball_by_Ball b  ON b.Match_Id     = m.Match_Id
JOIN Team         t  ON b.Team_Batting = t.Team_Id
GROUP BY t.Team_Id, t.Team_Name, s.Season_Year
ORDER BY s.Season_Year, avg_runs_scored_per_match DESC;

-- KPI 2: Toss win to match win conversion rate per team
SELECT
    t.Team_Name,
    COUNT(*)                                                   AS toss_wins,
    SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) AS converted_to_match_win,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2)                                                         AS toss_win_conversion_pct
FROM Matches m
JOIN Team t ON m.Toss_Winner = t.Team_Id
WHERE m.Outcome_type = 1
GROUP BY t.Team_Id, t.Team_Name
ORDER BY toss_win_conversion_pct DESC;

-- KPI 3: Powerplay (overs 1-6) vs Death (overs 17-20) run comparison
SELECT
    t.Team_Name,
    ROUND(AVG(CASE WHEN b.Over_Id BETWEEN 1 AND 6  THEN b.Runs_Scored END), 2) AS avg_runs_powerplay,
    ROUND(AVG(CASE WHEN b.Over_Id BETWEEN 17 AND 20 THEN b.Runs_Scored END), 2) AS avg_runs_death_overs
FROM Ball_by_Ball b
JOIN Team t ON b.Team_Batting = t.Team_Id
GROUP BY t.Team_Id, t.Team_Name
ORDER BY avg_runs_powerplay DESC;

-- KPI 4: Player of the Match win frequency (clutch players)
SELECT
    p.Player_Name,
    COUNT(m.Man_of_the_Match)  AS motm_awards
FROM Matches m
JOIN Player p ON m.Man_of_the_Match = p.Player_Id
WHERE m.Outcome_type = 1
GROUP BY p.Player_Id, p.Player_Name
ORDER BY motm_awards DESC
LIMIT 15;

-- KPI 5: Extras conceded per team per season (discipline KPI)
SELECT
    t.Team_Name,
    s.Season_Year,
    SUM(er.Extra_Runs)         AS total_extras_conceded,
    COUNT(DISTINCT m.Match_Id) AS matches_played,
    ROUND(SUM(er.Extra_Runs) / COUNT(DISTINCT m.Match_Id), 2) AS extras_per_match
FROM Extra_Runs er
JOIN Ball_by_Ball b
    ON  er.Match_Id   = b.Match_Id
    AND er.Over_Id    = b.Over_Id
    AND er.Ball_Id    = b.Ball_Id
    AND er.Innings_No = b.Innings_No
JOIN Matches m  ON b.Match_Id    = m.Match_Id
JOIN Season  s  ON m.Season_Id   = s.Season_Id
JOIN Team    t  ON b.Team_Bowling = t.Team_Id
GROUP BY t.Team_Id, t.Team_Name, s.Season_Year
ORDER BY s.Season_Year, extras_per_match DESC;


-- ============================================================
-- OBJECTIVE QUESTION 13
-- Average wickets taken by each bowler at each venue
-- + RANK by average within each venue
-- ============================================================

WITH bowler_venue AS (
    SELECT
        v.Venue_Name,
        p.Player_Name,
        COUNT(DISTINCT m.Match_Id)                          AS matches_at_venue,
        COUNT(wt.Player_Out)                                AS total_wickets,
        ROUND(
            COUNT(wt.Player_Out) / COUNT(DISTINCT m.Match_Id)
        , 2)                                                AS avg_wickets
    FROM Ball_by_Ball b
    JOIN Matches       m  ON b.Match_Id    = m.Match_Id
    JOIN Venue         v  ON m.Venue_Id    = v.Venue_Id
    JOIN Player        p  ON b.Bowler      = p.Player_Id
    LEFT JOIN Wicket_Taken wt
        ON  wt.Match_Id   = b.Match_Id
        AND wt.Over_Id    = b.Over_Id
        AND wt.Ball_Id    = b.Ball_Id
        AND wt.Innings_No = b.Innings_No
        AND wt.Kind_Out  != 3
    GROUP BY v.Venue_Id, v.Venue_Name, p.Player_Id, p.Player_Name
    HAVING matches_at_venue >= 2               -- at least 2 matches for relevance
)
SELECT
    Venue_Name,
    Player_Name,
    matches_at_venue,
    total_wickets,
    avg_wickets,
    RANK() OVER (
        PARTITION BY Venue_Name
        ORDER BY avg_wickets DESC
    )                                          AS venue_rank
FROM bowler_venue
ORDER BY Venue_Name, venue_rank;


-- ============================================================
-- OBJECTIVE QUESTION 14
-- Players who have consistently performed well across seasons
-- (High average runs AND appearing in multiple seasons)
-- ============================================================

SELECT
    p.Player_Name,
    COUNT(DISTINCT m.Season_Id)              AS seasons_played,
    SUM(b.Runs_Scored)                       AS career_runs,
    COUNT(DISTINCT m.Match_Id)               AS matches_played,
    ROUND(
        SUM(b.Runs_Scored)
        / COUNT(DISTINCT m.Match_Id)
    , 2)                                     AS avg_runs_per_match,
    -- Consistency = std dev approximation: low variance = consistent
    ROUND(STDDEV(b.Runs_Scored), 2)          AS runs_std_deviation
FROM Ball_by_Ball b
JOIN Player  p ON b.Striker  = p.Player_Id
JOIN Matches m ON b.Match_Id = m.Match_Id
GROUP BY p.Player_Id, p.Player_Name
HAVING seasons_played >= 3
   AND avg_runs_per_match >= 10
ORDER BY avg_runs_per_match DESC, seasons_played DESC
LIMIT 20;


-- ============================================================
-- OBJECTIVE QUESTION 15
-- Players whose performance is suited to specific venues
-- (venue-level batting average vs overall batting average)
-- ============================================================

WITH overall_avg AS (
    SELECT
        b.Striker,
        ROUND(SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_Id), 2) AS career_avg
    FROM Ball_by_Ball b
    GROUP BY b.Striker
),
venue_avg AS (
    SELECT
        b.Striker,
        v.Venue_Name,
        COUNT(DISTINCT m.Match_Id)               AS matches_at_venue,
        SUM(b.Runs_Scored)                       AS runs_at_venue,
        ROUND(
            SUM(b.Runs_Scored)
            / COUNT(DISTINCT m.Match_Id)
        , 2)                                     AS venue_avg
    FROM Ball_by_Ball b
    JOIN Matches m ON b.Match_Id  = m.Match_Id
    JOIN Venue   v ON m.Venue_Id  = v.Venue_Id
    GROUP BY b.Striker, v.Venue_Id, v.Venue_Name
    HAVING matches_at_venue >= 3
)
SELECT
    p.Player_Name,
    va.Venue_Name,
    va.matches_at_venue,
    va.runs_at_venue,
    va.venue_avg,
    oa.career_avg,
    ROUND(va.venue_avg - oa.career_avg, 2)       AS venue_vs_career_diff,
    CASE
        WHEN va.venue_avg > oa.career_avg * 1.2  THEN 'Venue Specialist'
        WHEN va.venue_avg < oa.career_avg * 0.8  THEN 'Struggles Here'
        ELSE 'Consistent'
    END                                           AS venue_fit
FROM venue_avg  va
JOIN overall_avg oa ON va.Striker   = oa.Striker
JOIN Player      p  ON va.Striker   = p.Player_Id
ORDER BY venue_vs_career_diff DESC;


-- ============================================================
-- SUBJECTIVE QUESTION 1
-- How does the toss decision affect the match result?
-- Is the impact limited to specific venues?
-- ============================================================

-- Overall toss decision vs win rate
SELECT
    td.Toss_Name                                                  AS toss_decision,
    COUNT(*)                                                      AS matches,
    SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) AS toss_winner_won,
    ROUND(
        SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2)                                                            AS win_pct_after_toss
FROM Matches m
JOIN Toss_Decision td ON m.Toss_Decide = td.Toss_Id
WHERE m.Outcome_type = 1
GROUP BY td.Toss_Id, td.Toss_Name;

-- Toss decision impact broken down by venue
SELECT
    v.Venue_Name,
    td.Toss_Name                                                  AS toss_decision,
    COUNT(*)                                                      AS matches,
    SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) AS toss_winner_won,
    ROUND(
        SUM(CASE WHEN m.Toss_Winner = m.Match_Winner THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2)                                                            AS win_pct
FROM Matches m
JOIN Toss_Decision td ON m.Toss_Decide = td.Toss_Id
JOIN Venue         v  ON m.Venue_Id    = v.Venue_Id
WHERE m.Outcome_type = 1
GROUP BY v.Venue_Id, v.Venue_Name, td.Toss_Id, td.Toss_Name
HAVING matches >= 5
ORDER BY v.Venue_Name, toss_decision;


-- ============================================================
-- SUBJECTIVE QUESTION 2
-- Suggest players best fit for RCB
-- (Top performers across batting, bowling & all-round)
-- ============================================================

-- Best batsmen (high avg runs, active in recent seasons)
SELECT
    'Batsman'          AS recommended_role,
    p.Player_Name,
    COUNT(DISTINCT m.Season_Id)                          AS seasons,
    SUM(b.Runs_Scored)                                   AS total_runs,
    ROUND(SUM(b.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS avg_runs,
    ROUND(SUM(b.Runs_Scored) / COUNT(b.Ball_Id) * 100, 2)     AS strike_rate
FROM Ball_by_Ball b
JOIN Player  p ON b.Striker  = p.Player_Id
JOIN Matches m ON b.Match_Id = m.Match_Id
WHERE m.Season_Id >= 6                                   -- Last 4 seasons
GROUP BY p.Player_Id, p.Player_Name
HAVING COUNT(DISTINCT m.Match_Id) >= 10
ORDER BY avg_runs DESC
LIMIT 10;

-- Best bowlers (high avg wickets, last 4 seasons)
SELECT
    'Bowler'           AS recommended_role,
    p.Player_Name,
    COUNT(DISTINCT m.Season_Id)                                          AS seasons,
    COUNT(wt.Player_Out)                                                 AS total_wickets,
    ROUND(COUNT(wt.Player_Out) / COUNT(DISTINCT m.Match_Id), 2)         AS avg_wickets
FROM Ball_by_Ball b
JOIN Player        p  ON b.Bowler    = p.Player_Id
JOIN Matches       m  ON b.Match_Id  = m.Match_Id
LEFT JOIN Wicket_Taken wt
    ON  wt.Match_Id   = b.Match_Id
    AND wt.Over_Id    = b.Over_Id
    AND wt.Ball_Id    = b.Ball_Id
    AND wt.Innings_No = b.Innings_No
    AND wt.Kind_Out  != 3
WHERE m.Season_Id >= 6
GROUP BY p.Player_Id, p.Player_Name
HAVING COUNT(DISTINCT m.Match_Id) >= 10
ORDER BY avg_wickets DESC
LIMIT 10;


-- ============================================================
-- SUBJECTIVE QUESTION 3
-- Parameters for player selection
-- (Composite scoring: runs, wickets, strike rate, MOTM)
-- ============================================================

SELECT
    p.Player_Name,
    COUNT(DISTINCT m.Match_Id)                                           AS matches,
    SUM(b.Runs_Scored)                                                   AS total_runs,
    ROUND(SUM(b.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2)           AS avg_runs,
    ROUND(SUM(b.Runs_Scored) / NULLIF(COUNT(b.Ball_Id), 0) * 100, 2)   AS strike_rate,
    COUNT(wt.Player_Out)                                                 AS wickets,
    ROUND(COUNT(wt.Player_Out) / COUNT(DISTINCT m.Match_Id), 2)         AS avg_wickets,
    SUM(CASE WHEN m.Man_of_the_Match = p.Player_Id THEN 1 ELSE 0 END)  AS motm_count,
    -- Composite Score (weighted: runs 40% + wickets 40% + MOTM 20%)
    ROUND(
        (SUM(b.Runs_Scored) / COUNT(DISTINCT m.Match_Id)) * 0.4
        + (COUNT(wt.Player_Out) / COUNT(DISTINCT m.Match_Id)) * 40
        + SUM(CASE WHEN m.Man_of_the_Match = p.Player_Id THEN 1 ELSE 0 END) * 2,
    2)                                                                   AS composite_score
FROM Ball_by_Ball b
JOIN Player  p  ON b.Striker  = p.Player_Id
JOIN Matches m  ON b.Match_Id = m.Match_Id
LEFT JOIN Wicket_Taken wt
    ON  wt.Match_Id   = b.Match_Id
    AND wt.Over_Id    = b.Over_Id
    AND wt.Ball_Id    = b.Ball_Id
    AND wt.Innings_No = b.Innings_No
    AND wt.Kind_Out  != 3
GROUP BY p.Player_Id, p.Player_Name
HAVING matches >= 10
ORDER BY composite_score DESC
LIMIT 20;


-- ============================================================
-- SUBJECTIVE QUESTION 4
-- Players offering versatility (both bat + bowl effectively)
-- All-rounders: above-average in both batting and bowling
-- ============================================================

WITH bat_stats AS (
    SELECT
        b.Striker                                                        AS player_id,
        SUM(b.Runs_Scored)                                               AS runs,
        COUNT(DISTINCT b.Match_Id)                                       AS bat_matches,
        SUM(b.Runs_Scored) / COUNT(DISTINCT b.Match_Id)                  AS avg_runs
    FROM Ball_by_Ball b GROUP BY b.Striker
),
bowl_stats AS (
    SELECT
        b.Bowler                                                         AS player_id,
        COUNT(wt.Player_Out)                                             AS wickets,
        COUNT(DISTINCT b.Match_Id)                                       AS bowl_matches,
        COUNT(wt.Player_Out) / COUNT(DISTINCT b.Match_Id)               AS avg_wickets
    FROM Ball_by_Ball b
    LEFT JOIN Wicket_Taken wt
        ON  wt.Match_Id   = b.Match_Id
        AND wt.Over_Id    = b.Over_Id
        AND wt.Ball_Id    = b.Ball_Id
        AND wt.Innings_No = b.Innings_No
        AND wt.Kind_Out  != 3
    GROUP BY b.Bowler
)
SELECT
    p.Player_Name,
    ba.runs             AS total_runs,
    ROUND(ba.avg_runs,    2)    AS avg_runs_per_match,
    bw.wickets          AS total_wickets,
    ROUND(bw.avg_wickets, 2)   AS avg_wickets_per_match,
    GREATEST(ba.bat_matches, bw.bowl_matches) AS matches_involved
FROM bat_stats ba
JOIN bowl_stats bw ON ba.player_id = bw.player_id
JOIN Player     p  ON ba.player_id = p.Player_Id
WHERE ba.avg_runs    > (SELECT AVG(avg_runs)    FROM bat_stats)
  AND bw.avg_wickets > (SELECT AVG(avg_wickets) FROM bowl_stats)
  AND ba.bat_matches >= 10
  AND bw.bowl_matches >= 10
ORDER BY ba.avg_runs DESC, bw.avg_wickets DESC;


-- ============================================================
-- SUBJECTIVE QUESTION 5
-- Players whose presence positively influences team performance
-- (Team win rate when player is playing vs when not)
-- ============================================================

-- Win rate WITH the player in the team
SELECT
    p.Player_Name,
    COUNT(DISTINCT pm.Match_Id)                                          AS matches_played,
    SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END)       AS team_wins_with_player,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) * 100.0
        / COUNT(DISTINCT pm.Match_Id),
    2)                                                                   AS win_pct_with_player
FROM Player_Match pm
JOIN Matches m ON pm.Match_Id = m.Match_Id
JOIN Player  p ON pm.Player_Id = p.Player_Id
WHERE m.Outcome_type = 1
GROUP BY p.Player_Id, p.Player_Name
HAVING matches_played >= 10
ORDER BY win_pct_with_player DESC
LIMIT 20;


-- ============================================================
-- SUBJECTIVE QUESTION 6
-- Suggestions to RCB before mega auction
-- (Identify RCB weaknesses: low avg runs, high extras, poor death bowling)
-- ============================================================

-- RCB batting analysis across seasons
SELECT
    s.Season_Year,
    SUM(b.Runs_Scored)                          AS rcb_runs_scored,
    COUNT(DISTINCT m.Match_Id)                  AS matches,
    ROUND(SUM(b.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS avg_runs_per_match
FROM Ball_by_Ball b
JOIN Matches m ON b.Match_Id    = m.Match_Id
JOIN Season  s ON m.Season_Id   = s.Season_Id
WHERE b.Team_Batting = 2            -- RCB
GROUP BY s.Season_Year
ORDER BY s.Season_Year;

-- RCB death-over (17-20) weakness
SELECT
    s.Season_Year,
    ROUND(AVG(CASE WHEN b.Over_Id BETWEEN 17 AND 20 THEN b.Runs_Scored END), 2) AS avg_death_over_runs_conceded
FROM Ball_by_Ball b
JOIN Matches m ON b.Match_Id   = m.Match_Id
JOIN Season  s ON m.Season_Id  = s.Season_Id
WHERE b.Team_Bowling = 2             -- RCB bowling
GROUP BY s.Season_Year
ORDER BY s.Season_Year;

-- RCB home vs away win rate
SELECT
    CASE WHEN v.City_Id = 1 THEN 'Home (Bangalore)' ELSE 'Away' END AS venue_type,
    COUNT(*)                                                          AS matches,
    SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END)             AS wins,
    ROUND(SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS win_pct
FROM Matches m
JOIN Venue v ON m.Venue_Id = v.Venue_Id
WHERE (m.Team_1 = 2 OR m.Team_2 = 2)
  AND m.Outcome_type = 1
GROUP BY venue_type;


-- ============================================================
-- SUBJECTIVE QUESTION 7
-- Factors contributing to high-scoring matches
-- ============================================================

SELECT
    m.Match_Id,
    s.Season_Year,
    v.Venue_Name,
    SUM(b.Runs_Scored)                                                  AS total_match_runs,
    SUM(COALESCE(er.Extra_Runs, 0))                                     AS total_extras,
    COUNT(wt.Player_Out)                                                AS total_wickets,
    ROUND(SUM(b.Runs_Scored) / 40, 2)                                   AS avg_runs_per_over,
    CASE
        WHEN SUM(b.Runs_Scored) > 350 THEN 'Very High Scoring'
        WHEN SUM(b.Runs_Scored) > 280 THEN 'High Scoring'
        ELSE 'Normal'
    END                                                                  AS match_type
FROM Matches m
JOIN Season       s  ON m.Season_Id   = s.Season_Id
JOIN Venue        v  ON m.Venue_Id    = v.Venue_Id
JOIN Ball_by_Ball b  ON b.Match_Id    = m.Match_Id
LEFT JOIN Extra_Runs er
    ON  er.Match_Id  = b.Match_Id
    AND er.Over_Id   = b.Over_Id
    AND er.Ball_Id   = b.Ball_Id
    AND er.Innings_No = b.Innings_No
LEFT JOIN Wicket_Taken wt
    ON  wt.Match_Id  = b.Match_Id
    AND wt.Over_Id   = b.Over_Id
    AND wt.Ball_Id   = b.Ball_Id
    AND wt.Innings_No = b.Innings_No
WHERE m.Outcome_type = 1
GROUP BY m.Match_Id, s.Season_Year, v.Venue_Name
ORDER BY total_match_runs DESC
LIMIT 20;


-- ============================================================
-- SUBJECTIVE QUESTION 8
-- Home-ground advantage analysis for RCB
-- (Chinnaswamy Stadium = Bangalore = City_Id 1)
-- ============================================================

SELECT
    s.Season_Year,
    CASE WHEN v.City_Id = 1 THEN 'Home' ELSE 'Away' END     AS ground_type,
    COUNT(*)                                                  AS matches,
    SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END)     AS wins,
    SUM(CASE WHEN m.Match_Winner != 2 THEN 1 ELSE 0 END)    AS losses,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2)                                                        AS win_pct
FROM Matches m
JOIN Venue   v ON m.Venue_Id  = v.Venue_Id
JOIN Season  s ON m.Season_Id = s.Season_Id
WHERE (m.Team_1 = 2 OR m.Team_2 = 2)
  AND m.Outcome_type = 1
GROUP BY s.Season_Year, ground_type
ORDER BY s.Season_Year, ground_type;


-- ============================================================
-- SUBJECTIVE QUESTION 9
-- RCB past season performance analysis
-- (Runs, wickets, wins, losses — season by season)
-- ============================================================

SELECT
    s.Season_Year,
    COUNT(DISTINCT m.Match_Id)                                           AS matches_played,
    SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END)                AS wins,
    SUM(CASE WHEN m.Match_Winner != 2
              AND m.Outcome_type = 1 THEN 1 ELSE 0 END)                AS losses,
    SUM(CASE WHEN m.Outcome_type != 1 THEN 1 ELSE 0 END)               AS no_result,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = 2 THEN 1 ELSE 0 END) * 100.0
        / COUNT(DISTINCT m.Match_Id),
    2)                                                                   AS win_percentage
FROM Matches m
JOIN Season s ON m.Season_Id = s.Season_Id
WHERE m.Team_1 = 2 OR m.Team_2 = 2
GROUP BY s.Season_Id, s.Season_Year
ORDER BY s.Season_Year;


-- ============================================================
-- SUBJECTIVE QUESTION 10
-- Open-ended approach (no predefined questions)
-- Starting data exploration queries
-- ============================================================

-- Overview: row counts of all tables
SELECT 'Player'        AS tbl, COUNT(*) AS 'rows' FROM Player        UNION ALL
SELECT 'Matches',              COUNT(*)          FROM Matches       UNION ALL
SELECT 'Ball_by_Ball',         COUNT(*)          FROM Ball_by_Ball  UNION ALL
SELECT 'Wicket_Taken',         COUNT(*)          FROM Wicket_Taken  UNION ALL
SELECT 'Extra_Runs',           COUNT(*)          FROM Extra_Runs    UNION ALL
SELECT 'Season',               COUNT(*)          FROM Season        UNION ALL
SELECT 'Venue',                COUNT(*)          FROM Venue         UNION ALL
SELECT 'Team',                 COUNT(*)          FROM Team;

-- Most impactful matches (high scoring + many wickets)
SELECT
    m.Match_Id,
    t1.Team_Name AS team_1,
    t2.Team_Name AS team_2,
    s.Season_Year,
    m.Win_Margin,
    wb.Win_Type
FROM Matches m
JOIN Team         t1 ON m.Team_1    = t1.Team_Id
JOIN Team         t2 ON m.Team_2    = t2.Team_Id
JOIN Season       s  ON m.Season_Id = s.Season_Id
JOIN Win_By       wb ON m.Win_Type  = wb.Win_Id
WHERE m.Outcome_type = 1
ORDER BY m.Win_Margin DESC
LIMIT 10;


-- ============================================================
-- SUBJECTIVE QUESTION 11
-- Replace 'Delhi_Capitals' with 'Delhi_Daredevils' in the dataset
-- Finding: Team table uses 'Delhi Daredevils' (spaces, not underscores)
-- The incorrect spelling mentioned in the question does not exist
-- in this dataset — data is already correct.
-- ============================================================

-- Step 1: Check actual Delhi entry in Team table
SELECT Team_Id, Team_Name
FROM Team
WHERE Team_Name LIKE '%Delhi%';

-- Step 2: Confirm no 'Delhi_Capitals' entry exists
SELECT Team_Id, Team_Name
FROM Team
WHERE Team_Name = 'Delhi_Capitals';
-- Result: 0 row(s) returned — no incorrect entry found


-- Step 3: The correct UPDATE query (for reference / if error existed)
-- This is the proper way to fix it IF 'Delhi_Capitals' were present:
SET SQL_SAFE_UPDATES = 0;
UPDATE Team
SET Team_Name = 'Delhi Daredevils'
WHERE Team_Name = 'Delhi_Capitals';

-- Step 4: Final verification
SELECT Team_Id, Team_Name
FROM Team
WHERE Team_Name LIKE '%Delhi%';
-- Confirms: Team_Id = 6 → 'Delhi Daredevils'

-- ============================================================
-- END OF IPL SQL SOLUTIONS
-- Hope this Data is Acurate
-- Presented By: Adithya Lakkakula
-- ============================================================
