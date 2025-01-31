-- 2022 Top Scorers by Team
SELECT 
    team,
    SUM(wc_goals) AS total_goals,
    STRING_AGG(player || ' (' || wc_goals || ')', ', ') AS scorers
FROM world_cups_squads_2022
WHERE wc_goals > 0
GROUP BY team
ORDER BY total_goals DESC;


-- Top 10 most capped players
SELECT player, team, caps, goals
FROM world_cups_squads_2022
ORDER BY caps DESC
LIMIT 10;

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
