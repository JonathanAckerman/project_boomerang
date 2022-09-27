AI_Data :: struct {
    has_AI := false; // @Jay: this is a little jank

    has_goal := false;
    goal_position: Vector2;
    goal_reset_timer: float;
    goal_reset_duration :: 5.0;
}

update_ai :: (using creature: *Creature) {
    player, gone := from_handle(game.player);
    chase_player_vector: Vector2;
    
    if !gone then chase_player_vector = player.position - creature.position;

    if !gone && length(chase_player_vector) < 300.0
    {
        forward_intended = unit_vector(chase_player_vector);
        velocity = forward_intended * move_speed.cur;
    }
    else // if the player is gone or we are too far from the player do a random walk
    {
        if ai.has_goal
        {
            if length(position - ai.goal_position) < 10.0
            {
                // we have reached the goal
                velocity = .{};
                ai.has_goal = false;
            }
            else // move towards the goal
            {
                forward_intended = unit_vector(ai.goal_position - position);
                velocity = forward_intended * move_speed.cur;
            }
        }
        else
        {
            // find a new goal
            if ai.goal_reset_timer <= 0.0 {
                x := random_get_within_range(0, 1000);
                y := random_get_within_range(0, 1000);
                ai.goal_position = xy(x,y);
                ai.goal_reset_timer = ai.goal_reset_duration;
                ai.has_goal = true;
            }
            else {
                ai.goal_reset_timer -= game.dt;
            }
        }
    }
}