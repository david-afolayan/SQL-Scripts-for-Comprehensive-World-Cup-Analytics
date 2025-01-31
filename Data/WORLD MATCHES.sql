-- Teams in Group A with rankings
SELECT * FROM world_cup_groups_2022
WHERE group_name = 'A'
ORDER BY fifa_ranking;

-- All matches where host team played
SELECT * FROM world_cup_matches_2022
WHERE host_team = TRUE;

-- Argentina's forwards
SELECT player, age, club 
FROM world_cups_squads_2022
WHERE team = 'Argentina' AND position = 'Forward';

-- World Cup winners timeline
SELECT year, host_country, winner, runners_up
FROM world_cups
WHERE winner IS NOT NULL
ORDER BY year DESC;

-- Average ranking per group
SELECT group_name, 
       ROUND(AVG(fifa_ranking), 1) AS avg_ranking
FROM world_cup_groups_2022
GROUP BY group_name
ORDER BY avg_ranking;

-- Top 10 most capped players
SELECT player, team, caps, goals
FROM world_cups_squads_2022
ORDER BY caps DESC
LIMIT 10;

-- All 2022 matches chronological order
SELECT date, stage, home_team, away_team
FROM world_cup_matches_2022
ORDER BY date;



-- Historical matchups between two specific teams (e.g., Argentina vs. Germany)
WITH all_matches AS (
    SELECT home_team AS team1, away_team AS team2, home_goals, away_goals 
    FROM world_cup_matches
    UNION ALL
    SELECT away_team, home_team, away_goals, home_goals 
    FROM world_cup_matches
    UNION ALL
    SELECT home_team, away_team, home_goals, away_goals 
    FROM international_matches
)
SELECT 
    team1, 
    team2,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN home_goals > away_goals THEN 1 ELSE 0 END) AS team1_wins,
    SUM(CASE WHEN home_goals < away_goals THEN 1 ELSE 0 END) AS team2_wins,
    SUM(CASE WHEN home_goals = away_goals THEN 1 ELSE 0 END) AS draws,
    SUM(home_goals) AS team1_goals,
    SUM(away_goals) AS team2_goals
FROM all_matches
WHERE (team1 = 'Argentina' AND team2 = 'Germany')
   OR (team1 = 'Germany' AND team2 = 'Argentina')
GROUP BY team1, team2;



-- Goals per stage across all World Cups
SELECT 
    wc.year,
    m.stage,
    SUM(m.home_goals + m.away_goals) AS total_goals,
    ROUND(AVG(m.home_goals + m.away_goals), 2) AS avg_goals_per_match
FROM world_cup_matches m
JOIN world_cups wc ON m.year = wc.year
GROUP BY wc.year, m.stage
ORDER BY wc.year DESC, total_goals DESC;

-- 2022 Top Scorers by Team
SELECT 
    team,
    SUM(wc_goals) AS total_goals,
    STRING_AGG(player || ' (' || wc_goals || ')', ', ') AS scorers
FROM world_cups_squads_2022
WHERE wc_goals > 0
GROUP BY team
ORDER BY total_goals DESC;


-- Team progression through stages
WITH team_progression AS (
    SELECT 
        home_team AS team,
        stage,
        MIN(date) AS first_appearance,
        MAX(date) AS last_appearance
    FROM world_cup_matches_2022
    GROUP BY home_team, stage
    
    UNION
    
    SELECT 
        away_team AS team,
        stage,
        MIN(date),
        MAX(date)
    FROM world_cup_matches_2022
    GROUP BY away_team, stage
)
SELECT 
    team,
    STRING_AGG(stage || ' (' || TO_CHAR(first_appearance, 'Mon DD') || ')', ' → ') AS progression,
    COUNT(DISTINCT stage) AS stages_reached
FROM team_progression
GROUP BY team
ORDER BY stages_reached DESC, team;


