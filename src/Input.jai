handle_input :: inline () {
    if IsKeyPressed(xx KeyboardKey.F5) then game.resetting = true;
    player, gone := from_handle(game.player);
    if gone /*|| player.status != .ALIVE*/ then return;
    using player;

    new_velocity: Vector2;

    if IsKeyDown(xx KeyboardKey.W) || IsKeyDown(xx KeyboardKey.UP) {
        new_velocity += xy(0, -1);
        forward_intended += xy(0, -1);
    }
    if IsKeyDown(xx KeyboardKey.S) || IsKeyDown(xx KeyboardKey.DOWN) {
        new_velocity += xy(0, 1);
        forward_intended += xy(0, 1);
    }
    if IsKeyDown(xx KeyboardKey.A) || IsKeyDown(xx KeyboardKey.LEFT) {
        new_velocity += xy(-1, 0);
        forward_intended += xy(-1, 0);
    }
    if IsKeyDown(xx KeyboardKey.D) || IsKeyDown(xx KeyboardKey.RIGHT) {
        new_velocity += xy(1, 0);
        forward_intended += xy(1, 0);
    } 

    forward_intended = unit_vector(forward_intended);
    velocity = unit_vector(new_velocity) * move_speed.cur;
}
