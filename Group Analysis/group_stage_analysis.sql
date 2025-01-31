-- Teams in Group A with rankings
SELECT * FROM world_cup_groups_2022
WHERE group_name = 'A'
ORDER BY fifa_ranking;

-- All matches where host team played
SELECT * FROM world_cup_matches_2022
WHERE host_team = TRUE;

-- Average ranking per group
SELECT group_name, 
       ROUND(AVG(fifa_ranking), 1) AS avg_ranking
FROM world_cup_groups_2022
GROUP BY group_name
ORDER BY avg_ranking;

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