-- Show complete knockout bracket progression
WITH knockout_paths AS (
    SELECT 
        id,
        home_team,
        away_team,
        stage,
        LEAD(home_team) OVER (ORDER BY date) AS next_home,
        LEAD(away_team) OVER (ORDER BY date) AS next_away
    FROM world_cup_matches_2022
    WHERE stage <> 'Group stage'
)
SELECT 
    kp.stage,
    kp.home_team AS team1,
    kp.away_team AS team2,
    kp.next_home AS advanced_to_next_home,
    kp.next_away AS advanced_to_next_away
FROM knockout_paths kp
WHERE kp.stage LIKE 'Round of 16%' 
   OR kp.stage LIKE 'Quarter-finals%'
   OR kp.stage LIKE 'Semi-finals%';
   
   
-- Age distribution analysis by position
SELECT 
    team,
    position,
    COUNT(*) AS players,
    ROUND(AVG(age), 1) AS avg_age,
    MIN(age) AS youngest,
    MAX(age) AS oldest
FROM world_cups_squads_2022
GROUP BY team, position
ORDER BY team, 
         CASE position
             WHEN 'Goalkeeper' THEN 1
             WHEN 'Defender' THEN 2
             WHEN 'Midfielder' THEN 3
             ELSE 4
         END;

-- Experience vs Performance
SELECT 
    s.team,
    ROUND(AVG(s.caps), 1) AS avg_caps,
    SUM(s.wc_goals) AS total_goals,
    COUNT(*) FILTER (WHERE s.wc_goals > 0) AS goalscorers
FROM world_cups_squads_2022 s
JOIN world_cup_groups_2022 g ON s.team = g.team
GROUP BY s.team
ORDER BY total_goals DESC;


-- Host nation performance comparison
SELECT 
    wc.year,
    wc.host_country,
    COUNT(m.id) FILTER (WHERE m.host_team = TRUE) AS total_matches,
    COUNT(m.id) FILTER (WHERE m.home_goals > m.away_goals) AS wins,
    COUNT(m.id) FILTER (WHERE m.home_goals < m.away_goals) AS losses,
    COUNT(m.id) FILTER (WHERE m.home_goals = m.away_goals) AS draws
FROM world_cups wc
LEFT JOIN world_cup_matches m ON wc.year = m.year
WHERE m.host_team = TRUE
GROUP BY wc.year, wc.host_country
ORDER BY wc.year DESC;



-- Identify strongest groups using FIFA rankings
WITH group_strength AS (
    SELECT 
        group_name,
        AVG(fifa_ranking) AS avg_ranking,
        MAX(fifa_ranking) AS weakest_team,
        MIN(fifa_ranking) AS strongest_team,
        MIN(fifa_ranking) - MAX(fifa_ranking) AS ranking_spread
    FROM world_cup_groups_2022
    GROUP BY group_name
)
SELECT 
    group_name,
    RANK() OVER (ORDER BY avg_ranking ASC) AS strength_rank,
    avg_ranking,
    strongest_team,
    weakest_team,
    ranking_spread
FROM group_strength
ORDER BY strength_rank;



-- Team performance with running totals
WITH match_results AS (
    SELECT 
        date,
        team,
        SUM(goals) AS daily_goals,
        SUM(SUM(goals)) OVER (PARTITION BY team ORDER BY date) AS running_total
    FROM (
        SELECT date, home_team AS team, home_goals AS goals
        FROM world_cup_matches
        UNION ALL
        SELECT date, away_team AS team, away_goals AS goals
        FROM world_cup_matches
    ) AS all_matches
    GROUP BY date, team
),
tournament_progression AS (
    SELECT 
        team,
        MIN(date) AS first_match,
        MAX(date) AS last_match,
        COUNT(*) AS matches_played,
        running_total AS total_goals
    FROM match_results
    GROUP BY team, running_total
)
SELECT 
    tp.*,
    RANK() OVER (ORDER BY total_goals DESC) AS goal_rank,
    ROUND(total_goals * 1.0 / matches_played, 2) AS goals_per_match
