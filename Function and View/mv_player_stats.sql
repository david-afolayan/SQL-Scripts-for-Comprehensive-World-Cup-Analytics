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


-- Argentina's forwards
SELECT player, age, club 
FROM world_cups_squads_2022
WHERE team = 'Argentina' AND position = 'Forward';