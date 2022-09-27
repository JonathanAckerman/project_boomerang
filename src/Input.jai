handle_input :: inline () {
    if IsKeyPressed(xx KeyboardKey.F5) then game.resetting = true;
    player, gone := from_handle(game.player);
    if gone /*|| player.status != .ALIVE*/ then return;
    using player;

    new_velocity: Vector2;

    if IsKeyDown(xx KeyboardKey.W) || IsKeyDown(xx KeyboardKey.UP) {
        orientation_intended = PI/2;
        new_velocity += xy(0, -1);
    }
    if IsKeyDown(xx KeyboardKey.S) || IsKeyDown(xx KeyboardKey.DOWN) {
        orientation_intended = 3*PI/2;
        new_velocity += xy(0, 1);
    }
    if IsKeyDown(xx KeyboardKey.A) || IsKeyDown(xx KeyboardKey.LEFT) {
        orientation_intended = PI;
        new_velocity += xy(-1, 0);
    }
    if IsKeyDown(xx KeyboardKey.D) || IsKeyDown(xx KeyboardKey.RIGHT) {
        orientation_intended = 0;
        new_velocity += xy(1, 0);
    } 

    velocity = unit_vector(new_velocity) * move_speed.cur;
}
