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