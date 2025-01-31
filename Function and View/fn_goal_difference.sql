CREATE OR REPLACE FUNCTION fn_goal_difference(
    goals_for INT, 
    goals_against INT
) RETURNS INT AS $$
BEGIN
    RETURN goals_for - goals_against;
END;
$$ LANGUAGE plpgsql;