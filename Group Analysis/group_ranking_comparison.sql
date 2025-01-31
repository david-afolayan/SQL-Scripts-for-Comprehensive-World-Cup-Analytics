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


-- World Cup winners timeline
SELECT year, host_country, winner, runners_up
FROM world_cups
WHERE winner IS NOT NULL
ORDER BY year DESC;



-- Recommended indexes for large datasets
CREATE INDEX idx_wc_matches_teams ON world_cup_matches_2022 (home_team, away_team);
CREATE INDEX idx_squads_team ON world_cups_squads_2022 (team);
CREATE INDEX idx_groups_group ON world_cup_groups_2022 (group_name);
CREATE INDEX idx_intl_matches_date ON international_matches (date);