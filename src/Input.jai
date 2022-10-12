input: struct {
    use_gamepad := true;
    gamepad_index: s32;
    gamepad: struct {
        normal_attack: GamepadButton = .GAMEPAD_BUTTON_RIGHT_FACE_RIGHT;
        pause:         GamepadButton = .GAMEPAD_BUTTON_MIDDLE_RIGHT;
        movement: Vector2;
        deadzone: float = 0.3;
    }
}

handle_input :: inline () {
    using input;
    use_gamepad = IsGamepadAvailable(gamepad_index);
    player, gone := from_handle(game.player);
    if gone /*|| player.status != .ALIVE*/ then return;

    if use_gamepad {
        if IsGamepadButtonPressed(gamepad_index, xx gamepad.normal_attack) {
            player.try_attack = true;
        } else {
            player.try_attack = false;
        }

        gamepad.movement.x = GetGamepadAxisMovement(gamepad_index, xx GamepadAxis.GAMEPAD_AXIS_LEFT_X);
        gamepad.movement.y = GetGamepadAxisMovement(gamepad_index, xx GamepadAxis.GAMEPAD_AXIS_LEFT_Y);
        if length(gamepad.movement) > gamepad.deadzone {
            player.forward_intended = unit_vector(gamepad.movement);
            player.velocity = gamepad.movement * player.move_speed.cur;
        } else {
            player.velocity = .{0, 0};
        }
    } 
    else {
        new_velocity: Vector2;
        if IsKeyDown(xx KeyboardKey.W) || IsKeyDown(xx KeyboardKey.UP) {
            new_velocity += xy(0, -1);
            player.forward_intended += xy(0, -1);
        }
        if IsKeyDown(xx KeyboardKey.S) || IsKeyDown(xx KeyboardKey.DOWN) {
            new_velocity += xy(0, 1);
            player.forward_intended += xy(0, 1);
        }
        if IsKeyDown(xx KeyboardKey.A) || IsKeyDown(xx KeyboardKey.LEFT) {
            new_velocity += xy(-1, 0);
            player.forward_intended += xy(-1, 0);
        }
        if IsKeyDown(xx KeyboardKey.D) || IsKeyDown(xx KeyboardKey.RIGHT) {
            new_velocity += xy(1, 0);
            player.forward_intended += xy(1, 0);
        }

        player.forward_intended = unit_vector(player.forward_intended);
        player.velocity = unit_vector(new_velocity) * player.move_speed.cur;

        if IsKeyPressed(xx KeyboardKey.SPACE) {
            player.try_attack = true;
        } else {
            player.try_attack = false;
        }
    }

    if IsKeyPressed(xx KeyboardKey.F5)  then game.resetting = true;
    if IsKeyPressed(xx KeyboardKey.F9)  then game.paused = !game.paused;
    if IsKeyPressed(xx KeyboardKey.F11) then game.debug = !game.debug;
}