FROM tournament_progression tp;





CREATE MATERIALIZED VIEW team_performance_summary AS
SELECT 
    g.team,
    g.group_name,
    COUNT(m.id) AS total_matches,
    SUM(CASE WHEN m.home_team = g.team THEN m.home_goals ELSE m.away_goals END) AS goals_for,
    SUM(CASE WHEN m.home_team = g.team THEN m.away_goals ELSE m.home_goals END) AS goals_against,
    SUM(CASE 
        WHEN (m.home_team = g.team AND m.home_goals > m.away_goals) OR
             (m.away_team = g.team AND m.away_goals > m.home_goals) THEN 3
        WHEN m.home_goals = m.away_goals THEN 1
        ELSE 0
    END) AS points
FROM world_cup_groups_2022 g
LEFT JOIN world_cup_matches m 
    ON g.team = m.home_team OR g.team = m.away_team
GROUP BY g.team, g.group_name;

-- Refresh when needed
REFRESH MATERIALIZED VIEW team_performance_summary;




CREATE OR REPLACE FUNCTION get_match_outcome(
    home_goals INT, 
    away_goals INT, 
    team TEXT
) RETURNS TEXT AS $$
BEGIN
    RETURN CASE
        WHEN home_goals > away_goals THEN 
            CASE WHEN team = 'home' THEN 'win' ELSE 'loss' END
        WHEN home_goals < away_goals THEN 
            CASE WHEN team = 'home' THEN 'loss' ELSE 'win' END
        ELSE 'draw'
    END;
END;
$$ LANGUAGE plpgsql;

-- Usage example
SELECT 
    home_team,
    away_team,
    get_match_outcome(home_goals, away_goals, 'home') AS home_result,
    get_match_outcome(home_goals, away_goals, 'away') AS away_result
FROM world_cup_matches;




WITH combined_history AS (
    SELECT 
        m.date,
        m.home_team,
        m.away_team,
        m.home_goals,
        m.away_goals,
        'World Cup' AS tournament_type
    FROM world_cup_matches m
    
    UNION ALL
    
    SELECT 
        i.date,
        i.home_team,
        i.away_team,
        i.home_goals,
        i.away_goals,
        'International' AS tournament_type
    FROM international_matches i
),
team_performance AS (
    SELECT
        team,
        tournament_type,
        COUNT(*) FILTER (WHERE outcome = 'win') AS wins,
        COUNT(*) FILTER (WHERE outcome = 'loss') AS losses,
        COUNT(*) FILTER (WHERE outcome = 'draw') AS draws
    FROM (
        SELECT 
            home_team AS team,
            tournament_type,
            get_match_outcome(home_goals, away_goals, 'home') AS outcome
        FROM combined_history
        
        UNION ALL
        
        SELECT 
            away_team AS team,
            tournament_type,
            get_match_outcome(home_goals, away_goals, 'away') AS outcome
        FROM combined_history
    ) AS all_results
    GROUP BY team, tournament_type
)
SELECT 
    team,
    ROUND(wins * 100.0 / (wins + losses + draws), 2) AS world_cup_win_pct,
    ROUND((SELECT wins * 100.0 / (wins + losses + draws) 
          FROM team_performance tp2 
          WHERE tp2.team = tp.team AND tp2.tournament_type = 'International'), 2) AS intl_win_pct
FROM team_performance tp
WHERE tournament_type = 'World Cup';





