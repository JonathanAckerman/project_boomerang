game: struct {
    resetting: bool;
    paused: bool;
    state: Game_State;
}

Game_State :: enum {
    INITIAL;
}

game_loop :: inline () {
    using context.entity_storage;
    dt := GetFrameTime();


    // simulate ----------------------------------------------------------------
    handle_input();


    // draw --------------------------------------------------------------------
    BeginDrawing();

    ClearBackground(DARKGRAY);

    DrawFPS(0, 0);

    {
        cstr := temp_c_string("PROJECT BOOMERANG");
        measure := MeasureTextEx(the_font, cstr, xx the_font.baseSize, 1);
        DrawTextPro(the_font, cstr, .{800-2, 600-2}, measure, 0, xx the_font.baseSize, 1, WHITE);
    }

    EndDrawing();


    // cleanup -----------------------------------------------------------------
    cleanup_despawning_entities();
    reset_temporary_storage();
}

game_reset :: () {
    log("RESETTING GAME");
    reset_entity_storage();
    game = .{};
}