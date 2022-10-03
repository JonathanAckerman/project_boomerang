game: struct {
    resetting: bool;
    paused: bool;
    state: Game_State;
    player: Handle(Creature);
    dt: float;
    camera: struct {
        zoom := 1.0;
        position: Vector2;
    }
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

    for _Creature simulate(it);

    player_obj, _ := from_handle(player); 
    camera.position = player_obj.position;

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
        c.position = .{0, 0};
        array_add(*c.animations, NewAnimation("player/idle"));
        player = spawn(c);

        c = Creatures.SMALL_FRY;
        c.position = .{300, 300};
        array_add(*c.animations, NewAnimation("small_fry/idle"));
        spawn(c);

        c = Creatures.MEDIUM_FRY;
        c.position = .{500, 400};
        array_add(*c.animations, NewAnimation("medium_fry/idle"));
        spawn(c);

        c = Creatures.BIG_FRY;
        c.position = .{700, 500};
        array_add(*c.animations, NewAnimation("big_fry/idle"));
        spawn(c);
    }
}
