handle_input :: inline () {
    if IsKeyPressed(xx KeyboardKey.F5) then game.resetting = true;
    player, gone := from_handle(game.player);
    if gone /*|| player.status != .ALIVE*/ then return;
    using player;

    new_velocity: Vector2;

    if IsKeyDown(xx KeyboardKey.UP)    then new_velocity += xy(0, -1);
    if IsKeyDown(xx KeyboardKey.DOWN)  then new_velocity += xy(0, 1);
    if IsKeyDown(xx KeyboardKey.LEFT)  then new_velocity += xy(-1, 0);
    if IsKeyDown(xx KeyboardKey.RIGHT) then new_velocity += xy(1, 0);



    velocity = unit_vector(new_velocity) * speed;
}
