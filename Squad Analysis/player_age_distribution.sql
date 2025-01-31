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