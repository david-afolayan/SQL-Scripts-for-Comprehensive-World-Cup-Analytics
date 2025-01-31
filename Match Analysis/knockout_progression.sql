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
   
   
   
-- Knockout_stages progression
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


WITH KnockoutMatches AS (
  SELECT
    ID,
    Stage,
    Home_Team,
    Away_Team,
    LEAD(Stage) OVER (ORDER BY Date) AS next_stage,
    LEAD(Home_Team) OVER (ORDER BY Date) AS next_home,
    LEAD(Away_Team) OVER (ORDER BY Date) AS next_away
  FROM world_cup_matches_2022
  WHERE Stage IN ('Round of 16', 'Quarter-finals', 'Semi-finals', 'Final')
)

SELECT
  Stage,
  Home_Team,
  Away_Team,
  next_stage AS progressed_to_stage,
  CASE
    WHEN next_home = Home_Team OR next_away = Home_Team THEN Home_Team
    ELSE Away_Team
  END AS winner
FROM KnockoutMatches;
