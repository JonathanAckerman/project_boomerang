game: struct {
    resetting: bool;
    paused: bool;
    state: Game_State;
    player: Handle(Creature);
    dt: float;

    enemies: [..] Handle(Creature);
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
        DrawTextPro(the_font, cstr, .{WINDOW_WIDTH-2, WINDOW_HEIGHT-2}, measure, 0, xx the_font.baseSize, 1, WHITE);
    }

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

    // init creatures
    {
        c := Creatures.PLAYER; 
        c.position = .{100, 100};
        c.animation = NewAnimation("player/idle");
        player = spawn(c);

        c = Creatures.SMALL_FRY;
        c.position = .{300, 300};
        c.animation = NewAnimation("small_fry/idle");
        array_add(*enemies, spawn(c));
    }
}
