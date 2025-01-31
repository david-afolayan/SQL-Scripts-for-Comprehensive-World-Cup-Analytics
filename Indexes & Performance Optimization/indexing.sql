-- Recommended indexes for large datasets
CREATE INDEX idx_wc_matches_teams ON world_cup_matches_2022 (home_team, away_team);
CREATE INDEX idx_squads_team ON world_cups_squads_2022 (team);
CREATE INDEX idx_groups_group ON world_cup_groups_2022 (group_name);
CREATE INDEX idx_intl_matches_date ON international_matches (date);



-- For match analysis
CREATE INDEX idx_matches_team_date ON world_cup_matches (home_team, away_team, date);
CREATE INDEX idx_intl_matches_tournament ON international_matches (tournament, date);

-- For squad queries
CREATE INDEX idx_squads_team_goals ON world_cups_squads_2022 (team, wc_goals);
CREATE INDEX idx_squads_position_age ON world_cups_squads_2022 (position, age);

-- For group stage analysis
CREATE INDEX idx_groups_ranking ON world_cup_groups_2022 (group_name, fifa_ranking);



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