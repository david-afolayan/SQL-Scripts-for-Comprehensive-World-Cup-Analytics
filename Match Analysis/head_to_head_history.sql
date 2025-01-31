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



-- All 2022 matches chronological order
SELECT date, stage, home_team, away_team
FROM world_cup_matches_2022
ORDER BY date;


--Historical matchups between two teams
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