WITH knockout_stages AS (
    SELECT 
        id,
        stage,
        home_team,
        away_team,
        LEAD(home_team) OVER (ORDER BY date) AS next_round_team1,
        LEAD(away_team) OVER (ORDER BY date) AS next_round_team2
    FROM world_cup_matches_2022
    WHERE stage IN ('Round of 16', 'Quarter-finals', 'Semi-finals', 'Final')
),
tournament_path AS (
    SELECT
        k1.stage,
        k1.home_team,
        k1.away_team,
        k2.stage AS next_stage,
        COALESCE(k2.home_team, k2.away_team) AS progressed_team
    FROM knockout_stages k1
    LEFT JOIN knockout_stages k2 
        ON k1.home_team = k2.next_round_team1
        OR k1.away_team = k2.next_round_team2
)
SELECT 
    tp.stage,
    tp.home_team,
    tp.away_team,
    STRING_AGG(tp.next_stage || ': ' || tp.progressed_team, ' → ') AS progression_path
FROM tournament_path tp
GROUP BY tp.stage, tp.home_team, tp.away_team;




-- Recommended indexes for large datasets
CREATE INDEX idx_wc_matches_teams ON world_cup_matches_2022 (home_team, away_team);
CREATE INDEX idx_squads_team ON world_cups_squads_2022 (team);
CREATE INDEX idx_groups_group ON world_cup_groups_2022 (group_name);
CREATE INDEX idx_intl_matches_date ON international_matches (date);





CREATE MATERIALIZED VIEW mv_team_performance AS
SELECT 
    g.team,
    g.group_name,
    COUNT(m.id) AS total_matches,
    SUM(CASE WHEN m.home_team = g.team THEN m.home_goals ELSE m.away_goals END) AS goals_for,
    SUM(CASE WHEN m.home_team = g.team THEN m.away_goals ELSE m.home_goals END) AS goals_against,
    SUM(CASE 
        WHEN (m.home_team = g.team AND m.home_goals > m.away_goals) OR
             (m.away_team = g.team AND m.away_goals > m.home_goals) THEN 3
        WHEN m.home_goals = m.away_goals THEN 1
        ELSE 0
    END) AS points
FROM world_cup_groups_2022 g
LEFT JOIN world_cup_matches m 
    ON g.team = m.home_team OR g.team = m.away_team
GROUP BY g.team, g.group_name;


CREATE MATERIALIZED VIEW mv_player_stats AS
SELECT 
    team,
    position,
    COUNT(*) AS total_players,
    AVG(age) AS avg_age,
    SUM(wc_goals) AS total_goals,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY caps) AS median_caps
FROM world_cups_squads_2022
GROUP BY team, position;


CREATE OR REPLACE FUNCTION fn_match_result(
    home_goals INT, 
    away_goals INT
) RETURNS TEXT AS $$
BEGIN
    RETURN CASE
        WHEN home_goals > away_goals THEN 'Home Win'
        WHEN home_goals < away_goals THEN 'Away Win'
        ELSE 'Draw'
    END;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION fn_goal_difference(
    goals_for INT, 
    goals_against INT
) RETURNS INT AS $$
BEGIN
    RETURN goals_for - goals_against;
END;
$$ LANGUAGE plpgsql;




-- For match analysis
CREATE INDEX idx_matches_team_date ON world_cup_matches (home_team, away_team, date);
CREATE INDEX idx_intl_matches_tournament ON international_matches (tournament, date);

-- For squad queries
CREATE INDEX idx_squads_team_goals ON world_cups_squads_2022 (team, wc_goals);
CREATE INDEX idx_squads_position_age ON world_cups_squads_2022 (position, age);

-- For group stage analysis
CREATE INDEX idx_groups_ranking ON world_cup_groups_2022 (group_name, fifa_ranking);



EXPLAIN ANALYZE
SELECT team, SUM(wc_goals) 
FROM world_cups_squads_2022
WHERE position = 'Forward'
GROUP BY team
ORDER BY SUM(wc_goals) DESC;

EXPLAIN ANALYZE
SELECT team, SUM(wc_goals) 
FROM world_cups_squads_2022
WHERE position = 'Forward'
GROUP BY team
ORDER BY SUM(wc_goals) DESC
LIMIT 10;


