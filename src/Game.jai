game: struct {
    resetting: bool;
    paused: bool;
    state: Game_State;
    dt: float;

    player: Handle(Creature);
    camera: struct {
        zoom := 1.0;
        position: Vector2;
    }

    physics_colliders: [..] Collider;
    hurt_colliders:    [..] Collider;
    hit_colliders:     [..] Collider;
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

    for * a: physics_colliders {
        for * b: physics_colliders {
            if a != b {
                if length(a.position - b.position) <= a.radius + b.radius {
                    a.is_colliding = true;
                    b.is_colliding = true;
                }
            }
        }
    }

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

    for physics_colliders {
        // @DEBUG
        color := YELLOW;
        if it.is_colliding then color = RED;
        ss_pos := world_to_screen(it.position);
        if it.radius != 0.0 then DrawCircleLines(xx ss_pos.x, xx ss_pos.y, xx it.radius, color);
    }

    EndDrawing();


    // cleanup -----------------------------------------------------------------
    array_reset_keeping_memory(*physics_colliders);
    array_reset_keeping_memory(*hurt_colliders);
    array_reset_keeping_memory(*hit_colliders);
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
        c.weapon.type = .BOOMERANG;
        c.weapon.boomerang.animation = NewAnimation("boomerang/spin");
        c.weapon.boomerang.animation.should_loop = true;
        c.weapon.boomerang.collider.radius = 50.0;
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
