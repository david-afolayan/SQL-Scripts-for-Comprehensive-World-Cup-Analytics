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
