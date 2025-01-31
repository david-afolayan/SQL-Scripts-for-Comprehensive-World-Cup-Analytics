CREATE OR REPLACE FUNCTION fn_match_result(
    home_goals INT, 
    away_goals INT
) RETURNS TEXT AS $$
BEGIN
    RETURN CASE
        WHEN home_goals > away_goals THEN 'Home Win'
        WHEN home_goals < away_goals THEN 'Away Win'
        ELSE 'Draw'
    END;
END;
$$ LANGUAGE plpgsql;