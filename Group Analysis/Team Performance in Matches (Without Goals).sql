WITH TeamAppearances AS (
  SELECT 
    Home_Team AS team,
    Stage,
    CASE 
      WHEN Host_Team = TRUE THEN 'Host'
      ELSE 'Away'
    END AS host_status
  FROM world_cup_matches_2022
  
  UNION ALL
  
  SELECT 
    Away_Team AS team,
    Stage,
    'Away' AS host_status
  FROM world_cup_matches_2022
)

SELECT 
  team,
  Stage,
  COUNT(*) AS total_matches,
  SUM(CASE WHEN host_status = 'Host' THEN 1 ELSE 0 END) AS host_matches
FROM TeamAppearances
GROUP BY team, Stage;