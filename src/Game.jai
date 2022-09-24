game: struct {
    resetting: bool;
    paused: bool;
    state: Game_State;
    player: Handle(Creature);
    dt: float;

    small_fry: Creature;
}

Game_State :: enum {
    INITIAL;
}

game_loop :: inline () {
    using game;
    using context.entity_storage;
    dt = GetFrameTime();


    // simulate ----------------------------------------------------------------
    handle_input();

    for _Creature simulate(it, dt);


    // draw --------------------------------------------------------------------
    BeginDrawing();

    ClearBackground(DARKGRAY);

    for _Creature render(it);

    DrawFPS(0, 0);

    {
        cstr := temp_c_string("PROJECT BOOMERANG");
        measure := MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1);
        DrawTextPro(the_font, cstr, .{800-2, 600-2}, measure, 0, xx the_font.baseSize, 1, WHITE);
    }

    update_animation(*small_fry.animation);
    draw_texture_centered_with_rotation(Current_Frame(small_fry.animation), small_fry.position, 0.0);

    EndDrawing();


    // cleanup -----------------------------------------------------------------
    cleanup_despawning_entities();
    reset_temporary_storage();
}

game_reset :: () {
    using game;
    log("RESETTING GAME");
    reset_entity_storage();
    load_all_animations();

    game = .{};
    {
        c := CT_PLAYER;
        c.position = .{100, 100};
        player = spawn(c);

        small_fry.position = .{200, 200};
        small_fry.animation = NewAnimation("small_fry/idle");
        small_fry.animation.should_loop = true;
    }
}
