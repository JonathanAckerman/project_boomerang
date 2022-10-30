simulate_dog :: () {
    if game.paused || game.is_gameplay_paused() return;

    player, _ := from_handle(game.player);
    if player.weapon.type != .BOOMERANG then return;

    boomerang := *player.weapon.boomerang;
    
    using game.dog;
    if boomerang.status == .SHEATHED {
        right_offset := rotate(player.forward, PI/2) * 50.0;
        forward_offset := player.forward * 20.0;
        goal_position = player.position + right_offset + forward_offset;

        direction := unit_vector(goal_position - position);
        if distance(position, goal_position) > 5.0 {
            position += direction * player.move_speed.cur * frame.dt;
            forward = direction;
        }
        else {
            forward = player.forward;
        }

        chase_timer = 0.0;
    }
    else {
        if boomerang.return_timer >= boomerang.return_delay return;

        if chase_timer >= chase_delay {
            if distance(position, boomerang.position) > 5.0 {
                direction := unit_vector(boomerang.position - position);
                position += direction * move_speed * frame.dt;
            }
            else boomerang.return_timer = boomerang.return_delay;
        }
        else chase_timer += frame.dt;
    }
}

render_dog :: () {
    using game.dog;
    update_animation(*animation);
    add_to_draw_buffer(Current_Frame(animation), position, .ENTITY, forward, .{50, 50}, BLUE);
}